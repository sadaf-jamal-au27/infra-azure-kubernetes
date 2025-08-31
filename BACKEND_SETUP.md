# Terraform Backend Configuration

## Overview

This document explains how to configure and manage Terraform remote state backends for different environments.

## Current Setup

Currently, all environments are configured to use **local state** for the CI/CD pipeline to avoid backend initialization issues. The remote backend configurations are commented out in the provider.tf files.

## Backend Storage Architecture

```
├── Dev Environment
│   ├── Resource Group: rg-tfstate-dev
│   ├── Storage Account: satfstatedev001
│   └── Container: tfstate
│       └── State File: dev.terraform.tfstate
│
├── Staging Environment
│   ├── Resource Group: rg-tfstate-staging
│   ├── Storage Account: satfstatestaging001
│   └── Container: tfstate
│       └── State File: staging.terraform.tfstate
│
└── Production Environment
    ├── Resource Group: rg-tfstate-prod
    ├── Storage Account: satfstateprod001
    └── Container: tfstate
        └── State File: prod.terraform.tfstate
```

## Setting Up Remote Backend (Optional)

### Step 1: Bootstrap Backend Storage

Run the bootstrap script to create the necessary Azure Storage Account for state management:

```bash
# For dev environment
./scripts/bootstrap-backend.sh dev

# For staging environment
./scripts/bootstrap-backend.sh staging

# For production environment
./scripts/bootstrap-backend.sh prod
```

### Step 2: Enable Backend Configuration

After bootstrapping, uncomment the backend configuration in the respective environment's `provider.tf`:

**For Dev Environment** (`environments/dev/provider.tf`):
```hcl
terraform {
  # ... other configuration ...
  
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-dev"
    storage_account_name = "satfstatedev001"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}
```

**For Staging Environment** (`environments/staging/provider.tf`):
```hcl
terraform {
  # ... other configuration ...
  
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-staging"
    storage_account_name = "satfstatestaging001"
    container_name       = "tfstate"
    key                  = "staging.terraform.tfstate"
  }
}
```

**For Production Environment** (`environments/prod/provider.tf`):
```hcl
terraform {
  # ... other configuration ...
  
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-prod"
    storage_account_name = "satfstateprod001"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```

### Step 3: Initialize with Remote Backend

After enabling the backend configuration, run:

```bash
cd environments/{environment}
terraform init
```

Terraform will detect the backend change and prompt to migrate existing state to the remote backend.

### Step 4: Update CI/CD Pipeline

Once remote backends are configured, update the GitHub Actions workflow to remove the `-backend=false` flag from terraform init commands.

## Security Considerations

1. **Storage Account Access**: The backend storage accounts should have restricted access
2. **State File Encryption**: State files contain sensitive information and are encrypted at rest
3. **Access Control**: Use Azure RBAC to control who can access state files
4. **Backup**: State files should be backed up regularly

## Troubleshooting

### Backend Not Found Error

If you see an error like "Resource group 'rg-tfstate-{env}' could not be found", run the bootstrap script:

```bash
./scripts/bootstrap-backend.sh {environment}
```

### State Lock Issues

If state is locked, you can force unlock (use with caution):

```bash
terraform force-unlock {lock-id}
```

### Migrating from Local to Remote

When migrating from local to remote backend:

1. Ensure local state is up to date
2. Run `terraform init` after enabling backend config
3. Terraform will prompt to copy local state to remote
4. Verify state migration was successful
5. Delete local state files (terraform.tfstate*)

## Current CI/CD Behavior

The CI/CD pipeline currently:
- Uses local state (`-backend=false`)
- Does not persist state between runs
- Suitable for validation and planning
- **NOT suitable for actual infrastructure deployment**

For production use, you should:
1. Set up remote backends using the bootstrap script
2. Update the workflow to use remote state
3. Ensure proper access controls are in place

## Best Practices

1. **Separate backends per environment** - Never share state files between environments
2. **Backup state files** - State files are critical, ensure they're backed up
3. **Lock state during operations** - Prevents concurrent modifications
4. **Monitor access** - Keep track of who accesses state files
5. **Version control backend config** - Keep backend configurations in version control
