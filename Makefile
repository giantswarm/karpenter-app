# DO NOT EDIT. Generated with:
#
#    devctl
#
#    https://github.com/giantswarm/devctl/blob/6a704f7e2a8b0f09e82b5bab88f17971af849711/pkg/gen/input/makefile/internal/file/Makefile.template
#

include Makefile.*.mk

##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z%\\\/_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

build:
	@vendir sync
	@cp kustomization-crds.yaml vendor/karpenter-provider-aws-upstream/pkg/apis/crds/kustomization.yaml
	@kubectl kustomize vendor/karpenter-provider-aws-upstream/pkg/apis/crds > helm/karpenter/templates/crds.yaml

clean:
	@rm -rf ./vendor
	@rm helm/karpenter/templates/crds.yaml
