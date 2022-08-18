from dataclasses import dataclass
from typing import List
import pendulum
import abc


@dataclass
class RemoteFileName(abc.ABC):
    """Abstract data class defining file name for files copied between s3 
    buckets. String representation is concatenated from file variables

    File name is assumed to consist of 4 consecutive parts:
        - prefix
        - infix
        - suffix
        - extension

    If more complex definition of file name is needed, each part can be set as
    it is needed in concrete implementation.

    Each concrete implementation should be added to collections in 
    RemoteFileNameCollection __init__ method

    Variables:
        feedname - used to identify concrete file naming implementation by
                   RemoteFileNameDataFactory, should be used in lambda function
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
class AcxiomDirectMailRemoteFileName(RemoteFileName):
    feedname: str = "AcxiomDirectMail"
    filenameprefix: str = "omf_card_apps_"
    filenameinfix: str = pendulum.now().format("YYYYMMDD")
    filenamesuffix: str = ""
    fileextension: str = ".csv"


@dataclass
class WebBankReport1RemoteFileName(RemoteFileName):
    feedname: str = "WebBankReport1"
    filenameprefix: str = "WB1_"
    filenameinfix: str = pendulum.now().format("DD.MM.YYYY")
    filenamesuffix: str = ""
    fileextension: str = ".csv"


@dataclass
class WebBankReport2RemoteFileName(RemoteFileName):
    feedname: str = "WebBankReport2"
    filenameprefix: str = "WB2_"
    filenameinfix: str = pendulum.now().format("DD.MM.YYYY")
    filenamesuffix: str = ""
    fileextension: str = ".csv"


@dataclass
class WebBankReport4RemoteFileName(RemoteFileName):
    feedname: str = "WebBankReport4"
    filenameprefix: str = "OMF_cards_ECOA_Adverse_action_Report_"
    filenameinfix: str = pendulum.now().format("DDMMYYYY")
    filenamesuffix: str = ""
    fileextension: str = ".csv"

@dataclass
class SanctionsReport2RemoteFileName(RemoteFileName):
    feedname: str = "SanctionsReport"
    filenameprefix: str = "OMFCardsPortM"
    filenameinfix: str = ""
    filenamesuffix: str = ""
    fileextension: str = ".csv"


@dataclass
class Report314a2RemoteFileName(RemoteFileName):
    feedname: str = "Report314a"
    filenameprefix: str = "OMFCards314a"
    filenameinfix: str = ""
    filenamesuffix: str = ""
    fileextension: str = ".csv"

class RemoteFileNameCollection(object):
    def __init__(self):
        self.remotefilenameslist = [
            AcxiomDirectMailRemoteFileName(),
            WebBankReport1RemoteFileName(),
            WebBankReport2RemoteFileName(),
            WebBankReport4RemoteFileName(),
            SanctionsReport2RemoteFileName(),
            Report314a2RemoteFileName(),
        ]
    
    def getremotefileslist(self):
        return self.remotefilenameslist
