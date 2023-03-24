# Karpenter

Upstream docs https://karpenter.sh/
Chart for Karpenter https://github.com/aws/karpenter
CRD source https://github.com/aws/karpenter/tree/main/pkg/apis/crds

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

### Create Provisioner

```
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: spot-provisioner
spec:
  # # If omitted, the feature is disabled and nodes will never expire.  If set to less time than it requires for a node
  # # to become ready, the node may expire before any pods successfully start.
  ttlSecondsUntilExpired: 86400 # 1 Days = 60 * 60 * 24 Seconds;

  # # If omitted, the feature is disabled, nodes will never scale down due to low utilization
  ttlSecondsAfterEmpty: 30

  # # Provisioned nodes will have these taints
  # # Taints may prevent pods from scheduling if they are not tolerated by the pod.
  # taints:
  #   - key: spotInstances
  #     value: "true"
  #     effect: "PreferNoSchedule"

  # Labels are arbitrary key-values that are applied to all nodes
  labels:
    managed-by: karpenter
    nodepool: <NODEPOOL_ID>
    cluster: <CLUSTER_ID>

  # Requirements that constrain the parameters of provisioned nodes.
  # These requirements are combined with pod.spec.affinity.nodeAffinity rules.
  # Operators { In, NotIn } are supported to enable including or excluding values
  requirements:
    - key: "karpenter.k8s.aws/instance-family"
      operator: NotIn
      values: ["t3", "t3a", "t2"]
    - key: "karpenter.k8s.aws/instance-size"
      operator: NotIn
      values: ["large", "xlarge"]
    - key: "karpenter.k8s.aws/instance-hypervisor"
      operator: In
      values: ["nitro"]
    - key: "topology.kubernetes.io/zone"
      operator: In
      values: ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
    - key: "kubernetes.io/arch"
      operator: In
      values: ["amd64"]
    - key: "karpenter.sh/capacity-type" # If not included, the webhook for the AWS cloud provider will default to on-demand
      operator: In
      values: ["spot"]


  # Resource limits constrain the total size of the cluster.
  # Limits prevent Karpenter from creating new instances once the limit is exceeded.
  limits:
    resources:
      cpu: "1000"
      memory: 1000Gi

  # These fields vary per cloud provider, see your cloud provider specific documentation
  provider:
    subnetSelector:
      giantswarm.io/machine-deployment: <NODEPOOL_ID>
    launchTemplate: <CLUSTER_ID>-<NODEPOOL_ID>-LaunchTemplate
    tags:
      managed-by: karpenter
      nodepool: <NODEPOOL_ID>
      cluster: <CLUSTER_ID>
      Name: <CLUSTER_ID>-karpenter-spot-worker
```