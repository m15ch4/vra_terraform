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

For the purpose of this demo Harbor runs on https://harbor.home.lab

## Deploy remote source version control - Gitlab
1. Prepare VM that will host GitLab
2. Follow the manual to deploy GitLab (ce) application 

For the purpose of this demo GitLab runs on https://gitlab.home.lab

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
On Docker host that has access to the Internet do the following:

1. Pull reference image:

``` docker pull projects.registry.vmware.com/vra/terraform:latest```

2. Build new image containing required provider(s)

For this purpose you have to create ```Dockerfile``` that looks similar to the following one:

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

Note: Dockerfile can look different for different Terraform versions. Above ```Dockerfile``` is suitable for version 1.0 of TF.

Also keep in mind that paths for different providers will differ. 

Build, tag and save container image.
```
docker build -t harbor.home.lab/library/terraform_vsphere:0.1
```
```
docker save --output terraform_vsphere.tar harbor.home.lab/library/terraform_vsphere:0.1 
```

You can verify if the providers are in correct directories using ```dive``` util available on https://github.com/wagoodman/dive.

Now move the ```terraform_vsphere.tar``` file to docker host on internet restricted environment and load it.
```
docker load --input terraform_vsphere.tar
```

To verify successful load of container image run ```docker image list```.

Then you need to upload image to image registry.
```
docker push harbor.home.lab/library/terraform_vsphere:0.1
```

## Kubernetes cluster
vRA executes Terraform mainfests inside PODs that are started in k8s cluster using image prepared in previous step. As the prepared image doesn't contain Terraform binary, it will be downloaded from the web server that we already prepared.

For this demo, TKC cluster will be used as container runtime. You can spinout TKC cluster using following specification - ```tkc1.yaml```.
```
apiVersion: run.tanzu.vmware.com/v1alpha3
kind: TanzuKubernetesCluster
metadata:
  name: tkc1
  namespace: dev-ns
spec:
  topology:
    controlPlane:
      replicas: 1
      vmClass: best-effort-small
      storageClass: vsan-default-storage-policy
      tkr:
        reference:
          name: v1.21.6---vmware.1-tkg.1.b3d708a
    nodePools:
    - replicas: 2
      name: worker
      vmClass: best-effort-small
      storageClass: vsan-default-storage-policy
  settings:
    storage:
      classes: [vsan-default-storage-policy]
      defaultClass: vsan-default-storage-policy
    network:
      cni:
        name: antrea
      pods:
        cidrBlocks: ["192.0.5.0/16"]
      services:
        cidrBlocks: ["198.53.100.0/16"]
      trust:
        additionalTrustedCAs:
          - name: harborCA
            data: LS0tLS...Qo=
```

Notice last four lines of this file containing Harbor certificate (b64 encoded). This is required to make k8s nodes able to download container images from registry thats certificate is not trusted by default.

## Notes on Cloud Template

When creating Cloud Template from Terraform mainfest vRA automatically finds variables in TF manifest and creates inputs in Cloud Templates yaml. 

For example in ```Simple_vSphere_VM``` a set of variables are declared:
```
variable "vsphere_server" {
  description = "vSphere server"
  type        = string
}

[...]

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
```

and are respectively mapped to inputs in Cloud Template: 

```
inputs:
  vsphere_server:
    type: string
    description: vSphere server

[...]

  disks:
    type: array
    default:
      - |-
        {
        label="diskA"
        unit_number=3
        size=3
        }
      - |-
        {
        label="diskB"
        unit_number=4
        size=4
        }
```

You can tune automatically created inputs by adding constraints, default values, etc. just as for other Cloud Templates. Additionally for array, set and map variables like ```disks``` in this example that is by default recognized as array of strings you should change it to be rendered correctly in the deployment request form.

```
  disks:
    type: array
    items:
      type: object
      properties:
        label:
          type: string
        unit_number:
          type: number
        size:
          type: number
```