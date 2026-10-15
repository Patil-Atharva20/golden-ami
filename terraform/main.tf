terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
}

variable "region" {
  description = "AWS region where the AMI is available."
  type        = string
  default     = "ap-south-1"
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

variable "ssh_public_key" {
  description = "Public SSH key corresponding to the private key kept on your local machine."
  type        = string

  validation {
    condition     = can(regex("^(ssh-ed25519|ssh-rsa) ", var.ssh_public_key))
    error_message = "ssh_public_key must be an OpenSSH Ed25519 or RSA public key."
  }
}

variable "ssh_allowed_cidr" {
  description = "Single trusted public IPv4 address allowed to connect over SSH."
  type        = string
  default     = "223.181.76.88/32"

  validation {
    condition     = can(cidrnetmask(var.ssh_allowed_cidr)) && can(regex("/32$", var.ssh_allowed_cidr))
    error_message = "ssh_allowed_cidr must be a single IPv4 address in /32 format."
  }
}

provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_key_pair" "local_ssh" {
  key_name   = "golden-ami-local-ssh"
  public_key = var.ssh_public_key
}

resource "aws_security_group" "ssh" {
  name        = "golden-ami-ssh"
  description = "Allow SSH only from the configured trusted IPv4 address."
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from trusted IPv4 address"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "golden-ami-ssh"
    ManagedBy = "Terraform"
  }
}

resource "aws_instance" "ami_test" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.local_ssh.key_name
  vpc_security_group_ids      = [aws_security_group.ssh.id]
  associate_public_ip_address = true

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

output "instance_public_ip" {
  description = "Public IP for SSH access from the configured trusted IPv4 address."
  value       = aws_instance.ami_test.public_ip
}
