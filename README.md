# Httpbin on AWS ECS

## What is it?

This project is a definition of a Terraform infrastructure that runs on AWS ECS the docker image [httpbin](https://httpbin.org/), a simple HTTP API.

## Usage

* Install Terraform
* Setup AWS and configure your credentials
* Check you have the rights in your AWS account
  To deploy this infrastructure, you need to be granted the necessary rights. You could add to your user the Administrator role over your account, or you could progressively add the necessary policies.
* Clone this repo.
* `terraform init`
* Get your public IP
* Deploy your infrastrucutre `terraform apply -var="operator-ip=1.2.3.4/32"`
* Test the API `curl -X GET curl -X GET http://httpbin-load-balancer-730777461.eu-west-3.elb.amazonaws.com/get?param1=1234`
* Test auto-scaling `./launch_apache_bench.sh`
* Destroy the application `terraform destroy -var="operator-ip=1.2.3.4/32"`

## Comments

* Launch Type
  In this project, the containers are going to run on Fargate through ECS. This conveniently avoids the need for EC2 instances management or Kubernetes cluster management.
* Region:
  This project is currently deployed on eu-west-3 Paris, the nearest AWS region for me. For cost optimization, you may choose eu-east-1.
* Availability Zone:
  The minimum for redundancy is 1 (eu-west-3-a and eu-west-3-b)
  The supporting network is basic: 2 public subnets and 2 private ones paired in the 2 different zones.
* Docker image:
  The deployed image is a simple API server: httpbin. Any other image web server, without much configuration, could be deployed the same way.
  The chosen image to run httpbin is [kennethreitz/httpbin](https://hub.docker.com/r/kennethreitz/httpbin) on Docker Hub. Kenneth Reitz is a [main contributor](https://github.com/postmanlabs/httpbin/graphs/contributors) of httpbin. But relying on a third party image, unchecked, is a security hole.
  Alternatively you could put a verified image on ECR.
* Encryption:
  Only HTTP is supported here.
* Tagging:
  There is no overload of the code with tagging.
  In a regular environment, every resource should be tagged.
* Naming convention:
  All the resources which are singleton of their Terraform class are named "this".
* Security
  The security is minimalist and relies on running the task into the private subnets and only allowing connexions from the "operator" IP.

## Costs

Approximate Cost for an hour of running:
* data transfert < 1€
* Fargate (Memory + Cpu) < 1€
* NAT gateway (Data + time) < 1€
  (Fetching the container image outside of AWS is not optimal, especially when debugging!)
* Load Balancing <1€
