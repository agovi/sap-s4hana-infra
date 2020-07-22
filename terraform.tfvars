rgname           = "ref-tf-rg-weu"
location         = "WestEurope"
sshkeypath       = "~/.ssh/id_rsa.pub"
vnetprefix       = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/27", "10.0.3.0/27"]
sapappsubnet     = "10.0.0.0/24"
sapdbsubnet      = "10.0.1.0/24"
bastionsubnet    = "10.0.2.0/27"
hubsubnet        = "10.0.3.0/27"
appvmname        = "ref-app-vm"
appvmsize        = "Standard_D4s_v3"
dbvmname         = "ref-db-vm"
dbvmsize         = "Standard_D8s_v3"
routervmname     = "ref-saprouter"
routervmsize     = "Standard_D2s_v3"
sapapp-ports     = ["3900","8001","8000","3600","3301","3201","4237","4239"]
sapdb-ports      = ["30015","30013","50013","30040","30041","30042","1128","1129"]
dbdiskluns       = [0, 1, 2, 3, 4, 5, 6, 7, 8]
dbdiskcache      = ["None", "None", "None", "None", "None", "None", "None", "ReadOnly", "ReadWrite"]
dbdisksizes      = [128, 128, 128, 128, 128, 128, 128, 512, 64]
dbdiskwaflag     = ["false", "false", "false", "false", "false", "false", "false", "false", "false"]
asset-insight-id = "xxxxxxx"
creator-email    = "karthik.venkatraman@microsoft.com"
creator-id       = "karthik.venkatraman@microsoft.com"



