# 📚 Infrastructure Documentation

This directory contains comprehensive documentation for the Azure infrastructure deployment pipeline.

## 📖 Available Documentation

### 🚀 [Debugging & Troubleshooting Guide](./DEBUGGING_TROUBLESHOOTING.md)
Complete guide for debugging and troubleshooting infrastructure issues, including:
- CI/CD Pipeline debugging
- Terraform configuration issues
- Azure resource problems
- Security compliance violations
- Performance optimization
- Recovery procedures

## 🎯 Quick Start

1. **For Developers**: Start with the [Debugging Guide](./DEBUGGING_TROUBLESHOOTING.md) for common issues
2. **For DevOps**: Use the troubleshooting procedures for infrastructure problems
3. **For Security**: Check the compliance section for security policy violations

## 🔧 CI/CD Pipeline Overview

The infrastructure pipeline consists of 4 main jobs:

1. **Infrastructure Validation & Security Compliance** (`ubuntu-latest`)
   - Terraform format validation
   - Configuration validation
   - Security compliance scanning (Checkov)

2. **Infrastructure Planning & Resource Analysis** (`ubuntu-latest`)
   - Terraform planning
   - Resource analysis
   - Change impact assessment

3. **Infrastructure Deployment & Provisioning** (`ubuntu-latest`)
   - Resource provisioning
   - Health validation
   - Status notifications

4. **Infrastructure Cleanup & Resource Optimization** (`ubuntu-latest`)
   - Post-deployment cleanup
   - Resource optimization
   - Artifact archiving

## 🏃‍♂️ Runner Configuration

All jobs use `ubuntu-latest` runners, which is correct for:
- ✅ Container actions (Checkov security scan)
- ✅ Terraform operations
- ✅ Azure CLI operations
- ✅ Cross-platform compatibility

## 📞 Support

For issues not covered in the documentation:
- **DevOps Team**: devops@todoapp.com
- **Infrastructure Team**: infra@todoapp.com
- **Security Team**: security@todoapp.com

---

*Last Updated: $(date)*
*Version: 1.0*
