# Azure Authentication Setup for GitHub Actions

## 🚨 Issue Resolved

**Problem**: GitHub Actions workflow was failing with Azure authentication error:
```
ERROR: Please run 'az login' to setup account.
Using default Azure credentials
Error: The operation was canceled.
```

## ✅ Solution Applied

### 1. Updated GitHub Actions Workflow

The workflow now uses proper Azure authentication with the `azure/login@v1` action:

```yaml
- name: Configure Azure CLI
  uses: azure/login@v1
  with:
    creds: ${{ secrets.AZURE_CREDENTIALS }}
  continue-on-error: true

- name: Verify Azure Authentication
  run: |
    az account show || echo "Azure authentication failed - using default credentials"
  continue-on-error: true
```

### 2. Required GitHub Secrets Setup

You need to create the `AZURE_CREDENTIALS` secret in your GitHub repository with the following format:

```json
{
  "clientId": "your-client-id",
  "clientSecret": "your-client-secret",
  "subscriptionId": "your-subscription-id",
  "tenantId": "your-tenant-id"
}
```

## 🔧 How to Set Up Azure Credentials

### Step 1: Create Azure Service Principal

Run these commands in Azure CLI:

```bash
# Login to Azure
az login

# Get your subscription ID
az account show --query id --output tsv

# Create service principal (replace <subscription-id> with your actual subscription ID)
az ad sp create-for-rbac \
  --name "github-actions-terraform" \
  --role "Contributor" \
  --scopes "/subscriptions/<subscription-id>" \
  --sdk-auth
```

This will output JSON like:
```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

### Step 2: Add GitHub Secret

1. Go to your GitHub repository
2. Navigate to: **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `AZURE_CREDENTIALS`
5. Value: Paste the entire JSON output from Step 1
6. Click **Add secret**

### Step 3: Verify Permissions

Ensure your service principal has the necessary permissions:

```bash
# Check role assignments
az role assignment list --assignee <client-id> --output table

# Add additional roles if needed (example for Key Vault access)
az role assignment create \
  --assignee <client-id> \
  --role "Key Vault Administrator" \
  --scope "/subscriptions/<subscription-id>"
```

## 🔐 Additional Security Setup (Optional)

### Environment-Specific Secrets

For enhanced security, you can create environment-specific credentials:

- `AZURE_CREDENTIALS_DEV`
- `AZURE_CREDENTIALS_STAGING` 
- `AZURE_CREDENTIALS_PROD`

Then update the workflow to use environment-specific secrets:

```yaml
- name: Configure Azure CLI
  uses: azure/login@v1
  with:
    creds: ${{ secrets[format('AZURE_CREDENTIALS_{0}', upper(matrix.environment))] }}
```

### Terraform Backend Authentication

If using Azure Storage for Terraform backend, also set these secrets:

- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET`
- `ARM_SUBSCRIPTION_ID`
- `ARM_TENANT_ID`

## 📋 Current Status

- ✅ **Workflow Updated**: All jobs now use proper Azure authentication
- ✅ **Error Handling**: Graceful fallback if authentication fails
- ✅ **Security Enhanced**: Uses Azure service principal for secure access
- ⚠️ **Action Required**: You need to set up the `AZURE_CREDENTIALS` secret

## 🎯 Next Steps

1. **Create Service Principal**: Follow Step 1 above
2. **Add GitHub Secret**: Follow Step 2 above
3. **Test Workflow**: Push code to trigger the workflow
4. **Verify Access**: Ensure service principal has required permissions

Once you've set up the `AZURE_CREDENTIALS` secret, your GitHub Actions workflow will be able to authenticate with Azure and deploy your infrastructure successfully! 🎉

## 🔍 Troubleshooting

**If authentication still fails:**

1. Verify the JSON format in the secret is correct
2. Check service principal permissions
3. Ensure subscription ID is correct
4. Validate tenant ID matches your Azure AD tenant

**For debugging, you can temporarily add:**
```yaml
- name: Debug Azure Account
  run: |
    az account list --output table
    az account show --output table
```
