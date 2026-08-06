# EKS-
EKS zero to hero from zero to hero

CHAPTER 1
 What cloud computing is
* Why companies use the cloud
* Cloud service models (IaaS, PaaS, SaaS)
* Deployment models
* Virtualization
* Regions and Availability Zones
* High Availability
* Scalability
* Load Balancing
* Disaster Recovery
* AWS Global Infrastructure
* Shared Responsibility Mode
  </br>
Characteristics of Cloud Computing

* On-demand self-service
* Broad network access
* Resource pooling
* Rapid elasticity
* Measured service (pay-as-you-go)

 IAAS PAAS SAAS

* Containers are generally:

  Faster to start
  Smaller in size
  More resource-efficient
 This is why Kubernetes and Amazon EKS use containers.
   Region--AZ-datacenters

Vertical scaling \
Horizontal scaling

17. Disaster Recovery (DR)
Disaster Recovery is the ability to restore systems after a major failure.
Common strategies:
* Backup and Restore
* Pilot Light
* Warm Standby
* Multi-site Active/Active

  CHAPTER 2
  AWS Cloud

├── Compute
│     ├── EC2
│     ├── Lambda
│     └── ECS/EKS
│
├── Storage
│     ├── S3
│     ├── EBS
│     └── EFS
│
├── Database
│     ├── RDS
│     └── DynamoDB
│
├── Networking
│     ├── VPC
│     ├── Route53
│     └── Load Balancer
│
├── Security
│     ├── IAM
│     └── KMS
│
└── Monitoring
      └── CloudWatch

EACH AWS ACCOUNT HAS
* Unique account ID
* Billing information
* Security boundaries

SPECIALISED POLICIES
Job-Function Managed Policies

Permissions Boundaries

Service Control Policies (SCPs)

Resource Control Policies (RCPs)

Attribute-Based Access Control (ABAC)

Conditional Permissions

@@@@@@@@@@@@@@@
LEARN CLI COMMANDS

General Purpose

Compute Optimized

Memory Optimized

Storage Optimized

Accelerated Computing, on demand, spot, reserved

VPC

├── CIDR Block

├── Subnets

├── Route Tables

├── Internet Gateway

├── NAT Gateway

└── Security Groups

 Internet Gateway (IGW) Allows communication between VPC and internet
 NAT Gateway: Allows private resources to access the internet.  * Software updates
                                                                * Package downloads
                                                                * Container image pulls

 Route Tables: Route tables decide where network traffic goes.  

 Network ACL works at subnet level.

Comparison:

| Security Group   | NACL             |
| ---------------- | ---------------- |
| Instance level   | Subnet level     |
| Stateful         | Stateless        |
| Allow rules only | Allow/Deny rules |

ALB 7, http, https
NLB 4, tcp, udp


































  
