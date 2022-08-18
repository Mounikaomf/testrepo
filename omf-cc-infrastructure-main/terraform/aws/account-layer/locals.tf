locals {
  tags-dev = {
    environment    = "dev"
    cost_center    = "25000337"
    ledger_account = "625010"
    data_classification = "confidential"
    creator = "eds-devops"
  }
  tags-qa1 = {
    environment    = "qa1"
    cost_center    = "25000337"
    ledger_account = "625010"
  }
  tags-uat = {
    environment    = "uat"
    cost_center    = "25000337"
    ledger_account = "625010"
  }
}
