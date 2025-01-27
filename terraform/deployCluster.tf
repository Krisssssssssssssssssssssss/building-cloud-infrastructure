# provider "aws" {
#   region = "me-south-1"
# }

# # Fetch Available AZs
# data "aws_availability_zones" "available" {
#   state = "available"
# }

# # Create a VPC
# resource "aws_vpc" "main" {
#   cidr_block           = "10.0.0.0/16"
#   enable_dns_support   = true
#   enable_dns_hostnames = true
#   tags = {
#     Name = "main-vpc"
#   }
# }

# # Public Subnets
# resource "aws_subnet" "public" {
#   count                   = 2
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
#   map_public_ip_on_launch = true
#   availability_zone       = data.aws_availability_zones.available.names[count.index]
#   tags = {
#     Name = "public-subnet-${count.index}"
#   }
# }

# # Private Subnets
# resource "aws_subnet" "private" {
#   count                   = 2
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 2)
#   availability_zone       = data.aws_availability_zones.available.names[count.index]
#   tags = {
#     Name = "private-subnet-${count.index}"
#   }
# }


# # Internet Gateway
# resource "aws_internet_gateway" "main" {
#   vpc_id = aws_vpc.main.id
#   tags = {
#     Name = "main-internet-gateway"
#   }
# }

# # Route Table for Public Subnets
# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.main.id
#   }

#   tags = {
#     Name = "public-route-table"
#   }
# }

# # Associate Public Subnets with Public Route Table
# resource "aws_route_table_association" "public" {
#   count          = 2
#   subnet_id      = aws_subnet.public[count.index].id
#   route_table_id = aws_route_table.public.id
# }

# # NAT Gateway
# resource "aws_nat_gateway" "main" {
#   allocation_id = aws_eip.main.id
#   subnet_id     = aws_subnet.public[0].id
#   tags = {
#     Name = "main-nat-gateway"
#   }
# }

# # Elastic IP for NAT Gateway
# resource "aws_eip" "main" {
#   domain = "vpc"
#   tags = {
#     Name = "main-eip"
#   }
# }

# # Route Table for Private Subnets
# resource "aws_route_table" "private" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.main.id
#   }

#   tags = {
#     Name = "private-route-table"
#   }
# }

# # Associate Private Subnets with Private Route Table
# resource "aws_route_table_association" "private" {
#   count          = 2
#   subnet_id      = aws_subnet.private[count.index].id
#   route_table_id = aws_route_table.private.id
# }

# # Security Group for Frontend
# resource "aws_security_group" "frontend" {
#   vpc_id = aws_vpc.main.id

#   ingress {
#     from_port   = 3000
#     to_port     = 3000
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "frontend-sg"
#   }
# }

# # Security Group for EKS Nodes
# resource "aws_security_group" "eks_nodes" {
#   vpc_id = aws_vpc.main.id

#   # Allow traffic from the control plane
#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = [aws_vpc.main.cidr_block]
#   }

#   # Allow communication between nodes
#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = [aws_vpc.main.cidr_block]
#   }

#   # Allow egress to the internet
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "eks-nodes-sg"
#   }
# }

# # Security Group for Backend
# resource "aws_security_group" "backend" {
#   vpc_id = aws_vpc.main.id

#   # Allow traffic from EKS Nodes
#   ingress {
#     from_port   = 8706
#     to_port     = 8706
#     protocol    = "tcp"
#     security_groups = [aws_security_group.eks_nodes.id]
#   }

#   # Allow traffic to MongoDB and Redis
#   ingress {
#     from_port   = 27017
#     to_port     = 27017
#     protocol    = "tcp"
#     cidr_blocks = [aws_vpc.main.cidr_block]
#   }

#   ingress {
#     from_port   = 6379
#     to_port     = 6379
#     protocol    = "tcp"
#     cidr_blocks = [aws_vpc.main.cidr_block]
#   }

#   tags = {
#     Name = "backend-sg"
#   }
# }


# # EKS Cluster
# module "eks_cluster" {
#   source          = "terraform-aws-modules/eks/aws"
#   version         = "20.33.1"
#   cluster_name    = "kristijan-production"
#   cluster_version = "1.27"

#   subnet_ids      = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
# }



# # Managed Node Group
# module "eks_node_group" {
#   source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
#   version = "20.33.1"

#   cluster_name    = module.eks_cluster.cluster_name
#   instance_types  = ["t3.medium"]
#   subnet_ids      = aws_subnet.private[*].id
#   min_size        = 1
#   max_size        = 4
# }

# # CI/CD and Monitoring: Outputs for Use in GitHub Actions or Jenkins
# output "eks_cluster_endpoint" {
#   description = "EKS Cluster endpoint for CI/CD integration"
#   value       = module.eks_cluster.cluster_endpoint
# }

# # Fetch the EKS cluster details
# data "aws_eks_cluster" "cluster" {
#   name = module.eks_cluster.cluster_name
# }

# # Fetch the EKS cluster authentication details
# data "aws_eks_cluster_auth" "cluster" {
#   name = module.eks_cluster.cluster_name
# }

# # Output for kubeconfig
# output "eks_cluster_kubeconfig" {
#   description = "Kubeconfig file for CI/CD integration"
#   value = jsonencode({
#     apiVersion = "v1"
#     clusters = [
#       {
#         cluster = {
#           server                   = data.aws_eks_cluster.cluster.endpoint
#           certificate-authority-data = data.aws_eks_cluster.cluster.certificate_authority[0].data
#         }
#         name = data.aws_eks_cluster.cluster.name
#       }
#     ]
#     contexts = [
#       {
#         context = {
#           cluster = data.aws_eks_cluster.cluster.name
#           user    = data.aws_eks_cluster.cluster.name
#         }
#         name = data.aws_eks_cluster.cluster.name
#       }
#     ]
#     current-context = data.aws_eks_cluster.cluster.name
#     kind            = "Config"
#     users = [
#       {
#         name = data.aws_eks_cluster.cluster.name
#         user = {
#           token = data.aws_eks_cluster_auth.cluster.token
#         }
#       }
#     ]
#   })
# }
