#!/bin/bash
#Author : Karthik Venkatraman
set -x
######## Check Variables###############
if [ "$(whoami)" != "root" ];then
    echo "Run the script as root user"
    exit 1
fi

# Check if mount points already exists
mcount1=$(mount -t xfs | grep -i hana | wc -l)
mcount2=$(mount -t xfs | grep -i sap | wc -l)
if [ $mcount1 != 0 ] ;then
   echo "HANA filesystems exist"
   exit 1
  if [ $mcount2 != 0 ];then
  echo "SAP filesystems already exist"
  exit 1
  fi
fi

echo "Creating filesystems"

for i in 0 1 2 3 4 5 6 7 8 
    do
      echo "Checking existence of LUNs"
      if [ ! -L "/dev/disk/azure/scsi1/lun${i}" ]; then
      echo "Lun ${i} not added"
      exit 1
      echo "pvcreate /dev/disk/azure/scsi1/lun${i}"
      pvcreate "/dev/disk/azure/scsi1/lun${i}"
        if [ $? != 0 ];then
        exit 1
        fi 
      fi
    done
    echo " PV created"

       # Creation of directories
    if [ ! -d "/hana/data" ];then
        mkdir -p /hana/data
    else
        echo "Data directory exists"
    fi
    if [ ! -d "/hana/log" ];then
        mkdir -p /hana/log
    else
        echo "Log directory exists"
    fi
    if [ ! -d "/hana/shared" ];then
        mkdir -p /hana/shared
    else
        echo "Shared directory exists"
    fi
    if [ ! -d "/hana/backup" ];then
        mkdir -p /hana/backup
    else
        echo "Backup directory exists"
    fi
    if [ ! -d "/usr/sap" ];then
        mkdir -p /usr/sap
    else
        echo "/usr/sap directory exists"
    fi
    echo "Directories created"

    # Create a backup of /etc/fstab
    cp /etc/fstab /etc/fstab.orig
    if [ $? != 0 ];then
     echo "Couldnt backup fstab. Please check why"
     exit 1
    fi

    # Creating VGs
    flag=1
        echo "Creating VGs,LVs and filesystems"
        vgcreate vg_hana_data /dev/disk/azure/scsi1/lun0 /dev/disk/azure/scsi1/lun1 /dev/disk/azure/scsi1/lun2 /dev/disk/azure/scsi1/lun3
        lvcreate -i 4 -I 256 -l 100%FREE -n hana_data vg_hana_data
        mkfs.xfs /dev/vg_hana_data/hana_data
        datafs=$(blkid | grep -i vg_hana_data | cut -d '"' -f 2)
        echo "/dev/disk/by-uuid/$datafs /hana/data xfs defaults,nofail  0  2"  >> /etc/fstab
        if [ $? = 0 ];then
        vgcreate vg_hana_log /dev/disk/azure/scsi1/lun4 /dev/disk/azure/scsi1/lun5 /dev/disk/azure/scsi1/lun6
        lvcreate -i 3 -I 64 -l 100%FREE -n hana_log vg_hana_log
        mkfs.xfs /dev/vg_hana_log/hana_log
        logfs=$(blkid | grep -i vg_hana_log | cut -d '"' -f 2)
        echo "/dev/disk/by-uuid/$logfs /hana/log xfs defaults,nofail  0  2"  >> /etc/fstab
        if [ $? = 0 ];then
        vgcreate vg_hana_shared /dev/disk/azure/scsi1/lun7
        lvcreate -l 100%FREE -n hana_shared vg_hana_shared
        mkfs.xfs /dev/vg_hana_shared/hana_shared
        sharedfs=$(blkid | grep -i vg_hana_shared | cut -d '"' -f 2)
        echo "/dev/disk/by-uuid/$sharedfs /hana/shared/ xfs defaults,nofail  0  2"  >> /etc/fstab
        if [ $? = 0 ];then
        vgcreate vg_usr_sap /dev/disk/azure/scsi1/lun8
        lvcreate -l 100%FREE -n usr_sap vg_usr_sap
        mkfs.xfs /dev/vg_usr_sap/usr_sap
        usrsap=$(blkid | grep -i vg_usr_sap | cut -d '"' -f 2)
        echo "/dev/disk/by-uuid/$usrsap /usr/sap/ xfs defaults,nofail  0  2"  >> /etc/fstab
        if [ $? = 0 ];then
        echo "VGs and LVs created successfully"
        flag=0
        fi 
        fi
        fi
        fi
    if [ $flag != 0 ]; then
       echo "VGs not created"
       exit 1
    fi
   echo "Filesystems created successfully"
   mount -a
    if [ $? != 0 ]; then
       echo "Filesystems count not be mounted"
       exit 1
    fi
   echo "Filesystems mounted"