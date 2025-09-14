#!/bin/bash

# Script to set up proper approval gates using GitHub CLI
# This creates GitHub Environments with protection rules

set -e

echo "🚦 Setting Up GitHub Environments with Approval Gates"
echo "=================================================="

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "Please install it first: https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI."
    echo "Please run: gh auth login"
    exit 1
fi

# Get repository info
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo "📋 Repository: $REPO"
echo ""

# Function to create environment with protection rules
create_environment() {
    local env_name=$1
    local reviewers=$2
    local wait_timer=$3
    
    echo "🔧 Creating environment: $env_name"
    
    # Create environment
    gh api repos/$REPO/environments/$env_name \
        --method PUT \
        --field name="$env_name" \
        --field protection_rules='[{
            "type": "required_reviewers",
            "required_reviewers": '$reviewers',
            "wait_timer": '$wait_timer'
        }]' \
        --silent
    
    echo "✅ Environment '$env_name' created with protection rules"
}

# Create staging environment
echo "🎭 Setting up Staging Environment..."
create_environment "staging" "1" "0"

# Create production environment  
echo "🏭 Setting up Production Environment..."
create_environment "production" "2" "5"

echo ""
echo "🎉 Approval gates setup complete!"
echo ""
echo "📋 What happens now:"
echo "   🚦 Staging deployments require 1 reviewer approval"
echo "   🚨 Production deployments require 2 reviewer approvals + 5min wait"
echo "   📧 Reviewers will receive email notifications"
echo "   ⏸️  Deployments will pause at approval gates"
echo ""
echo "👥 To add reviewers:"
echo "   1. Go to Settings → Environments"
echo "   2. Select 'staging' or 'production'"
echo "   3. Add required reviewers"
echo ""
echo "🚀 Test the approval gates by pushing to main branch!"
