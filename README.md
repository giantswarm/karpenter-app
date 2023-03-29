# Karpenter

Upstream docs https://karpenter.sh/
Chart for Karpenter https://github.com/aws/karpenter
CRD source https://github.com/aws/karpenter/tree/main/pkg/apis/crds


# Create Nodepool

Create a nodepool via happa or using kubectl-gs that uses all AZs and has min/max nodes set to 0
```
kubectl gs template nodepool --provider aws --organization giantswarm --cluster-name <cluster-id> --description karpenter --release 19.0.0 --availability-zones eu-central-1a,eu-central-1b,eu-central-1c  --nodes-min 0 --nodes-max 0 --aws-instance-type m5.large
```

# AWS Role

### IAM Policy

Create a policy with the following name `<cluster-id>-Karpenter`:
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
        },
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "arn:aws:iam::<account-id>:role/gs-cluster-<cluster-id>-role-*",
            "Sid": "PassNodeIAMRole"
        }
    ],
    "Version": "2012-10-17"
}
```

### Role

Create a new Role named `<cluster-id>-Karpenter-Role`.

- Use the following `Custom Trust Policy`, you can see the IRSA domain under `IAM > Identity Providers`
```
{
	"Version": "2012-10-17",
	"Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::<account-id>:oidc-provider/<irsa-domain>"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "<irsa-domain>:sub": "system:serviceaccount:kube-system:karpenter"
                }
            }
        }
	]
}
```
- Select `EC2 usecase`
- Attach the previously created policy

# Create Provisioner

We will create a provisioner that will reuse the Launch Template and Subnets of the previously created Nodepool.

Replace `<CLUSTER_ID>` and `<NODEPOOL_ID>` in the following template to create the first provisioner. 

Apply this resource on the workload cluster:

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

  # Make sure pods are not scheduled until cilium is running
  startupTaints:
  - key: node.cilium.io/agent-not-ready
    value: "true"
    effect: NoExecute

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
