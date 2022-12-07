instance-id: ${hostname}
local-hostname: ${hostname}
hostname: ${hostname}
network:
  version: 2
  ethernets:
    ens192:
      match:
        e*
      dhcp4: yes