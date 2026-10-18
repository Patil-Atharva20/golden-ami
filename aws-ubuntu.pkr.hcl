variable "ami_name" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "region" {
  type = string
}

variable "ssh_username" {
  type = string
}

packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = var.ami_name
  instance_type = var.instance_type
  region        = var.region
  ssh_username  = var.ssh_username
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
}
build {
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "shell" {
    inline = [
      "echo Installing Updates",
      "for attempt in 1 2 3; do",
      "  echo \"APT update attempt $attempt of 3\"",
      "  sudo rm -rf /var/lib/apt/lists/*",
      "  sudo apt-get clean",
      "  if sudo apt-get -o Acquire::Retries=3 update; then break; fi",
      "  if [ \"$attempt\" -eq 3 ]; then exit 1; fi",
      "  sleep $((attempt * 5))",
      "done",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y nginx"
    ]
  }
  post-processor "manifest" {
    output = "manifest.json"
  }
}