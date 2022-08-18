from omfeds_lambda_python.remotefilenamedata import RemoteFileNameCollection


class RemoteFileNameDataFactory(object):
    def __init__(self, feedname):
        self.feedname = feedname
        self.remotefilenamecollection = RemoteFileNameCollection()
        self.remotefilenamelist = self.remotefilenamecollection.getremotefileslist()

    def getremotefilename(self):
        for item in self.remotefilenamelist:
            if item.feedname == self.feedname:
                return str(item)
        else:
            return self.feedname
