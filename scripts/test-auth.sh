#!/bin/bash

# Test Azure Authentication Script

set -e

echo "🔧 Testing Azure Authentication..."

# Get current Azure account
CURRENT_ACCOUNT=$(az account show --output json)
SUBSCRIPTION_ID=$(echo "$CURRENT_ACCOUNT" | jq -r '.id')
TENANT_ID=$(echo "$CURRENT_ACCOUNT" | jq -r '.tenantId')

echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Tenant ID: $TENANT_ID"

# Create a temporary service principal for testing
SP_NAME="test-terraform-auth-$(date +%s)"
echo "Creating test service principal: $SP_NAME"

SP_OUTPUT=$(az ad sp create-for-rbac \
    --name "$SP_NAME" \
    --role "Contributor" \
    --scopes "/subscriptions/$SUBSCRIPTION_ID" \
    --sdk-auth \
    --output json)

echo "Service principal created successfully!"

# Set environment variables
export ARM_CLIENT_ID=$(echo "$SP_OUTPUT" | jq -r .clientId)
export ARM_CLIENT_SECRET=$(echo "$SP_OUTPUT" | jq -r .clientSecret)
export ARM_SUBSCRIPTION_ID=$(echo "$SP_OUTPUT" | jq -r .subscriptionId)
export ARM_TENANT_ID=$(echo "$SP_OUTPUT" | jq -r .tenantId)
export ARM_USE_CLI=false

echo ""
echo "Environment variables set:"
echo "ARM_CLIENT_ID: $ARM_CLIENT_ID"
echo "ARM_SUBSCRIPTION_ID: $ARM_SUBSCRIPTION_ID"
echo "ARM_TENANT_ID: $ARM_TENANT_ID"
echo "ARM_USE_CLI: $ARM_USE_CLI"

# Test terraform
cd lib/environments/dev
echo ""
echo "Testing Terraform with service principal authentication..."

terraform init -backend=false >/dev/null 2>&1
if terraform validate >/dev/null 2>&1; then
    echo "✅ Terraform validation successful"
else
    echo "❌ Terraform validation failed"
    terraform validate
    exit 1
fi

if terraform plan -out=tfplan >/dev/null 2>&1; then
    echo "✅ Terraform plan successful"
    rm -f tfplan
    echo ""
    echo "🎉 Authentication test successful!"
    echo ""
    echo "📄 Use this JSON for GitHub Secrets:"
    echo "$SP_OUTPUT" | jq .
else
    echo "❌ Terraform plan failed"
    terraform plan
    exit 1
fi
