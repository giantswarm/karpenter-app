# Karpenter

This is the `karpenter` app for the GiantSwarm app platform.

The contents of this repository are mostly generated from the `karpenter` fork that we maintain at https://github.com/giantswarm/karpenter-provider-aws-upstream.
If you want to do changes to the app, please do so in that repository and then run `make build` to update the contents of this repository.

```bash
make build
```

> [!WARNING]  
> These files are not generated and need to be maintained manually:
> - `values.schema.json`
> - `values.yaml`
> - `Chart.yaml`
