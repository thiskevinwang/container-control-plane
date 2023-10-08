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
  ami_name      = "nomad-x86_64"
  source_ami    = "ami-03a6eaae9938c858c" # Amazon Linux 2023 AMI 2023.2.20230920.1 x86_64 HVM kernel-6.1
  instance_type = "t2.medium"
  region        = "us-east-1"
  ssh_username  = "ec2-user"
}


build {
  name = "packer-build"
  sources = [
    "source.amazon-ebs.basic"
  ]

  # install junk
  provisioner "shell" {
    inline = [
      "sudo yum -y install zsh",
      "sudo yum -y install git",
      "sudo yum -y install util-linux-user",
      "sudo chsh -s $(which zsh) $(whoami)",
      # "sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting",
      # "sudo git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions",
      # "sudo touch ~/.zshrc",
      # "echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' >> ~/.zshrc",
    ]
  }



  # multiline script in packer - https://stackoverflow.com/a/68216479
  # sudo cat not working - https://stackoverflow.com/a/18836896
  provisioner "shell" {
    inline = [
      "sudo mkdir -p /etc/nomad.d/",
      <<EOT
sudo bash -c 'cat <<EOF > /etc/nomad.d/conf.hcl
bind_addr = "0.0.0.0" 
data_dir  = "/opt/nomad"
plugin_dir = "/opt/nomad/plugins"

acl {
  enabled = true
}

client {
  enabled = true
}

server {
  enabled          = true
  bootstrap_expect = 1
}
EOF'
EOT
    ]
  }

  # Install nomad & run it
  provisioner "shell" {
    inline = [
      "sudo yum -y install yum-utils",
      "sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo",
      "sudo yum -y install nomad",
      "sudo systemctl enable nomad.service",
      "sudo systemctl start nomad.service"
    ]
  }

  # Install docker & run it; This will be a driver that nomad will use
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
