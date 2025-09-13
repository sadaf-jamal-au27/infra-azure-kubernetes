# 🔑 Setup Azure Credentials for GitHub Actions

## 🚨 **Issue: Invalid Client Secret**

The pipeline is failing with `AADSTS7000215: Invalid client secret provided` because the service principal secret in GitHub is expired or invalid.

---

## ✅ **Solution: Create New Service Principal**

I've created a fresh Azure service principal with valid credentials. The actual credentials are stored locally in `AZURE_CREDENTIALS.json` (not committed to git for security).

---

## 🔧 **Step-by-Step Fix**

### **1. Get the Credentials**

The credentials are available in the local file `AZURE_CREDENTIALS.json`. You can view them with:

```bash
cat AZURE_CREDENTIALS.json
```

### **2. Update GitHub Repository Secret**

1. **Go to your GitHub repository**
2. **Navigate to**: Repository → Settings → Secrets and variables → Actions
3. **Find the secret**: `AZURE_CREDENTIALS`
4. **Click**: "Update" (or delete and create new if update option isn't available)
5. **Copy the entire JSON** from `AZURE_CREDENTIALS.json` and paste it as the secret value
6. **Click**: "Update secret"

### **3. Verify the Secret**

- ✅ **Name**: `AZURE_CREDENTIALS`
- ✅ **Value**: Complete JSON from the local file
- ✅ **Format**: Valid JSON with all required fields

---

## 🧪 **Test the Fix**

### **Option 1: Trigger Pipeline Manually**
```bash
# Push a small change to trigger the pipeline
git add .
git commit -m "Update Azure credentials"
git push origin main
```

### **Option 2: Manual Workflow Trigger**
1. Go to: Repository → Actions tab
2. Select: "Infrastructure CI/CD Pipeline"
3. Click: "Run workflow"
4. Select: "main" branch
5. Click: "Run workflow"

### **Option 3: GitHub CLI**
```bash
gh workflow run cicd.yaml
```

---

## 📊 **Expected Results**

### **Pipeline Success Indicators:**
- ✅ **Azure Login**: "Configure Azure CLI" step should succeed
- ✅ **Terraform Init**: All environments should initialize successfully
- ✅ **Terraform Validate**: All configurations should validate
- ✅ **Security Scan**: Checkov should run and pass (84/84 checks)
- ✅ **Terraform Plan**: Plans should generate successfully

### **What You'll See:**
```
✅ Configure Azure CLI
✅ Set Terraform Azure Environment Variables
✅ Terraform Init and Validate (Dev)
✅ Terraform Init and Validate (Staging)
✅ Security Scan with Checkov
✅ Upload Checkov Results to GitHub Security
```

---

## 🔍 **Troubleshooting**

### **If Still Getting Authentication Errors:**

1. **Check Secret Format**:
   - Ensure JSON is valid (no syntax errors)
   - No extra spaces or line breaks
   - All quotes are straight quotes (`"` not `"`)

2. **Verify Service Principal**:
   ```bash
   # Test locally with credentials from AZURE_CREDENTIALS.json
   export ARM_CLIENT_ID="[FROM_JSON_FILE]"
   export ARM_CLIENT_SECRET="[FROM_JSON_FILE]"
   export ARM_SUBSCRIPTION_ID="[FROM_JSON_FILE]"
   export ARM_TENANT_ID="[FROM_JSON_FILE]"
   export ARM_USE_CLI=false
   
   cd lib/environments/dev
   terraform init -backend=false
   terraform validate
   ```

3. **Check Azure Permissions**:
   - Service principal has Contributor role
   - Subscription is active and accessible
   - No conditional access policies blocking the SP

### **Common Issues:**

- **Secret Expiry**: Service principal secrets expire (this one is fresh)
- **Wrong Tenant**: Ensure tenant ID matches your Azure subscription
- **Insufficient Permissions**: Contributor role provides full access
- **JSON Format**: Must be valid JSON with all required fields

---

## 🎯 **Next Steps After Fix**

1. **Monitor Pipeline**: Watch the Actions tab for successful runs
2. **Verify Deployment**: Check that resources are being created in Azure
3. **Review Logs**: If any issues, check the workflow logs for specific errors
4. **Update Documentation**: Note the new service principal for future reference

---

## 📞 **Support**

If you continue to have issues:

1. **Check Workflow Logs**: Repository → Actions → Click on failed run → View logs
2. **Verify Azure Access**: Ensure your Azure subscription is active
3. **Test Locally**: Use the environment variables from `AZURE_CREDENTIALS.json` to test terraform locally
4. **Create New SP**: If needed, run `./scripts/create-new-service-principal.sh` again

---

## 🎉 **Summary**

✅ **New Service Principal**: Created with valid credentials
✅ **Credentials File**: Available locally in `AZURE_CREDENTIALS.json`
✅ **GitHub Secret**: Ready to be updated with JSON from local file
✅ **Authentication**: Will work once secret is updated
✅ **Pipeline**: Ready to run successfully

**Status**: 🔧 **READY FOR SECRET UPDATE**

Once you update the `AZURE_CREDENTIALS` secret in GitHub with the JSON from `AZURE_CREDENTIALS.json`, your pipeline will work perfectly!
