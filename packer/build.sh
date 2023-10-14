#! /bin/bash

# delete old ami
# TODO(kevinwang) - make this image-id dynamic
aws ec2 deregister-image --image-id ami-009b7fa65d8d873d0

# build new ami
packer build packer/x86_84.pkr.hcl