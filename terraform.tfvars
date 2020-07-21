rgname        = "ref-tf-rg"
location      = "WestEurope"
sshkeypath    = "~/.ssh/id_rsa.pub"
vnetprefix    = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/27","10.0.3.0/27"]
sapappsubnet  = "10.0.0.0/24"
sapdbsubnet   = "10.0.1.0/24"
bastionsubnet = "10.0.2.0/27"
hubsubnet     = "10.0.3.0/27"
appvmname     = "ref-app-vm"
appvmsize     = "Standard_D4s_v3"
dbvmname      = "ref-db-vm"
dbvmsize      = "Standard_D8s_v3"
routervmname  = "ref-saprouter"
routervmsize  = "Standard_D2s_v3"
natports = ["3200","3300","3600","3900","8000","8100"]
luns = [0, 1, 2, 3, 4, 5, 6, 7, 8]
cache_settings = ["None", "None", "None", "None", "None","None","None","ReadOnly", "ReadWrite"]
disksizes = [128, 128, 128, 128, 128, 128, 128, 512, 64]
waflag =  ["false", "false", "false", "false", "false", "false", "false", "false", "false"]



