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
* web server (eg. Nginx)
* two docker hosts (1 in offline environment and 1 in environment that has access to internet)
* k8s cluster (eg. TKGs cluster)

## Deploy container image registry - Harbor
1. Prepare VM that will host Harbor (docker, docker-compose)
2. Follow instructions available at https://goharbor.io/docs/2.6.0/install-config/

* the important part here is to have Harbor running on https. The certificate of Harbor will be used later while deploying TKC.

## Deploy remote source version control - Gitlab
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

Add ```location``` directive to nginx configuration file in ```server``` section:
```
location /tf/ {
    autoindex on;
}
```

Also keep in mind that ```root``` directive must be set for ```server```.

## Docker hosts
Docker host that has internet access will be used to:
1. pull image

``` docker pull projects.registry.vmware.com/vra/terraform:latest```

2. build new image containing required provider(s)

For this purpose you have to create Dockerfile that looks similar to the following one:

```
FROM projects.registry.vmware.com/vra/terraform:latest as final
 
# Create provider plug-in directory
ARG plugins=/tmp/terraform.d/plugin-cache/linux_amd64
RUN mkdir -m 777 -p $plugins
  
# Download and unzip all required provider plug-ins from hashicorp to provider directory
RUN cd $plugins \
    && mkdir -p registry.terraform.io/hashicorp/vsphere/2.2.0/linux_amd64/ \
    && cd registry.terraform.io/hashicorp/vsphere/2.2.0/linux_amd64/
    && wget -q https://releases.hashicorp.com/terraform-provider-vsphere/2.2.0/terraform-provider-vsphere_2.2.0_linux_amd64.zip \
    && unzip *.zip \
    && rm *.zip \
  
# For "terraform init" configure terraform CLI to use provider plug-in directory and not download from internet
ENV TF_CLI_ARGS_init="-plugin-dir=$plugins"
```

Note: Dockerfile can look different for different Terraform versions. Above on is suitable for version 1.0 of TF.

Build, tag and save container image.
```
docker build -t harbor.home.lab/library/terraform_vsphere:0.1

docker save --output terraform_vsphere.tar harbor.home.lab/library/terraform_vsphere:0.1 
```

Now move the ```terraform_vsphere.tar``` file to docker host on internet restricted environment and load it.
```
docker load --input terraform_vsphere.tar
```

To verify successful load of container image run ```docker image list```.

Then you need to upload image to image registry.
```
docker push harbor.home.lab/library/terraform_vsphere:0.1
```
