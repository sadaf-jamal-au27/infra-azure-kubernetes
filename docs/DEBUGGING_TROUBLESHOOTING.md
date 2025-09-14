# 🚀 Azure Infrastructure Debugging & Troubleshooting Guide

## 📋 Table of Contents
- [Overview](#overview)
- [CI/CD Pipeline Debugging](#cicd-pipeline-debugging)
- [Terraform Debugging](#terraform-debugging)
- [Azure Resource Debugging](#azure-resource-debugging)
- [Security & Compliance Issues](#security--compliance-issues)
- [Performance Optimization](#performance-optimization)
- [Common Error Scenarios](#common-error-scenarios)
- [Monitoring & Logging](#monitoring--logging)
- [Recovery Procedures](#recovery-procedures)

## 🎯 Overview

This guide provides comprehensive debugging and troubleshooting strategies for the Azure infrastructure deployment pipeline. It covers everything from CI/CD pipeline issues to Azure resource problems and security compliance violations.

## 🔧 CI/CD Pipeline Debugging

### Pipeline Job Status Monitoring

#### 1. Infrastructure Validation & Security Compliance
```bash
# Check validation job logs
gh run view --log-file validation.log

# Common validation issues:
- Terraform format errors
- Security policy violations (Checkov)
- Azure authentication failures
- Resource quota exceeded
```

#### 2. Infrastructure Planning & Resource Analysis
```bash
# Check planning job logs
gh run view --log-file planning.log

# Common planning issues:
- Resource conflicts
- Insufficient permissions
- Invalid resource configurations
- Dependency resolution failures
```

#### 3. Infrastructure Deployment & Provisioning
```bash
# Check deployment job logs
gh run view --log-file deployment.log

# Common deployment issues:
- Resource creation timeouts
- Network connectivity problems
- Storage account conflicts
- AKS cluster provisioning failures
```

#### 4. Infrastructure Cleanup & Resource Optimization
```bash
# Check cleanup job logs
gh run view --log-file cleanup.log

# Common cleanup issues:
- Resource deletion failures
- Dependency conflicts
- Permission issues
- Orphaned resources
```

### Runner Label Verification

#### Current Runner Configuration
```yaml
# All jobs currently use ubuntu-latest
validation:
  runs-on: ubuntu-latest  # ✅ Correct for container actions

plan:
  runs-on: ubuntu-latest  # ✅ Correct for Terraform operations

deploy-development:
  runs-on: ubuntu-latest  # ✅ Correct for Azure CLI operations

cleanup:
  runs-on: ubuntu-latest  # ✅ Correct for cleanup operations
```

#### Runner Requirements Analysis
- **Container Actions**: Require Linux runners (ubuntu-latest ✅)
- **Terraform Operations**: Work on any runner (ubuntu-latest ✅)
- **Azure CLI**: Cross-platform support (ubuntu-latest ✅)
- **Security Scans**: Checkov requires Linux (ubuntu-latest ✅)

## 🏗️ Terraform Debugging

### Debugging Commands

#### 1. Format Validation
```bash
# Check formatting issues
terraform fmt -check -recursive

# Fix formatting issues
terraform fmt -recursive

# Verify formatting
terraform fmt -check -recursive
```

#### 2. Configuration Validation
```bash
# Initialize Terraform
cd lib/environments/dev
terraform init -backend=false

# Validate configuration
terraform validate

# Check for syntax errors
terraform validate -json | jq '.diagnostics'
```

#### 3. Planning Debugging
```bash
# Generate detailed plan
terraform plan -out=tfplan -detailed-exitcode

# Plan with debug logging
TF_LOG=DEBUG terraform plan

# Plan with specific variables
TF_VAR_environment=dev TF_VAR_sql_admin_password="P@ssw0rd@789" terraform plan
```

#### 4. State Management
```bash
# Check current state
terraform show

# List all resources
terraform state list

# Check specific resource
terraform state show module.aks.azurerm_kubernetes_cluster.aks

# Import existing resources
terraform import module.rg.azurerm_resource_group.rg /subscriptions/{subscription-id}/resourceGroups/{rg-name}
```

### Common Terraform Issues

#### 1. Resource Conflicts
```bash
# Error: Resource already exists
# Solution: Import existing resource or use different name
terraform import azurerm_resource_group.rg /subscriptions/{id}/resourceGroups/{name}

# Error: Name already taken
# Solution: Use unique suffixes or random IDs
resource "random_id" "unique" {
  byte_length = 4
}
```

#### 2. Dependency Issues
```bash
# Error: Circular dependency
# Solution: Use explicit depends_on
resource "azurerm_sql_database" "db" {
  depends_on = [azurerm_mssql_server.server]
}

# Error: Missing dependency
# Solution: Add implicit or explicit dependencies
module "sql_db" {
  depends_on = [module.sql_server]
}
```

#### 3. Variable Issues
```bash
# Error: Undefined variable
# Solution: Define in variables.tf or terraform.tfvars
variable "sql_admin_password" {
  description = "SQL Server administrator password"
  type        = string
  sensitive   = true
}

# Error: Invalid variable type
# Solution: Check variable type definition
variable "max_size_gb" {
  type = string  # Not number for some Azure resources
}
```

## ☁️ Azure Resource Debugging

### Resource Group Issues

#### 1. Resource Group Not Found
```bash
# Check if resource group exists
az group show --name "rg-dev-todoapp-{suffix}" --output table

# Create resource group if missing
az group create --name "rg-dev-todoapp-{suffix}" --location "eastus"
```

#### 2. Permission Issues
```bash
# Check current permissions
az role assignment list --assignee $(az account show --query user.name -o tsv)

# Check subscription permissions
az account show --query "id" -o tsv
```

### AKS Cluster Issues

#### 1. Cluster Creation Failures
```bash
# Check AKS service status
az aks list --output table

# Check node pool status
az aks nodepool list --cluster-name "aks-dev-{suffix}" --resource-group "rg-dev-todoapp-{suffix}"

# Check cluster diagnostics
az aks diagnostics --name "aks-dev-{suffix}" --resource-group "rg-dev-todoapp-{suffix}"
```

#### 2. Node Issues
```bash
# Check node status
kubectl get nodes

# Check node events
kubectl describe node <node-name>

# Check pod status
kubectl get pods --all-namespaces
```

### SQL Server Issues

#### 1. Connection Problems
```bash
# Test SQL Server connectivity
sqlcmd -S "sql-dev-{suffix}.database.windows.net" -U "devopsadmin" -P "P@ssw0rd@789"

# Check firewall rules
az sql server firewall-rule list --server "sql-dev-{suffix}" --resource-group "rg-dev-todoapp-{suffix}"
```

#### 2. Database Issues
```bash
# Check database status
az sql db show --name "sqldb-dev-todoapp" --server "sql-dev-{suffix}" --resource-group "rg-dev-todoapp-{suffix}"

# Check database metrics
az monitor metrics list --resource "/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Sql/servers/{server}/databases/{db}"
```

### Storage Account Issues

#### 1. Access Issues
```bash
# Check storage account status
az storage account show --name "sadev{suffix}" --resource-group "rg-dev-todoapp-{suffix}"

# Check access keys
az storage account keys list --account-name "sadev{suffix}" --resource-group "rg-dev-todoapp-{suffix}"
```

#### 2. Container Issues
```bash
# List containers
az storage container list --account-name "sadev{suffix}" --account-key "{key}"

# Check container permissions
az storage container show --name "container-name" --account-name "sadev{suffix}" --account-key "{key}"
```

## 🔒 Security & Compliance Issues

### Checkov Security Scan Issues

#### 1. Policy Violations
```bash
# Run Checkov locally
checkov -d . --framework terraform

# Run with specific policies
checkov -d . --framework terraform --check CKV_AZURE_168

# Generate detailed report
checkov -d . --framework terraform --output cli --output-file-path checkov-report.txt
```

#### 2. Common Policy Violations

##### CKV_AZURE_168: AKS Max Pods
```hcl
# ❌ Violation
max_pods = 30

# ✅ Fix
max_pods = 50  # Minimum required
```

##### CKV_AZURE_229: SQL Zone Redundancy
```hcl
# ❌ Violation
zone_redundant = false

# ✅ Fix
zone_redundant = true
```

##### CKV_AZURE_206: Storage Replication
```hcl
# ❌ Violation
account_replication_type = "LRS"

# ✅ Fix
account_replication_type = "GRS"
```

##### CKV2_AZURE_27: Azure AD Authentication
```hcl
# ❌ Violation (missing azuread_administrator)
resource "azurerm_mssql_server" "server" {
  # ... other config
}

# ✅ Fix
resource "azurerm_mssql_server" "server" {
  azuread_administrator {
    login_username = "azuread-admin"
    object_id      = data.azurerm_client_config.current.object_id
  }
}
```

### Key Vault Issues

#### 1. Access Policy Issues
```bash
# Check Key Vault access policies
az keyvault show --name "kv-dev-{suffix}" --resource-group "rg-dev-todoapp-{suffix}"

# List access policies
az keyvault list-policies --name "kv-dev-{suffix}" --resource-group "rg-dev-todoapp-{suffix}"
```

#### 2. Secret Management
```bash
# List secrets
az keyvault secret list --vault-name "kv-dev-{suffix}"

# Get secret value
az keyvault secret show --vault-name "kv-dev-{suffix}" --name "secret-name"
```

## ⚡ Performance Optimization

### Resource Optimization

#### 1. AKS Optimization
```bash
# Check cluster metrics
az monitor metrics list --resource "/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.ContainerService/managedClusters/{cluster}"

# Optimize node pool
az aks nodepool update --cluster-name "aks-dev-{suffix}" --name "default" --resource-group "rg-dev-todoapp-{suffix}" --max-pods 50
```

#### 2. SQL Database Optimization
```bash
# Check database performance
az sql db show --name "sqldb-dev-todoapp" --server "sql-dev-{suffix}" --resource-group "rg-dev-todoapp-{suffix}"

# Monitor query performance
az monitor metrics list --resource "/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Sql/servers/{server}/databases/{db}"
```

### Cost Optimization

#### 1. Resource Sizing
```bash
# Check resource costs
az consumption usage list --start-date "2024-01-01" --end-date "2024-01-31"

# Optimize VM sizes
az vm list-skus --location "eastus" --output table | grep "Standard_B2pls_v2"
```

#### 2. Storage Optimization
```bash
# Check storage usage
az storage account show --name "sadev{suffix}" --resource-group "rg-dev-todoapp-{suffix}" --query "usage"

# Optimize storage tier
az storage account update --name "sadev{suffix}" --resource-group "rg-dev-todoapp-{suffix}" --access-tier Cool
```

## 🚨 Common Error Scenarios

### 1. Free Subscription Limitations

#### Error: VM Size Not Available
```bash
# Error: Standard_B2s not available
# Solution: Use available VM sizes
az vm list-skus --location "eastus" --output table | grep -v "NotAvailableForSubscription"
```

#### Error: Quota Exceeded
```bash
# Check current quotas
az vm list-usage --location "eastus" --output table

# Request quota increase
az support tickets create --ticket-name "Quota Increase" --description "Request for increased VM quota"
```

### 2. Network Issues

#### Error: DNS Resolution
```bash
# Check DNS resolution
nslookup "aks-dev-{suffix}.eastus.azmk8s.io"

# Check network connectivity
ping "aks-dev-{suffix}.eastus.azmk8s.io"
```

#### Error: Firewall Rules
```bash
# Check firewall rules
az sql server firewall-rule list --server "sql-dev-{suffix}" --resource-group "rg-dev-todoapp-{suffix}"

# Add firewall rule
az sql server firewall-rule create --server "sql-dev-{suffix}" --resource-group "rg-dev-todoapp-{suffix}" --name "AllowAzureServices" --start-ip-address "0.0.0.0" --end-ip-address "0.0.0.0"
```

### 3. Authentication Issues

#### Error: Service Principal Issues
```bash
# Check service principal
az ad sp show --id "{client-id}"

# Check role assignments
az role assignment list --assignee "{client-id}"
```

#### Error: Azure CLI Authentication
```bash
# Login to Azure
az login

# Check current account
az account show

# Switch subscription
az account set --subscription "{subscription-id}"
```

## 📊 Monitoring & Logging

### Azure Monitor

#### 1. Resource Monitoring
```bash
# Enable monitoring for AKS
az monitor diagnostic-settings create --name "aks-monitoring" --resource "/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.ContainerService/managedClusters/{cluster}" --workspace "/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.OperationalInsights/workspaces/{workspace}"

# Check metrics
az monitor metrics list --resource "/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.ContainerService/managedClusters/{cluster}"
```

#### 2. Log Analytics
```bash
# Query logs
az monitor log-analytics query --workspace "{workspace-id}" --analytics-query "AzureActivity | where ResourceGroup == 'rg-dev-todoapp-{suffix}'"
```

### Application Insights

#### 1. Setup Application Insights
```bash
# Create Application Insights
az monitor app-insights component create --app "todoapp-insights" --location "eastus" --resource-group "rg-dev-todoapp-{suffix}"
```

#### 2. Monitor Application Performance
```bash
# Check application metrics
az monitor app-insights component show --app "todoapp-insights" --resource-group "rg-dev-todoapp-{suffix}"
```

## 🔄 Recovery Procedures

### 1. Infrastructure Recovery

#### Complete Infrastructure Rebuild
```bash
# Destroy existing infrastructure
cd lib/environments/dev
terraform destroy -auto-approve

# Rebuild infrastructure
terraform apply -auto-approve
```

#### Partial Resource Recovery
```bash
# Remove specific resource from state
terraform state rm module.aks.azurerm_kubernetes_cluster.aks

# Recreate resource
terraform apply -target=module.aks.azurerm_kubernetes_cluster.aks
```

### 2. Data Recovery

#### SQL Database Recovery
```bash
# Restore from backup
az sql db restore --dest-name "sqldb-dev-todoapp-restored" --name "sqldb-dev-todoapp" --server "sql-dev-{suffix}" --resource-group "rg-dev-todoapp-{suffix}" --restore-point-in-time "2024-01-01T00:00:00Z"
```

#### Storage Account Recovery
```bash
# Restore deleted storage account
az storage account restore --name "sadev{suffix}" --resource-group "rg-dev-todoapp-{suffix}"
```

### 3. Pipeline Recovery

#### Manual Pipeline Execution
```bash
# Trigger pipeline manually
gh workflow run "cicd.yaml" --ref main

# Check pipeline status
gh run list --workflow="cicd.yaml"
```

#### Rollback Deployment
```bash
# Revert to previous commit
git revert HEAD

# Push rollback
git push origin main
```

## 🛠️ Debugging Tools

### 1. Azure CLI Extensions
```bash
# Install useful extensions
az extension add --name aks-preview
az extension add --name storage-preview
az extension add --name sql
```

### 2. Terraform Debugging
```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Run terraform with debug
terraform plan
```

### 3. Kubernetes Debugging
```bash
# Install kubectl
az aks install-cli

# Get cluster credentials
az aks get-credentials --resource-group "rg-dev-todoapp-{suffix}" --name "aks-dev-{suffix}"

# Debug cluster issues
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 📞 Support & Escalation

### 1. Internal Support
- **DevOps Team**: devops@todoapp.com
- **Infrastructure Team**: infra@todoapp.com
- **Security Team**: security@todoapp.com

### 2. External Support
- **Azure Support**: https://azure.microsoft.com/support/
- **Terraform Support**: https://www.terraform.io/docs/cloud/support/
- **GitHub Actions Support**: https://docs.github.com/en/actions

### 3. Emergency Procedures
- **Critical Issues**: Contact on-call engineer
- **Security Incidents**: Follow security incident response plan
- **Data Loss**: Initiate data recovery procedures immediately

---

## 📝 Quick Reference

### Common Commands
```bash
# Check pipeline status
gh run list --workflow="cicd.yaml"

# View pipeline logs
gh run view --log-file pipeline.log

# Check Azure resources
az resource list --resource-group "rg-dev-todoapp-{suffix}"

# Validate Terraform
terraform validate

# Check security compliance
checkov -d . --framework terraform
```

### Emergency Contacts
- **On-Call Engineer**: +1-XXX-XXX-XXXX
- **Security Team**: security@todoapp.com
- **Azure Support**: https://azure.microsoft.com/support/

---

*Last Updated: $(date)*
*Version: 1.0*
*Maintained by: DevOps Team*
