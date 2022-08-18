from omfeds_lambda_python.pgpfilenamedata import PGPFileNameCollection


class PGPFileNameDataFactory(object):
    def __init__(self, feedname):
        self.feedname = feedname
        self.pgpfilenamecollection = PGPFileNameCollection()
        self.pgpfilenamelist = self.pgpfilenamecollection.getpgpfileslist()

    def getpgpfilename(self):
        for item in self.pgpfilenamelist:
            if item.feedname == self.feedname:
                return str(item)
        else:
            return self.feedname
