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
* k8s cluster (eg. TKGs cluster)

## Deployment container image registry - Harbor
1. Prepare VM that will host Harbor (docker, docker-compose)
2. Follow instructions available at https://goharbor.io/docs/2.6.0/install-config/

* the important part here is to have Harbor running on https. The certificate of Harbor will be used later while deploying TKC.

## Deployment of remote source version control - Gitlab
1. Prepare VM that will host GitLab
2. Follow the manual to deploy GitLab (ce) application 

## Web server configuration - Nginx
Web server running on internet restricted environment is used to host Terraform binaries.

Download Terraform binaries from https://releases.hashicorp.com/terraform eg. https://releases.hashicorp.com/terraform/1.0.5/terraform_1.0.5_linux_amd64.zip

You have to download binaries for each version of Terraform that you plan to use. For vRA 8.10 the latest version of Terraform that is supported is version 1.0.

Transfer downloaded zip files to Web server and place them in selected directory eg. /etc/nginx/html/tf/.
Directories needs to have 755 and files 644 permissions.

```
root@docker [ /etc/nginx/html ]# tree
.
├── 50x.html
├── index.html
└── tf
    └── terraform_1.0.5_linux_amd64.zip

1 directory, 3 files
```

Add ```location``` directive to nginx configuration file in server section:
```
location /tf/ {
    autoindex on;
}
```

Also keep in mind that ```root``` directive must be set for ```server```.
