# Red Hat Connectivity Link Overview

## Purpose
Red Hat Connectivity Link addresses the challenges of connecting applications across multi-cloud and multi-cluster environments, ensuring consistent, secure, and observable connectivity.

## Key Problems Solved
- Fragmented connectivity across clusters and clouds
- Inconsistent security policies (TLS, Auth, RateLimit)
- Lack of observability for cross-cluster traffic
- Complex DNS and traffic routing
- Operational burden on platform engineers

## Core Capabilities
| Capability | Description |
|------------|-------------|
| Multi-cluster ingress | Gateway API + Envoy-based traffic management across clusters |
| Centralized policy control | Unified TLS, Auth, RateLimit enforcement |
| Enhanced observability | Built-in metrics, tracing, logging, and alerting |
| DNS integration | Health checks and auto record updates with Route53, Azure DNS, etc. |
| OpenShift integration | Native support for Service Mesh and Web Console |

## Technical Foundation
- Built on Kuadrant (open source)
- Uses Envoy and Gateway API
- Extensible via WASM plugins

## Target Users
- Platform engineers
- DevOps teams
- Application developers in OpenShift or Kubernetes environments

## Benefits
- Simplified connectivity management
- Improved security posture
- Better traffic visibility and control
- Seamless multi-cloud application delivery

