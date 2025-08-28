---
title: "Cloud Native Security Best Practices"
speaker: "Jonathan Baruch"
conference: "KubeCon + CloudNativeCon 2024"
date: "2024-11-15"
status: "completed"
description: "Exploring security patterns and best practices for cloud native applications, including RBAC, network policies, and container security scanning."
abstract: |
  As organizations move to cloud native architectures, security becomes more complex but also more important. 
  This talk covers essential security practices for Kubernetes environments, including proper RBAC configuration, 
  network security policies, and automated security scanning in CI/CD pipelines.

resources:
  - type: "slides"
    title: "Security Best Practices Deck"
    url: "https://docs.google.com/presentation/d/e/2PACX-1vQtLbueXXLmtdrkOsEFqtDlhM-rzaoaEFacQ8fMrmn4w9qFptjZe0RlsaUcUjMwyg/pub?start=false&loop=false&delayms=3000"
  - type: "video"
    title: "Conference Recording"
    url: "https://www.youtube.com/watch?v=Yh_hs4mZTiY"
  - type: "code"
    title: "Security Policy Examples"
    url: "https://github.com/example/k8s-security-policies"
  - type: "link"
    title: "CNCF Security Whitepaper"
    url: "https://www.cncf.io/reports/cloud-native-security-whitepaper/"
---

# Cloud Native Security: A Comprehensive Approach

Security in cloud native environments requires a shift from traditional perimeter-based security to a more distributed, layered approach.

## Key Topics Covered

### 1. Container Security
- Base image scanning and selection
- Runtime security monitoring
- Secrets management best practices

### 2. Kubernetes Security
- RBAC configuration patterns
- Network policies implementation
- Pod security standards

### 3. CI/CD Security
- Pipeline security scanning
- Supply chain security
- Artifact signing and verification

## Takeaways

The most important aspect of cloud native security is implementing security as code - making security decisions explicit, version controlled, and automated throughout the development lifecycle.