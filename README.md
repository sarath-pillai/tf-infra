# IAC for EKS Kubernetes cluster with Nginx & Cert Manager
### Description
The main purpose of this repository is to demonstrate the creation of a kubernetes cluster in AWS Cloud (eks - managed cluster), along with several cluster level components like nginx ingress controller, network load balancer, and letsencrypt certificate manager. 

Any changes to `master` branch will get auto deployed to the AWS account in question. 

### Prerequisite
- This project assumes that you have an AWS Account with right level of access. 
- This workflow (github workflow) in this repository requires that you have added secrets for AWS account access (`AWS_ACCESS_KEY_ID` & `AWS_SECRET_ACCESS_KEY`)
- You own a domain that can be used for this (in this example repository i have used a subdomain named `demo.slashroot.in`)
- The Route53 Zone created by this IAC will have several NS records. Which have to be added to the domain registrator. In this case, i had to add NS record for the domain `demo.slashroot.in` in the zone of `slashroot.in` (this part was done manually)

### Infrastructure resources created
This repository is mainly terraform HCL content. The terraform resources defined in this repository creates the below cloud resources. 

- An EKS cluster. 
- A VPC with public & Private Subnets. 
- Deploys on top of the EKS cluster several k8s components like nginx-ingress controller, certificate manager for letsencrypt. 
- A public route53 zone

### Terraform Variables
| Variable Name | Description |
| ------ | ------ |
| clusters | Basically tagged nodes that are basically node groups in the eks cluster. You can have different set of node groups to achieve different purpse and target your deployment based on these nodes |
|cluster_version|EKS Kubernetes cluster version. By default its set to 1.21|
|domain_name|The zone for route53|
|environment|The environment name that will be added to different resource names. Default is demo|


We use the publicly available terraform modules for EKS & VPC to achieve some of our work here. Mainly to stick with DRY principle, We can also create our own module and house it inside a dedicated git repository named as `tf-modules` and reference it from another repository. 

The load balancer created in this infrastructure does not have an SSL certificate attached to it. The SSL certificate is attached and served by nginx ingress controller. Nginx controller uses the certificate created by certificate manager for letsencrypt. There are several advantages to this. The main one being that traffic is end to end encrypted (in other cases, traffic between the load balancer and the backend kubernetes node in aws is not encrypted).

Apart from using this certificate manager for auto renewal, we could have also used ALB ingress controller with proper annotations and ACM for SSL certificates. This way 3 months renewal process is not required. 

### How does this get deployed
This repository uses Github workflow as its deployment method. I have selected github workflow for illustration purpose only. This can be adapted to use Jenkins by committing a Jenkinsfile to the root of the repository as well.  Or any other CI tool for that matter. Any commits to the main branch gets auto deployed to AWS cloud using github workflow. You can see the workflow configuration file here: https://github.com/sarath-pillai/tf-infra/blob/main/.github/workflows/actions.yaml


Once the cluster is deployed, the terraform helm provider uses EKS cluster outputs for initializing itself. Helm then can deploy stuff like nginx-ingress & cert-manager. 

Apart from Helm, we also use kubernetes provider in terraform to deploy `letsencrypt` clusterissuer. This basically configures the acme server and ingress class settings etc. 

The nginx-ingress controller deployment creates an AWS load balancer whose endpoint CNAME is then grabbed using the `kubernetes_service` data source. This is then given as inoput to a wild card DNS entry for `*.demo.slashroot.in`
