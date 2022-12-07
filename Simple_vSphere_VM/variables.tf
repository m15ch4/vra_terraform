variable "vsphere_server" {
  description = "vSphere server"
  type        = string
  default = "vc.home.lab"
}

variable "vsphere_user" {
  description = "vSphere username"
  type        = string
  default = "administrator@vsphere.local"
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
  default = "VMware1!"
  sensitive = true
}

variable "cpus" {
  description = "Number of CPUs"
  type = number
  default = 2
}

variable "vm_name" {
  description = "VM Name"
  type        = string
}

variable "template" {
  description = "VM Template"
  type        = string
  default = "debiantemplate"
}

variable "ssh_keys" {
  description = "SSH authorized keys"
  type = string
}

variable "disks" {
  type = set(object({
    label = string
    unit_number = number
    size = number
  }))
  default = [
    {
      label = "diskA"
      unit_number = 3
      size = 3
    },
    {
      label = "diskB"
      unit_number = 4
      size = 4      
    }
  ]
}