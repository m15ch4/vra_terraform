#cloud-config

users:
  - name: test
    primary_group: test
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: sudo, wheel
    ssh_import_id: None
    lock_passwd: true
    ssh_authorized_keys:
      ${ssh_key_list}