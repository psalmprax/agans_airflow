#!/bin/bash
echo "$1"

template=$1
aws sts get-caller-identity

stack_name=$2
echo "${stack_name}"
aws cloudformation delete-stack --stack-name $stack_name
sleep 80s
region=$(aws configure get region)
echo "${region}"
region=${region:-eu-central-1}

bucket=aws-sam-cli-managed-default-samclisourcebucket-4lm377w4boj2
echo "${bucket}"

bucketexist=$(aws s3api head-bucket --bucket "${bucket}" 2>&1)
echo "${bucketexist}"

if echo "${bucketexist}" | grep 'Not Found';
then
  echo "Bucket does not exist"
elif echo "${bucketexist}" | grep 'Forbidden';
then
  echo "Bucket exists but not owned"
elif echo "${bucketexist}" | grep 'Bad Request';
then
  echo "Bucket name specified is less than 3 or greater than 63 characters"
else
  echo "Bucket Exist"
fi

sudo sam build -u -t $PWD/${template}
sudo sam deploy --s3-bucket $bucket --stack-name $stack_name --capabilities CAPABILITY_IAM --region $region --no-disable-rollback --no-confirm-changeset --no-fail-on-empty-changeset > /dev/null 2>&1
sleep 80s

#vpcpeering_id_1=$(aws ec2 describe-vpc-peering-connections --query 'VpcPeeringConnections[0:3:1].VpcPeeringConnectionId | [1]' --output text)
#vpcpeering_id_2=$(aws ec2 describe-vpc-peering-connections --query 'VpcPeeringConnections[0:3:1].VpcPeeringConnectionId | [2]' --output text)

pcx=$(aws ec2 describe-vpc-peering-connections --query 'VpcPeeringConnections[*].VpcPeeringConnectionId' --output text) &&
status=$(aws ec2 describe-vpc-peering-connections --query 'VpcPeeringConnections[*].Status.Code' --output text)
cot=0
px=0
for k in $status; do
	if echo "${k}" | grep "active"
	  then echo "${cot}"
	for l in $pcx; do
	if [ $px = $cot ]; then
	echo "DNS Resolution for $l is been Enabled Now"
	aws ec2 modify-vpc-peering-connection-options --vpc-peering-connection-id $l --requester-peering-connection-options '{"AllowDnsResolutionFromRemoteVpc":true}' --accepter-peering-connection-options '{"AllowDnsResolutionFromRemoteVpc":true}' --region $region
	fi
	px=$((px+1))
	done
	px=0
	fi
	cot=$((cot+1))
done