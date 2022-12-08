##Provider

# vsphere provider
terraform {
  required_providers {
    vsphere = {
      source = "hashicorp/vsphere"
      version = "2.2.0"
    }
  }
}

provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}


##Data (variables should be used here)

data "vsphere_datacenter" "dc" {
  name = "Home-DC"
}

data "vsphere_datastore" "datastore" {
  name          = "vsanDatastore"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = "vsan-cluster"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.portgroup
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.template
  datacenter_id = data.vsphere_datacenter.dc.id
}

##Cloud-init
data "template_file" "meta-data" {
  template = file("meta-data.tpl")

  vars = {
    hostname = var.vm_name
    ssh_key_list = var.ssh_keys
  }
}
data "template_cloudinit_config" "meta-data" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.meta-data.rendered
  }
}

data "template_file" "user-data" {
  template = file("user-data.tpl")

  vars = {
    hostname = var.vm_name
    ssh_key_list = var.ssh_keys
    os_username = var.os_username
  }
}
data "template_cloudinit_config" "user-data" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.user-data.rendered
  }
}

##vSphere VMs

resource "vsphere_virtual_machine" "vm01" {
  name             = var.vm_name
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = var.cpus
  memory   = 4096
  guest_id = data.vsphere_virtual_machine.template.guest_id

  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

# Name disks
   dynamic "disk" {
    for_each = data.vsphere_virtual_machine.template.disks

    content {
      label = disk.value.label
      unit_number = disk.value.unit_number
      size = disk.value.size
    }
  } 

  dynamic "disk" {
    for_each = var.disks
    content {
      label = disk.value.label
      unit_number = disk.value.unit_number
      size = disk.value.size
    }
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }

## Below commented remote-exec provisioner wont work with password authentication
## It should be fixed to use private key to connect through SSH

# connection {
#    type     = "ssh"
#    user     = "micze"
#    password = "VMware1!"
#    host     = vsphere_virtual_machine.vm01.default_ip_address
# }

# provisioner "remote-exec" {
#   inline = [
#    "sleep 60",
#      "echo test > /tmp/test.txt"      
#    ]
# }

## guestinfo is read by cloud-init

  extra_config = {
    "guestinfo.metadata"          = base64encode(data.template_file.meta-data.rendered)
    "guestinfo.metadata.encoding" = "base64"
    "guestinfo.userdata"          = base64encode(data.template_file.user-data.rendered)
    "guestinfo.userdata.encoding" = "base64"
  }

}

 ##Output

output "ip" {
  value = vsphere_virtual_machine.vm01.default_ip_address
}

