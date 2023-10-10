terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.19.0"
    }
  }
}

#############
# Variables #
#############
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Key name for SSH access - hardcoded for demonstration purposes"
  type        = string
  default     = "test"
}

variable "vpc_id" {
  description = "The VPC ID — hardcoded for demonstration purposes"
  type        = string
  default     = "vpc-139b3769" # default VPC
}

variable "ami" {
  description = "The AMI output from packer — hardcoded for demonstration purposes"
  type        = string
  default     = "ami-0d82e39faee57ab0e"
}

#############
# Providers #
#############
provider "aws" {
  region = var.region
}

##########
# Locals #
##########
locals {
  tags = {
    repo = "traefik-test"
  }
}

################
# Data sources #
################
data "aws_vpc" "default" {
  id = var.vpc_id
}

#############
# Resources #
#############

# Consider more restrictive security group rules
resource "aws_security_group" "allow_all" {
  description = "Allow all public traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "Allow all inbound public traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "Allow all outbound public traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = local.tags
}

# TODO(kevinwang): Side quest to understand EBS usage
# resource "aws_ebs_volume" "shared-storage" {
#   availability_zone = "us-east-1a"
#   size              = 10

#   tags = local.tags
# }

# TODO(kevinwang): Side quest to understand EBS usage
# resource "aws_volume_attachment" "ebs_att" {
#   device_name = "/dev/sdh"
#   volume_id   = aws_ebs_volume.shared-storage.id
#   instance_id = aws_instance.nomad-leader.id
# }

resource "aws_instance" "nomad-leader" {
  ami                    = var.ami
  instance_type          = "t2.large"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_all.id]

  tags = local.tags
}

###########
# Outputs #
###########





output "nomad_acl_bootstrap_reminder" {
  value       = <<EOT

################################################
# Reminder to bootstrap ACLs on initial launch #
################################################

export NOMAD_ADDR=http://${aws_instance.nomad-leader.public_ip}:4646

export NOMAD_TOKEN=$(nomad acl bootstrap -json | jq -r '.SecretID')

export NOMAD_VAR_token_for_traefik=$NOMAD_TOKEN


######################
# SSH Helper command #
######################

ssh -i ~/Downloads/test.pem ec2-user@${aws_instance.nomad-leader.public_dns}

EOT
  description = "convenience command to bootstrap ACLs"
}
