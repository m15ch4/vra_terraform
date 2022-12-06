# vra_terraform

Contains Terraform plans used by vRA 8 to deploy VMs on different platforms.

## Currently used providers
* vSphere
* Nutanix ??

## Requirements
To use vRA 8 and Terraform integration we need below components to run and to be properly configured. 
For offline environment we need:
* image registry (eg. Harbor)
* remote svc system (eg. GitLab)
* web server
* two docker hosts (1 in offline environment and 1 in environment that has access to internet)
* k8s cluster
