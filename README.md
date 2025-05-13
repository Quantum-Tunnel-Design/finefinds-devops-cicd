# FineFinds Platform

FineFinds is a modern e-commerce platform built with React, Node.js, and AWS infrastructure.

## Project Structure

```
finefinds/
├── frontend/              # React frontend applications
│   ├── client-portal/    # Customer-facing portal
│   └── admin-portal/     # Admin dashboard
├── backend/              # Node.js backend application
├── infra/               # AWS CDK infrastructure
└── docs/                # Project documentation
```

## Prerequisites

- Node.js 18.x or later
- AWS CLI configured with appropriate credentials
- AWS CDK CLI installed (`npm install -g aws-cdk`)
- Docker installed for local development
- MongoDB Atlas account for search functionality
- GitHub account for source control

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/finefinds.git
   cd finefinds
   ```

2. Install dependencies:
   ```bash
   # Install backend dependencies
   cd backend
   npm install

   # Install frontend dependencies
   cd ../frontend/client-portal
   npm install
   cd ../admin-portal
   npm install

   # Install infrastructure dependencies
   cd ../../infra
   npm install
   ```

3. Set up environment variables:
   ```bash
   # Backend
   cp backend/.env.example backend/.env
   # Edit backend/.env with your configuration

   # Frontend
   cp frontend/client-portal/.env.example frontend/client-portal/.env
   cp frontend/admin-portal/.env.example frontend/admin-portal/.env
   # Edit the .env files with your configuration
   ```

4. Start development servers:
   ```bash
   # Backend
   cd backend
   npm run dev

   # Frontend (in separate terminals)
   cd frontend/client-portal
   npm start

   cd frontend/admin-portal
   npm start
   ```

## Infrastructure Deployment

The infrastructure is managed using AWS CDK. See the [Infrastructure README](infra/README.md) for detailed deployment instructions.

## Development Workflow

### Branching Strategy

Our project follows a branch-to-environment mapping strategy:

- `main` branch → Production environment
- `staging` branch → Staging environment
- `qa` branch → QA environment
- `dev` branch → Development environment
- `sonarqube` branch → SonarQube setup and configuration

All feature development should be done in feature branches:

1. Create a new branch for your feature:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and commit them:
   ```bash
   git add .
   git commit -m "Description of your changes"
   ```

3. Push your branch and create a pull request to the appropriate environment branch:
   ```bash
   git push origin feature/your-feature-name
   ```
   
   Then create a PR against:
   - `dev` branch for development testing
   - `qa` branch for quality assurance
   - `staging` branch for pre-production verification
   - `main` branch for production deployment

4. The CI/CD pipeline will:
   - Run tests 
   - Generate a diff of infrastructure changes
   - Deploy to the appropriate environment after approval
   - Send Slack notifications on success or failure

## Testing

```bash
# Backend tests
cd backend
npm test

# Frontend tests
cd frontend/client-portal
npm test

cd frontend/admin-portal
npm test
```

## Code Quality

- SonarQube is deployed separately using a dedicated workflow
- ESLint and Prettier are configured for code formatting
- Husky is set up for pre-commit hooks

## Security

- All infrastructure is deployed with security best practices
- WAF is configured for web application protection
- KMS encryption is used for sensitive data
- IAM roles follow the principle of least privilege
- Regular security scans are performed

## Monitoring

- CloudWatch is used for logging and monitoring
- X-Ray is configured for distributed tracing
- Custom dashboards are available for key metrics
- Alerts are configured for critical issues with Slack notifications

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a pull request to the appropriate environment branch

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 