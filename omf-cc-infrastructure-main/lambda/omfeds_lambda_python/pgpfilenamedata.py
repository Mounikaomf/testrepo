from dataclasses import dataclass
import abc
import pendulum


@dataclass
class PGPFileName(abc.ABC):
    """Abstract data class defining file name for encrypted file. String 
    representation is concatenated from file variables

    File name is assumed to consist of 4 consecutive parts:
        - prefix
        - infix
        - suffix
        - extension

    If more complex definition of file name is needed, each part can be set as
    it is needed in concrete implementation.

    Each concrete implementation should be added to collections in 
    PGPFileNameCollection __init__ method

    Variables:
        feedname - used to identify concrete file naming implementation by
                   PGPFileNameDataFactory, should be used in lambda function
                   environment variable
        filenameprefix - file prefix
        filenameinfix - file infix
        filenamesuffix - file suffix
        filextension - file extension, usually separated using dot
    """
    feedname: str
    filenameprefix: str
    filenameinfix: str
    filenamesuffix: str
    fileextension: str

    def __str__(self):
        return (
            f"{self.filenameprefix}{self.filenameinfix}{self.filenamesuffix}{self.fileextension}"
        )


@dataclass
class AcxiomDirectMailPGPFileName(PGPFileName):
    feedname: str = "AcxiomDirectMail"
    filenameprefix: str = "omf_card_apps_"
    filenameinfix: str = pendulum.now().format("YYYYMMDD")
    filenamesuffix: str = ""
    fileextension: str = ".pgp"


class PGPFileNameCollection(object):
    """Collection of file name data objects, used by PGPFileNameDataFactory
    """
    def __init__(self):
        self.pgpfilenameslist = [
            AcxiomDirectMailPGPFileName(),
        ]
    
    def getpgpfileslist(self):
        """Returns list of file names as defined in __init__method
        This list is iterated by PGPFileNameDataFactory to determine file name
        pattern

        Returns:
            self.pgpfilenameslist: List of file names
        """
        return self.pgpfilenameslist