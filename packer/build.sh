#! /bin/bash

# delete old ami
# TODO(kevinwang) - make this image-id dynamic
aws ec2 deregister-image --image-id ami-05dc771b6a201cf29

# build new ami
packer build packer/x86_84.pkr.hcl