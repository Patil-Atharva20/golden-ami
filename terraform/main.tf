terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "region" {
  description = "AWS region where the AMI is available."
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "ID of the Packer-built AMI to test (for example, ami-0123456789abcdef0)."
  type        = string

  validation {
    condition     = can(regex("^ami-[0-9a-fA-F]+$", var.ami_id))
    error_message = "ami_id must be a valid-looking AWS AMI ID such as ami-0123456789abcdef0."
  }
}

variable "instance_type" {
  description = "Small instance type compatible with your AMI architecture and account."
  type        = string
  default     = "t3.micro"
}

variable "instance_name" {
  description = "Name tag for the test instance."
  type        = string
  default     = "packer-ami-test"
}

provider "aws" {
  region = var.region
}

resource "aws_instance" "ami_test" {
  ami           = var.ami_id
  instance_type = var.instance_type

  # Use the account's default VPC and default security group. No inbound access is added.
  # This avoids assuming a particular VPC or opening SSH/HTTP to the internet.

  tags = {
    Name      = var.instance_name
    ManagedBy = "Terraform"
    Purpose   = "Packer AMI test"
  }
}

output "instance_id" {
  description = "ID of the test EC2 instance."
  value       = aws_instance.ami_test.id
}

output "instance_ami_id" {
  description = "AMI used by the test instance."
  value       = aws_instance.ami_test.ami
}

output "instance_private_ip" {
  description = "Private IP, if assigned."
  value       = aws_instance.ami_test.private_ip
}
