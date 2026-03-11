# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Add `io.giantswarm.application.audience: all` annotation to publish the app to the customer Backstage catalog.
- Migrate chart metadata annotations to `io.giantswarm.application.*` format for both the karpenter and karpenter-bundle charts.

## [2.2.0] - 2026-03-09

### Changed

- Update ABS config to replace `.appVersion` in Chart.yaml with version detected by ABS.

### Fixed

- Use `.Chart.AppVersion` instead of `.Chart.Version` for OCIRepository tag.

## [2.1.0] - 2026-03-01

### Added

- Add `PodLogs` and `PodMonitor` custom resources for observability data ingestion.
- Deployment: Add HTTP proxy support.

## [2.0.0] - 2026-01-28

### Added

- Add e2e tests for this app.
- Add `karpenter-bundle` chart that consolidates `karpenter-app` and `karpenter-crossplane-resources` into a single deployable bundle.

[Unreleased]: https://github.com/giantswarm/karpenter-app/compare/v2.2.0...HEAD
[2.2.0]: https://github.com/giantswarm/karpenter-app/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/giantswarm/karpenter-app/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/giantswarm/karpenter-app/compare/v1.4.0...v2.0.0
