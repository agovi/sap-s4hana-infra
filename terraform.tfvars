rgname = "ref-tf-rg"
location = "WestEurope" 
sshkeypath = "~/.ssh/id_rsa.pub"
vnetprefix = ["10.0.0.0/24", "10.0.1.0/24","10.0.2.0/27"] 
sapappsubnet = "10.0.0.0/24"
sapdbsubnet = "10.0.1.0/24"
bastionsubnet = "10.0.2.0/27"
appvmname = "ref-app-vm"
appvmsize = "Standard_D4s_v3"
dbvmname = "ref-db-vm"
dbvmsize = "Standard_D8s_v3"

