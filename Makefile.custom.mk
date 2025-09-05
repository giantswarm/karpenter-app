build:
	@vendir sync
	@cp kustomization-crds.yaml vendor/karpenter-provider-aws-upstream/pkg/apis/crds/kustomization.yaml
	@kubectl kustomize vendor/karpenter-provider-aws-upstream/pkg/apis/crds > helm/karpenter/templates/crds.yaml

clean:
	@rm -rf ./vendor
	@rm helm/karpenter/templates/crds.yaml
