#! /bin/bash

# delete old ami
# TODO(kevinwang) - make this image-id dynamic
aws ec2 deregister-image --image-id ami-03f4a15e529cb7391

# build new ami
packer build packer/x86_84.pkr.hcl