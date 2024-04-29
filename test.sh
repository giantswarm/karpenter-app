#!/bin/bash

# Get autoscaling group names with the specified cluster ID tag
autoscaling_groups=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[?Tags[?Key=='kubernetes.io/cluster/$CLUSTER_ID']].{AutoScalingGroupName: AutoScalingGroupName, NodeGroupName: Tags[?Key=='eks:nodegroup-name'].Value | [0]}" --output json)

# Iterate over each autoscaling group
for row in $(echo "${autoscaling_groups}" | jq -r '.[] | @base64'); do
    _jq() {
        echo "${row}" | base64 --decode | jq -r "$@"
    }

    asg_name=$(_jq '.AutoScalingGroupName')
    node_group_name=$(_jq '.NodeGroupName' | cut -d '_' -f 2-)

    # Get default launch template version for the autoscaling group
    launch_template_version=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name "$asg_name" --query "AutoScalingGroups[].MixedInstancesPolicy.LaunchTemplate.LaunchTemplateSpecification.LaunchTemplateId" --output text)

    # Get user data from the default launch template version
    user_data=$(aws ec2 describe-launch-template-versions --launch-template-id "$launch_template_version" --versions \$Latest --query "LaunchTemplateVersions[].LaunchTemplateData.UserData" --output text)
    user_data_decoded=$(echo "$user_data" | base64 -d)

    ami_id=$(aws ec2 describe-launch-template-versions --launch-template-id "$launch_template_version" --versions \$Latest --query "LaunchTemplateVersions[].LaunchTemplateData.ImageId" --output text)

    if kubectl get EC2NodeClass "$node_group_name"  >/dev/null 2>&1; then
        kubectl patch EC2NodeClass "$node_group_name" --type='json' -p='[{"op": "replace", "path": "/spec/amiSelectorTerms", "value": [{ id: "'"$ami_id"'" } ]}]'
        kubectl patch EC2NodeClass "$node_group_name" --type='json' -p='[{"op": "replace", "path": "/spec/userData", "value": "'"$user_data"'"}]'
    else
        echo "EC2NodeClass $node_group_name not found"
    fi
done