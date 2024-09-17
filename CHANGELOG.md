# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.9.4] - 2024-09-17

### Changed

- Set the correct `app.kubernetes.io/instance` label to `karpenter-renewer`. This fixes the Karpenter `PodDisruptionBudget` pod selection.

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

[Unreleased]: https://github.com/giantswarm/karpenter-app/compare/v0.9.4...HEAD
[0.9.4]: https://github.com/giantswarm/karpenter-app/compare/v0.9.3...v0.9.4
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
