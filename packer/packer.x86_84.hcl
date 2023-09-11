packer {
  required_plugins {
    amazon = {
      version = ">= 1.1.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# https://developer.hashicorp.com/packer/plugins/builders/amazon/ebs#tag-example
source "amazon-ebs" "basic" {
  ami_name      = "packer-x86_64"
  source_ami    = "ami-0aa7d40eeae50c9a9" # (64-bit (x86))
  instance_type = "t2.small"
  region        = "us-east-1"
  ssh_username  = "ec2-user"
}


build {
  name = "packer-arm-build"
  sources = [
    "source.amazon-ebs.basic"
  ]


  # install nixpacks
  provisioner "shell" {
    inline = [
      "curl -sSL https://nixpacks.com/install.sh | sudo bash",
      "nixpacks --version"
    ]
  }

  # install junk
  provisioner "shell" {
    inline = [
      "sudo yum -y install zsh",
      "sudo yum -y install git",
    ]
  }

  # Install nomad 
  provisioner "shell" {
    inline = [
      "sudo yum -y install yum-utils",
      "sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo",
      "sudo yum -y install nomad",
      "sudo systemctl enable nomad",
      "sudo systemctl start nomad"
    ]
  }

  # Use provisioner to install docker desktop
  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum -y install docker",
      "sudo usermod -a -G docker ec2-user",
      "id ec2-user",
      "newgrp docker",
      "sudo systemctl enable docker.service",
      "sudo systemctl start docker.service",
    ]
  }
}
