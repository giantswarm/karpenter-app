# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.0] - 2025-10-02

### Changed

- Updated karpenter to 1.7.1

## [1.2.0] - 2025-09-11

### Changed

- Move PSS to policy-exceptions namespace.
- Move to Default Catalog.

## [1.1.1] - 2025-09-05

### Changed

- Enable spot to spot consolidation.
- Enable node repair.
- Set resources.

## [1.1.0] - 2025-09-05

### Changed

- Updated Karpenter to `v1.6.3`.

## [1.0.0] - 2025-06-09

### Changed

- Updated Karpenter to `v1.5.0`.
- Update README.
- Migrate to use `abs` to build the chart.

### Removed

- Drop deprecated `flowcontrol.apiserver.k8s.io/v1beta2` version of FlowSchema and PriorityLevelConfiguration.

## [0.14.0] - 2024-11-28

### Changed

- Deploy the `ServiceMonitor` by default.

## [0.13.0] - 2024-08-26

### Changed

- Detect and use latest `flowcontrol` API version.
- Update PolicyExceptions to v2 and fallback to v2beta1.

## [0.12.1] - 2024-05-09

### Changed

- Set interruption queue
- Remove default values

## [0.12.0] - 2024-04-29

## [0.11.0] - 2024-04-17

### Changed

- Remove node-renewer, in CAPA we will rely on TTL or manual roll of the nodes.

## [0.10.1] - 2024-02-06

### Changed

- Change role name to crossplane managed.

## [0.10.0] - 2024-02-06

### Changed

- Use crossplane configmap to configure account and AWS resources.

## [0.9.3] - 2024-02-06

## [0.9.2] - 2024-02-05

## [0.9.1] - 2024-02-05

### Changed

- Image registry
- Update Architect orb

## [0.9.0] - 2024-01-16

### Changed

- Use `batch/v1` for Cronjob.

## [0.8.0] - 2023-10-31

### Added

- Add PSS exceptions.

#### Changed

- Add flowschema for API resilience.

## [0.7.0] - 2023-10-12

- Add node-renewer that will replace nodes during upgrades.

## [0.6.1] - 2023-08-30

## [0.6.0] - 2023-08-29

### Changed

- Fixed ARN for AWS China

## [0.5.0] - 2023-08-10

### Added

- `app.kubernetes.io/instance` and `app.kubernetes.io/name` labels

### Changed

- Upgrade to Karpenter 0.29.2
- Create ServiceMonitor by default

## [0.4.0] - 2023-08-04

### Changed

- Updated Karpenter to 0.28

## [0.3.0] - 2023-06-29

### Changed

- Completely moved to Helm chart dependency
- Reverted Karpenter to 0.27

## [0.2.0] - 2023-06-27

### Added

- Enable consolidation in the Provisioner
- Add `giantswarm.io/cluster` AWS tag for unified overview in AWS cost explorer

### Changed

- Updated Karpenter to v0.28.0

## [0.1.0] - 2023-06-08

### Added

- First release of Karpenter-app

[Unreleased]: https://github.com/giantswarm/karpenter-app/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/giantswarm/karpenter-app/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/giantswarm/karpenter-app/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/giantswarm/karpenter-app/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/giantswarm/karpenter-app/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/giantswarm/karpenter-app/compare/v0.14.0...v1.0.0
[0.14.0]: https://github.com/giantswarm/karpenter-app/compare/v0.13.0...v0.14.0
[0.13.0]: https://github.com/giantswarm/karpenter-app/compare/v0.12.1...v0.13.0
[0.12.1]: https://github.com/giantswarm/karpenter-app/compare/v0.12.0...v0.12.1
[0.12.0]: https://github.com/giantswarm/karpenter-app/compare/v0.11.0...v0.12.0
[0.11.0]: https://github.com/giantswarm/karpenter-app/compare/v0.10.1...v0.11.0
[0.10.1]: https://github.com/giantswarm/karpenter-app/compare/v0.10.0...v0.10.1
[0.10.0]: https://github.com/giantswarm/karpenter-app/compare/v0.9.3...v0.10.0
[0.9.3]: https://github.com/giantswarm/karpenter-app/compare/v0.9.2...v0.9.3
[0.9.2]: https://github.com/giantswarm/karpenter-app/compare/v0.9.1...v0.9.2
[0.9.1]: https://github.com/giantswarm/karpenter-app/compare/v0.9.0...v0.9.1
[0.9.0]: https://github.com/giantswarm/karpenter-app/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/giantswarm/karpenter-app/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/giantswarm/karpenter-app/compare/v0.6.1...v0.7.0
[0.6.1]: https://github.com/giantswarm/karpenter-app/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/giantswarm/karpenter-app/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/giantswarm/karpenter-app/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/giantswarm/karpenter-app/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/giantswarm/karpenter-app/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/giantswarm/karpenter-app/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/giantswarm/karpenter-app/compare/v0.0.0...v0.1.0
