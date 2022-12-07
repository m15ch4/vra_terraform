#cloud-config

users:
  - name: ${os_username}
    primary_group: ${os_username}
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: sudo, wheel
    ssh_import_id: None
    lock_passwd: true
    ssh_authorized_keys:
      ${ssh_key_list}