# Karpenter

Chart for Karpenter https://github.com/aws/karpenter


# AWS Role

Create a new Role named <cluster-id>-Karpenter-Role
### Role

Attach the following policy to the role:
```
{
    "Statement": [
        {
            "Action": [
                "ssm:GetParameter",
                "ec2:DescribeImages",
                "ec2:RunInstances",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeLaunchTemplates",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceTypes",
                "ec2:DescribeInstanceTypeOfferings",
                "ec2:DescribeAvailabilityZones",
                "ec2:DeleteLaunchTemplate",
                "ec2:CreateTags",
                "ec2:CreateLaunchTemplate",
                "ec2:CreateFleet",
                "ec2:DescribeSpotPriceHistory",
                "pricing:GetProducts"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Sid": "Karpenter"
        },
        {
            "Action": "ec2:TerminateInstances",
            "Condition": {
                "StringLike": {
                    "ec2:ResourceTag/Name": "*karpenter*"
                }
            },
            "Effect": "Allow",
            "Resource": "*",
            "Sid": "ConditionalEC2Termination"
        }
    ],
    "Version": "2012-10-17"
}
```

### Trust Policy
```
    {
        "Effect": "Allow",
        "Principal": {
            "Federated": "arn:aws:iam::111111111:oidc-provider/irsa.xxxx.baseDomain"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
            "StringEquals": {
                "irsa.xxxx.baseDomain:sub": "system:serviceaccount:kube-system:karpenter"
            }
        }
    }
```

### Create Nodepool

Create a nodepool via happa or using kubectl-gs that uses all AZs and has min/max nodes set to 0
```
kubectl gs template nodepool --provider aws --organization giantswarm --cluster-name c2km7 --description karpenter --release 19.0.0 --availability-zones eu-central-1a,eu-central-1b,eu-central-1c  --nodes-min 0 --nodes-max 0 --aws-instance-type m5.large
```
