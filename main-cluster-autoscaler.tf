/* గమనిక: పై Terraform Node Group + discovery tags create చేస్తుంది. Cluster Autoscaler controller itself Terraform ద్వారా install చేయలేదు. అది Kubernetes/Helm side లో install చేయాలి.
AWS docs కూడా Node Group create చేసిన తర్వాత Cluster Autoscaler ని separately install చేయాలని చెబుతున్నాయి.
*/

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-2"

  default_tags {
    tags = {
      Project     = "eks-cluster-autoscaler"
      Environment = "lab"
    }
  }
}

# =========================================================
# VPC
# =========================================================

resource "aws_vpc" "eks" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "eks-lab-vpc"
  }
}

# =========================================================
# INTERNET GATEWAY
# =========================================================

resource "aws_internet_gateway" "eks" {
  vpc_id = aws_vpc.eks.id

  tags = {
    Name = "eks-lab-igw"
  }
}

# =========================================================
# PUBLIC SUBNETS
# =========================================================

resource "aws_subnet" "public" {
  count = 2

  vpc_id = aws_vpc.eks.id

  availability_zone = [
    "ap-south-2a",
    "ap-south-2b"
  ][count.index]

  cidr_block = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ][count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "eks-public-${count.index + 1}"

    "kubernetes.io/role/elb" = "1"
  }
}

# =========================================================
# PRIVATE SUBNETS
# =========================================================

resource "aws_subnet" "private" {
  count = 2

  vpc_id = aws_vpc.eks.id

  availability_zone = [
    "ap-south-2a",
    "ap-south-2b"
  ][count.index]

  cidr_block = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ][count.index]

  tags = {
    Name = "eks-private-${count.index + 1}"

    "kubernetes.io/role/internal-elb" = "1"
  }
}

# =========================================================
# PUBLIC ROUTE TABLE
# =========================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.eks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks.id
  }

  tags = {
    Name = "eks-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id = aws_subnet.public[count.index].id

  route_table_id = aws_route_table.public.id
}

# =========================================================
# NAT GATEWAYS - 2
# =========================================================

resource "aws_eip" "nat" {
  count = 2

  domain = "vpc"

  tags = {
    Name = "eks-nat-eip-${count.index + 1}"
  }

  depends_on = [
    aws_internet_gateway.eks
  ]
}

resource "aws_nat_gateway" "eks" {
  count = 2

  allocation_id = aws_eip.nat[count.index].id

  subnet_id = aws_subnet.public[count.index].id

  tags = {
    Name = "eks-nat-${count.index + 1}"
  }

  depends_on = [
    aws_internet_gateway.eks
  ]
}

# =========================================================
# PRIVATE ROUTE TABLES
# =========================================================

resource "aws_route_table" "private" {
  count = 2

  vpc_id = aws_vpc.eks.id

  route {
    cidr_block = "0.0.0.0/0"

    nat_gateway_id = aws_nat_gateway.eks[count.index].id
  }

  tags = {
    Name = "eks-private-rt-${count.index + 1}"
  }
}

resource "aws_route_table_association" "private" {
  count = 2

  subnet_id = aws_subnet.private[count.index].id

  route_table_id = aws_route_table.private[count.index].id
}

# =========================================================
# EKS CLUSTER IAM ROLE
# =========================================================

resource "aws_iam_role" "eks_cluster" {
  name = "eks-lab-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "eks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role = aws_iam_role.eks_cluster.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# =========================================================
# EKS CLUSTER
# =========================================================

resource "aws_eks_cluster" "eks" {
  name = "eks-lab-cas"

  role_arn = aws_iam_role.eks_cluster.arn

  version = "1.36"

  vpc_config {
    subnet_ids = aws_subnet.private[*].id
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# =========================================================
# NODE IAM ROLE
# =========================================================

resource "aws_iam_role" "node" {
  name = "eks-lab-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role = aws_iam_role.node.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role = aws_iam_role.node.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role = aws_iam_role.node.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

# =========================================================
# MANAGED NODE GROUP
# =========================================================

resource "aws_eks_node_group" "nodes" {

  cluster_name = aws_eks_cluster.eks.name

  node_group_name = "eks-lab-node-group"

  node_role_arn = aws_iam_role.node.arn

  subnet_ids = aws_subnet.private[*].id

  # We explicitly choose the EC2 instance type
  instance_types = ["t3.micro"]

  capacity_type = "ON_DEMAND"

  scaling_config {
    min_size = 2

    desired_size = 2

    max_size = 4
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr
  ]

  tags = {
    Name = "eks-lab-node-group"

    # Cluster Autoscaler discovery tags
    "k8s.io/cluster-autoscaler/enabled" = "true"

    "k8s.io/cluster-autoscaler/eks-lab-cas" = "owned"
  }
}

# =========================================================
# OUTPUTS
# =========================================================

output "cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "node_group_name" {
  value = aws_eks_node_group.nodes.node_group_name
}

output "region" {
  value = "ap-south-2"
}
