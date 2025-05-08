#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print colored messages
print_message() {
    echo -e "${2}${1}${NC}"
}

# Check if git is installed
if ! command -v git &> /dev/null; then
    print_message "Error: git is not installed" "$RED"
    exit 1
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    print_message "Error: terraform is not installed" "$RED"
    exit 1
fi

# Create new DevOps repository
print_message "Creating new DevOps repository..." "$YELLOW"

# Create directory structure
mkdir -p devops/{terraform/{environments/{dev,staging,prod},modules,shared},kubernetes,scripts,docs}

# Move existing Terraform files
print_message "Moving Terraform files..." "$YELLOW"
mv terraform/* devops/terraform/
rm -rf terraform

# Create .gitignore
cat > devops/.gitignore << EOL
# Terraform
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
!example.tfvars
.terraformrc
terraform.rc

# Environment files
.env
.env.*

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/
EOL

# Initialize git repository
cd devops
git init

# Create initial commit
git add .
git commit -m "Initial commit: DevOps configuration"

print_message "DevOps repository created successfully!" "$GREEN"
print_message "Next steps:" "$YELLOW"
echo "1. Create a new repository on GitHub/GitLab"
echo "2. Add the remote repository:"
echo "   git remote add origin <repository-url>"
echo "3. Push the code:"
echo "   git push -u origin main"
echo "4. Update the main repository's CI/CD configuration to use the new DevOps repository"
echo "5. Remove the old DevOps files from the main repository" 