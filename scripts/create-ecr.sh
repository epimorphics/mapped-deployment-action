#!/bin/bash
# Create ECR repostiory if it does not exist
# Required environment:
#   image
#   region
#   AWS_ACCESS_KEY_ID
#   AWS_SECRET_ACCESS_KEY

set -e

if ! aws ecr describe-repositories --region $region --repository-names $image > /dev/null 2>&1 ; then
    aws ecr create-repository --region $region --repository-name $image
    aws ecr set-repository-policy --region $region --repository-name $image --policy-text '{
    "Version": "2008-10-17",
    "Statement": [
        {
        "Sid": "Org-wide access",
        "Effect": "Allow",
        "Principal": "*",
        "Action": [
            "ecr:BatchCheckLayerAvailability",
            "ecr:BatchGetImage",
            "ecr:CompleteLayerUpload",
            "ecr:GetDownloadUrlForLayer",
            "ecr:InitiateLayerUpload",
            "ecr:PutImage",
            "ecr:UploadLayerPart",
            "ecr:ListImages"
        ],
        "Condition": {
            "StringEquals": {
            "aws:PrincipalOrgID": "o-fmu3vfgvz2"
            }
        }
        }
    ]
    }'
    aws ecr put-image-scanning-configuration --region $region --repository-name $image --image-scanning-configuration scanOnPush=true
fi
