# FineFinds Infrastructure Documentation

This directory contains documentation for the FineFinds AWS infrastructure, formatted for Confluence. These Markdown files can be directly imported into Confluence to create a comprehensive documentation space.

## Documentation Structure

The documentation is organized into the following pages:

1. **[Infrastructure Overview](infrastructure-overview.md)**
   - High-level overview of the FineFinds infrastructure architecture
   - Core components and services
   - Basic architecture diagrams and principles

2. **[Environment Configurations](environment-configurations.md)**
   - Detailed settings for each environment (Production, Development, etc.)
   - Environment-specific service configurations
   - Configuration management approach

3. **[Infrastructure Costs](infrastructure-costs.md)**
   - Cost breakdown by environment and service
   - Cost optimization strategies implemented
   - Reserved Instance and Savings Plans recommendations
   - Budget and cost governance

4. **[DevOps Procedures](devops-procedures.md)**
   - Step-by-step guides for common operations tasks
   - Environment setup instructions
   - Deployment procedures
   - Infrastructure management operations
   - Security management

5. **[VPC Endpoints](vpc-endpoints.md)**
   - VPC Endpoint configuration details
   - Cost analysis and recommendations
   - Implementation instructions

## Using This Documentation

### Importing to Confluence

To import these files into Confluence:

1. Create a new space or page hierarchy in Confluence
2. Use the "Import content" feature, selecting "Markdown"
3. Upload the desired Markdown file
4. Review the import preview and publish

### Updating Documentation

When making infrastructure changes:

1. Update the relevant Markdown files in this directory
2. Include detailed explanations of changes and their impact
3. Keep cost estimates current when prices or configurations change
4. Update procedure documents when processes change

### For New Team Members

New team members should:

1. Start with the Infrastructure Overview document
2. Review the Environment Configurations to understand the different environments
3. Familiarize themselves with the DevOps Procedures for day-to-day operations
4. Use the Infrastructure Costs document to understand cost optimization priorities

## Documentation Maintenance

This documentation should be updated:

- When new infrastructure components are added
- When configurations change
- When costs change significantly
- When operating procedures are modified
- When AWS service properties are updated (e.g., when Cognito StandardThreatProtectionMode was changed to advancedSecurityMode)

The team should perform a quarterly review of all documentation to ensure accuracy. 