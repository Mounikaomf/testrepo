import logging
import os

import gnupg


class gnuPGHelper(object):
    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)
        self.loglevel = kwargs.get("loglevel", "INFO")
        self.gnupghome = kwargs.get("gnupghome", "/tmp")
        self.logger = logging.getLogger(__name__)
        self.logger.setLevel(os.environ.get("LOGLEVEL", self.loglevel))
        self.pgpinstance = gnupg.GPG(gnupghome=self.gnupghome)

    def getkeydata(self):
        try:
            return open(self.pgpkey, "r").read()
        except Exception:
            errormessage = "Error when reading key data "
            self.logger.critical(errormessage, exc_info=True)

    def importpgpkey(self):
        keydata = self.getkeydata()
        try:
            import_result = self.pgpinstance.import_keys(
                keydata, extra_args=["--allow-non-selfsigned-uid"]
            )
        except Exception:
            errormessage = "Error when importing key data "
            self.logger.critical(errormessage, exc_info=True)
        else:
            print(import_result.results[0])
            if import_result.results[0]["fingerprint"] is None:
                errormessage = "Invalid key in {keydata} file"
                errormessagedetailed = errormessage.format(keydata=keydata)
                self.logger.critical(errormessagedetailed)
                raise TypeError
            return import_result.fingerprints[0]


class FileEncryptor(gnuPGHelper):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

    def encryptfilewithstatus(self, keyfingerprint):
        with open(self.datafilename, "rb") as datafile:
            status = self.pgpinstance.encrypt_file(
                datafile,
                recipients=keyfingerprint,
                output=self.pgpfilename,
                always_trust=True,
            )

            if status.ok is not True:
                self.logger.exception(
                    "Error when encrypting file:",
                    status.status,
                )
                raise ValueError

    def encryptfilepgp(self):
        fingerprint = self.importpgpkey()
        try:
            self.encryptfilewithstatus(fingerprint)
        except Exception:
            self.logger.exception(
                "Error when encrypting file:",
                exc_info=True,
            )
        else:
            infomessage = "Encrypted {pgpfilename} successfully".format(
                pgpfilename=self.pgpfilename,
            )
            self.logger.info(infomessage)


class FileDecryptor(gnuPGHelper):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

    def decryptfilewithstatus(self, keyfingerprint):
        with open(self.datafilename, "rb") as datafile:
            status = self.pgpinstance.decrypt_file(
                datafile,
                output=self.pgpfilename,
                always_trust=True,
            )

            if status.ok is not True:
                self.logger.exception(
                    f"Error when decrypting file: {self.datafilename} with status {status.status}"
                )
                raise ValueError

            return status

    def decryptfilepgp(self):
        fingerprint = self.importpgpkey()

        status = self.decryptfilewithstatus(fingerprint)
        infomessage = f"Decrypted {self.datafilename} successfully to {self.pgpfilename}"
        self.logger.info(infomessage)
        return status
