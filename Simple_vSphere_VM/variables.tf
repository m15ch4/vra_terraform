variable "vsphere_server" {
  description = "vSphere server"
  type        = string
}

variable "vsphere_user" {
  description = "vSphere username"
  type        = string
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
}

variable "cpus" {
  description = "Number of CPUs"
  type = number
}

variable "vm_name" {
  description = "VM Name"
  type        = string
}

variable "template" {
  description = "VM Template"
  type        = string
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