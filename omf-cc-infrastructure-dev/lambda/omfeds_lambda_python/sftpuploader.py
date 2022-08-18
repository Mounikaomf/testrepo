import logging
import os
import paramiko
from datetime import date, datetime

class SftpClient(object):
    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)
        self.loglevel = kwargs.get("loglevel", "INFO")
        self.logger = logging.getLogger(__name__)
        self.logger.setLevel(os.environ.get("LOGLEVEL", self.loglevel))
        defaultsftpport = "22"
        self.sftpport = int(kwargs.get("sftpport", defaultsftpport))
        self.sftpdirectory = kwargs.get("sftpdirectory", None)

    def getsftptransport(self):
        return paramiko.Transport((self.sftphost, self.sftpport))

    def getsftpclient(self, sftptransport):
        sftptransport.connect(
            username=self.sftpuser,
            password=self.sftppassword,
            pkey=None,
        )
        return paramiko.SFTPClient.from_transport(sftptransport)

    @staticmethod
    def normalize_dirpath(dirpath):
        if dirpath is None or dirpath == "":
            dirpath = "/"
            return dirpath
        if dirpath != "/":
            while dirpath.endswith("/"):
                dirpath = dirpath[:-1]
        return dirpath


    #Returns the list of tuples with filename, modification datetime having substring <filenamepattern> on sftp
    #Source path: self.sftpdirectory + dirprefix
    def listfiles(self, dirprefix, filenamepattern, outcount):
        transport = self.getsftptransport()
        sftpclient = self.getsftpclient(transport)
        outfilelist=[]
        cnt = outcount
        
        remotepath = self.normalize_dirpath(self.sftpdirectory)

        if dirprefix is not None:
            remotepath = os.path.join(remotepath, dirprefix)

        if remotepath:
            try:
                sftpclient.chdir(remotepath)
            except FileNotFoundError:
                errormessage = "Error when changing remote directory: "
                self.logger.critical(errormessage, exc_info=True)
                
        files = sftpclient.listdir_attr()
        files.sort(key = lambda f: f.st_mtime, reverse = True)

        for file in files:
            if cnt < 1:
                break

            self.logger.info("listfiles__fileattr.filename: " + str(file.filename))
            self.logger.info("listfiles__file.st_mtime: " + str(file.st_mtime))

            if filenamepattern in file.filename:
                fileproperties = (file.filename, datetime.fromtimestamp(file.st_mtime))
                outfilelist.append(fileproperties)

            cnt -=1

        return outfilelist


#Source path: self.sftpdirectory (same as for SftpUploader), target path: /tmp/
#input filenamelist like ["filename1,filename2"]
class SftpDownloader(SftpClient):
    def __init__(self, **kwargs):
        SftpClient.__init__(self, **kwargs)

    def sftpgetfiles(self, filenamelist):
        transport = self.getsftptransport()
        sftpclient = self.getsftpclient(transport)

        if self.sftpdirectory:
            try:
                sftpclient.chdir(self.sftpdirectory)
            except FileNotFoundError:
                errormessage = "Error when changing remote directory: "
                self.logger.critical(errormessage, exc_info=True)

        with transport:
            try:
                for filename in filenamelist:
                    self.logger.info("Proccessing file: " + filename)
                    sftpclient.get(filename, f"/tmp/{os.path.basename(filename)}")
            except Exception:
                errormessage = "Error when downloading file: "
                self.logger.critical(errormessage, exc_info=True)
                raise
            else:
                infomessage = f"File downloaded from SFTP successfully"
                self.logger.info(infomessage)


class SftpUploader(SftpClient):
    def __init__(self, **kwargs):
        SftpClient.__init__(self, **kwargs)

    def sftpputlocalfile(self):

        transport = self.getsftptransport()
        sftpclient = self.getsftpclient(transport)
        remotfilename = os.path.basename(self.localfilename)

        if self.sftpdirectory:
            try:
                sftpclient.chdir(self.sftpdirectory)
            except FileNotFoundError:
                errormessage = "Error when changing remote directory: "
                self.logger.critical(errormessage, exc_info=True)

        with transport:
            try:
                sftpclient.put(self.localfilename, remotfilename)
            except Exception:
                errormessage = "Error when uploading file: "
                self.logger.critical(errormessage, exc_info=True)
                raise
            else:
                infomessage = f"Uploaded {self.localfilename} to SFTP successfully"
                self.logger.info(infomessage)
