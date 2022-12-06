##Provider

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
  name          = "seg-overlay-151"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.template
  datacenter_id = data.vsphere_datacenter.dc.id
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


  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }

 connection {
    type     = "ssh"
    user     = "micze"
    password = "VMware1!"
    host     = vsphere_virtual_machine.vm01.default_ip_address
 }

 provisioner "remote-exec" {
   inline = [
    "sleep 60",
      "echo test > /tmp/test.txt"
      
    ]
 }

 }

 ##Output

output "ip" {
value = vsphere_virtual_machine.vm01.default_ip_address

}