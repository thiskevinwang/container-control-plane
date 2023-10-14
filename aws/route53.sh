#!/bin/sh

# retrieve the hosted zone id for a given domain name
hosted_zone_name="thekevinwang.com"

# note the trailing period in the `hzn` arg
hosted_zone_id=$(aws route53 list-hosted-zones \
  | jq --arg hzn "$hosted_zone_name." -r '.HostedZones[] | select(.Name == $hzn) | .Id' \
  | cut -d'/' -f3
)

# note file path is relative to the caller's cwd
aws route53 change-resource-record-sets \
 --hosted-zone-id $hosted_zone_id \
 --change-batch file://./aws/route53.json