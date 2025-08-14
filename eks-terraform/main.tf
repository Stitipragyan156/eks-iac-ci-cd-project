provider "aws" {
  region = "us-east-1"  # Specify your desired region
}

 resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

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

# Attach AWS managed policies for EKS control plane
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}
resource "aws_iam_role" "eks_node_group_role" {
  name = "eks-node-group-role"

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

# Attach AWS managed policies for worker nodes
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_readonly" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_eks_cluster" "example" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = ["subnet-xxxx", "subnet-yyyy"]
  }
}



 
 # data source 
 data "aws_vpc" "newvpc" {
  tags = {
    Name = "new-vpc"  # Specify the name of your existing VPC
  }
}

data "aws_subnet" "public-subnet1" {
 vpc_id = data.aws_vpc.newvpc.id
 filter {
    name = "tag:Name"
    values = ["public-subnet1"]
 }
}

data "aws_subnet" "public-subnet2" {
 vpc_id = data.aws_vpc.newvpc.id
 filter {
    name = "tag:Name"
    values = ["public-subnet2"]
 }
}
data "aws_security_group" "ec2_sg" {
  vpc_id = data.aws_vpc.newvpc.id
  filter {
    name = "tag:Name"
    values = ["ec2-sg"]
 }
}

 #Creating EKS Cluster
  resource "aws_eks_cluster" "eks" {
    name     = "project-eks"
    role_arn = aws_iam_role.eks_cluster_role.arn


    vpc_config {
      subnet_ids = [data.aws_subnet.public-subnet1.id, data.aws_subnet.public-subnet2.id]
    }

    tags = {
      "Name" = "MyEKS"
    }

    
  }
 resource "aws_eks_node_group" "node-grp" {
    cluster_name    = aws_eks_cluster.eks.name
    node_group_name = "project-node-group"
    node_role_arn   = aws_iam_role.eks_node_group_role.arn
    subnet_ids      = [data.aws_subnet.public-subnet1.id, data.aws_subnet.public-subnet2.id]
    capacity_type   = "ON_DEMAND"
    disk_size       = 20
    instance_types  = ["t2.small"]

   

    labels = {
      env = "dev"
    }

    scaling_config {
      desired_size = 2
      max_size     = 4
      min_size     = 1
    }

    update_config {
      max_unavailable = 1
    }

    
  }
