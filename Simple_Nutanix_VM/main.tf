data "nutanix_cluster" "cluster" {
  name = "nutanix-1"
}

data "nutanix_subnet" "subnet" {
  subnet_name = "VM"
}

resource "nutanix_virtual_machine" "vm" {
  name                 = "MyVM from the Terraform Nutanix Provider"
  cluster_uuid         = data.nutanix_cluster.cluster.id
  num_vcpus_per_socket = "2"
  num_sockets          = "1"
  memory_size_mib      = 1024

  disk_list {
    data_source_reference = {
      kind = "image"
      uuid = "a11bb6ac-3b16-4a75-b129-1e763f340b64"
    }
  }

  disk_list {
    disk_size_bytes = 2 * 1024 * 1024 * 1024
    device_properties {
      device_type = "DISK"
      disk_address = {
        "adapter_type" = "SCSI"
        "device_index" = "1"
      }
    }
  }

  nic_list {
    subnet_uuid = data.nutanix_subnet.subnet.id
  }
}