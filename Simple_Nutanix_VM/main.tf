data "nutanix_cluster" "cluster" {
  name = "nutanix-1"
}

data "nutanix_subnet" "subnet" {
  subnet_name = "VM"
}

data "template_file" "user-data" {
  template = file("user-data.tpl")

  vars = {
    hostname = "vm13"
    ssh_key_list = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCtejAUUWE/y5G3gmO2J7LlRjqDZZB++HQ6T14+TGc0mUB+xIFRHiscrGuGqU0VfAVVvIYWwpBvBt54btgz7TQHvkBxBFHaTxQ3vlfQlG5xBtozfe39tbcJhl7z6bQJC8y4gOcdlp4s7vZNZzQ4XCZ2u/cQgXRaziDLujCzMC4899m2JBme71rXthLtRgzjLCpeK39LUkK3jvx2z7c3hlClrAg6zWiB/YQfveFdYncQEtpS6qgZLpk16GwRPfsOImINqD/HknmTEba3oXjkCYer6X6QZdUATrkh7EB1AcEsr82qH+I8zeUEWukdDqWVIrGE4/1op0iJHvktYzgztRhL micze@mczerwinski-a01.vmware.com"
    os_username = "micze"
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

  guest_customization_cloud_init_user_data = base64encode(data.template_file.user-data.rendered)
}