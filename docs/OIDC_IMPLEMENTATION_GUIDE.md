# 🔐 OIDC Implementation Guide for Azure Authentication

## 📋 Overview

This guide will help you implement OpenID Connect (OIDC) authentication for your GitHub Actions pipeline, replacing the current client secret-based authentication with a more secure, token-based approach.

## 🎯 Benefits of OIDC

- ✅ **No Client Secrets**: Eliminates long-lived secrets
- ✅ **Short-lived Tokens**: Automatic token expiration
- ✅ **Enhanced Security**: Modern authentication standard
- ✅ **Compliance**: Meets security best practices
- ✅ **Audit Trail**: Better tracking of authentication events

## 🛠️ Implementation Steps

### Step 1: Create New App Registration with Federated Credentials

#### Option A: Azure Portal (Recommended)

1. **Go to Azure Portal** → **Azure Active Directory** → **App registrations**
2. **Click "New registration"**
3. **Fill in details:**
   ```
   Name: github-actions-todoapp-oidc
   Supported account types: Single tenant
   Redirect URI: Leave blank
   ```
4. **Click "Register"**

5. **Note down the Application (client) ID** - you'll need this

#### Step 2: Create Federated Credential

1. **In your app registration**, go to **Certificates & secrets**
2. **Click "Federated credentials"** tab
3. **Click "Add credential"**
4. **Select "GitHub Actions deploying Azure resources"**
5. **Fill in details:**
   ```
   Organization: Your GitHub username or organization
   Repository: terraform-todoapp-infra
   Entity type: Branch
   Branch name: main
   Name: github-actions-main-branch
   ```
6. **Click "Add"**

#### Step 3: Assign Permissions

1. **Go to "API permissions"**
2. **Click "Add a permission"**
3. **Select "Azure Service Management"**
4. **Choose "user_impersonation"**
5. **Click "Add permissions"**
6. **Click "Grant admin consent"**

#### Step 4: Assign Subscription Role

1. **Go to Subscriptions** → Your subscription
2. **Click "Access control (IAM)"**
3. **Click "Add" → "Add role assignment"**
4. **Role: "Contributor"**
5. **Assign access to: "User, group, or service principal"**
6. **Search for: "github-actions-todoapp-oidc"**
7. **Click "Save"**

### Step 2: Update GitHub Repository Secrets

#### Remove Old Secrets (Optional)
- `AZURE_CLIENT_SECRET` (no longer needed)
- `AZURE_CREDENTIALS` (no longer needed)

#### Add New Secrets
1. **Go to Repository Settings** → **Secrets and variables** → **Actions**
2. **Add these secrets:**

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AZURE_CLIENT_ID` | `your-new-client-id` | New App Registration Client ID |
| `AZURE_TENANT_ID` | `0fc07ff0-d314-4e80-aed7-2dddffabbec7` | Azure AD Tenant ID |
| `AZURE_SUBSCRIPTION_ID` | `8cbf7ca1-02c5-4b17-aa60-0a669dc6f870` | Azure Subscription ID |

### Step 3: Update Pipeline Configuration

The pipeline will be updated to use `azure/login@v1` with OIDC instead of manual ARM environment variables.

## 🔍 Current vs New Authentication

### Current (Client Secret)
```yaml
env:
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}  # ❌ Long-lived secret
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### New (OIDC)
```yaml
- name: Azure Login
  uses: azure/login@v1
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    oidc: true  # ✅ Token-based authentication
```

## 🧪 Testing OIDC

### Test Commands
```bash
# After pipeline update, test with:
az account show
az group list --output table
terraform plan
```

### Expected Behavior
- ✅ No client secret required
- ✅ Short-lived tokens (1 hour)
- ✅ Automatic token refresh
- ✅ Better security audit trail

## 🔒 Security Considerations

1. **Federated Credential Scope**: Only works for specified repository/branch
2. **Token Expiration**: Tokens expire automatically
3. **Audit Logging**: All authentication events are logged
4. **No Secret Storage**: Eliminates secret management overhead

## 📊 Migration Checklist

- [ ] Create new App Registration
- [ ] Add federated credential
- [ ] Assign permissions and roles
- [ ] Update GitHub secrets
- [ ] Update pipeline configuration
- [ ] Test authentication
- [ ] Remove old client secret
- [ ] Update documentation

---

*This guide will be updated as we implement OIDC in your pipeline.*
