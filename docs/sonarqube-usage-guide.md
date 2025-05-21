# SonarQube Usage Guide

This guide explains how to set up and use SonarQube scanning in your application repositories, using our shared SonarQube instance.

## Overview

We use a single shared SonarQube instance for all repositories and environments to optimize costs while maintaining code quality across projects. Each repository should configure its own scanning workflow to connect to this shared instance.

## Setting Up a New Project

### 1. Create a New Project in SonarQube

1. Log in to the SonarQube instance at the URL stored in your organization's `SONAR_HOST_URL` secret
2. Use the admin token stored in the `SONAR_ADMIN_TOKEN` secret
3. Go to "Administration" > "Projects" > "Create Project"
4. Create a new project with:
   - Project key: Use your repository name (e.g., `frontend-web`)
   - Display name: Use a descriptive name (e.g., `FineFinds Frontend Web`)

### 2. Generate a Project Token

1. In SonarQube, go to "Administration" > "Security" > "Users"
2. Select the user you want to use (typically admin for simplicity)
3. Go to "Tokens" and generate a new token for your project
4. Store this token as a repository secret in GitHub with a name like `SONAR_TOKEN`

### 3. Add Scanning Workflow to Your Repository

Create a file named `.github/workflows/sonarqube-scan.yml` in your repository:

```yaml
name: SonarQube Scan

on:
  push:
    branches: [ main, dev, uat, qa ]
  pull_request:
    branches: [ main, dev, uat, qa ]

jobs:
  sonarqube-scan:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0  # Important for SonarQube to get full history
      
      # Set up language-specific dependencies and tests
      # For JavaScript/TypeScript projects:
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Run tests with coverage
        run: npm test -- --coverage
      
      # SonarQube Scan
      - name: SonarQube Scan
        uses: SonarSource/sonarqube-scan-action@master
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
        with:
          args: >
            -Dsonar.projectKey=${{ github.event.repository.name }}
            -Dsonar.projectName=${{ github.event.repository.name }}
            -Dsonar.branch.name=${{ github.ref_name }}
```

### 4. Configure sonar-project.properties

Create a `sonar-project.properties` file in your repository root:

```properties
# Project identification
sonar.projectKey=your-repo-name
sonar.projectName=Your Repo Name

# Source code location
sonar.sources=src
sonar.tests=src
sonar.test.inclusions=src/**/*.spec.js,src/**/*.spec.ts,src/**/*.test.js,src/**/*.test.ts
sonar.exclusions=node_modules/**,dist/**,coverage/**

# Language
sonar.language=js
sonar.javascript.lcov.reportPaths=coverage/lcov.info

# Encoding of the source code
sonar.sourceEncoding=UTF-8
```

Adjust the configuration based on your project's language and structure.

## Branch-Based Scanning

The workflow is configured to scan different branches (main, dev, uat, qa), which will allow you to:

1. Track code quality across different environments
2. Compare quality between branches
3. Monitor quality trends over time

In SonarQube, you can view branch-specific analyses by selecting the branch from the dropdown in your project dashboard.

## Quality Gates

Quality Gates determine whether your code meets the quality standards. By default, SonarQube provides a "Sonar Way" quality gate that includes checks for:

- Code coverage
- Duplicated code
- Maintainability issues
- Reliability issues
- Security vulnerabilities

You can customize quality gates in the SonarQube admin interface if needed.

## Getting Help

If you encounter issues with SonarQube scanning:

1. Check the GitHub Actions logs for specific error messages
2. Verify your project configuration in the sonar-project.properties file
3. Ensure your SONAR_TOKEN and SONAR_HOST_URL secrets are properly set
4. Contact the DevOps team for assistance with the shared SonarQube instance 