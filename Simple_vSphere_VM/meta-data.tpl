instance-id: ${hostname}
local-hostname: ${hostname}
hostname: ${hostname}
network:
  version: 2
  ethernets:
    nics:
      match:
        name: ens*
      dhcp4: yes