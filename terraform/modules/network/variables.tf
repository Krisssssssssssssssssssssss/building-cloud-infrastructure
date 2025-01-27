variable "region" {
  description = "AWS region"
  type        = string
  default     = "me-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
