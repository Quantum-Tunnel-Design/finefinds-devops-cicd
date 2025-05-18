import { BaseConfig } from './base-config';

export const prodConfig: BaseConfig = {
  environment: 'prod',
  vpc: {
    cidr: '10.2.0.0/16',
    maxAzs: 3,
    natGateways: 3,
  },
  ecs: {
    containerPort: 3000,
    cpu: 1024,
    memoryLimitMiB: 2048,
    desiredCount: 3,
    minCapacity: 3,
    maxCapacity: 10,
  },
  ecr: {
    repositoryName: 'finefinds-prod',
  },
  monitoring: {
    alarmEmail: 'devops@finefinds.com',
    slackChannel: '#devops-alerts',
  },
  s3: {
    versioned: true,
    lifecycleRules: true,
  },
  rds: {
    instanceType: 'db.t3.large',
    instanceClass: 'db.t3',
    instanceSize: 'large',
    multiAz: true,
    backupRetentionDays: 35,
    performanceInsights: true,
  },
  cognito: {
    clientUsers: {
      userPoolName: 'finefinds-prod-client-users',
      selfSignUpEnabled: true,
      passwordPolicy: {
        minLength: 8,
        requireLowercase: true,
        requireUppercase: true,
        requireNumbers: true,
        requireSymbols: true,
      },
      userGroups: {
        users: {
          name: 'Users',
          description: 'Regular users of the FineFinds platform',
        },
        premiumUsers: {
          name: 'PremiumUsers',
          description: 'Premium users with enhanced features',
        },
      },
    },
    adminUsers: {
      userPoolName: 'finefinds-prod-admin-users',
      selfSignUpEnabled: false,
      passwordPolicy: {
        minLength: 12,
        requireLowercase: true,
        requireUppercase: true,
        requireNumbers: true,
        requireSymbols: true,
      },
      userGroups: {
        admins: {
          name: 'Admins',
          description: 'Administrators with full access',
        },
        support: {
          name: 'Support',
          description: 'Support team members',
        },
      },
    },
    identityProviders: {},
  },
  waf: {
    rateLimit: 8000,
    enableManagedRules: true,
    enableRateLimit: true,
  },
  backup: {
    dailyRetention: 30,
    weeklyRetention: 12,
    monthlyRetention: 12,
    yearlyRetention: 5,
  },
  tags: {
    Environment: 'prod',
    Project: 'FineFinds',
    ManagedBy: 'CDK',
  },
  cloudfront: {
    allowedCountries: ['US', 'CA'],
  },
  smtp: {
    host: 'smtp.gmail.com',
    port: 587,
    username: 'noreply@finefinds.com',
  },
  opensearch: {
    endpoint: 'https://search-finefinds-prod-xxxxx.us-east-1.es.amazonaws.com',
  },
  redis: {
    nodeType: 'cache.t3.large',
    numNodes: 3,
    engineVersion: '7.0',
    snapshotRetentionLimit: 7,
    snapshotWindow: '03:00-04:00',
    maintenanceWindow: 'sun:04:00-sun:05:00',
  },
  amplify: {
    clientWebApp: {
      repository: 'finefinds-client-web',
      owner: 'amalgamage',
      branch: 'main',
      buildSettings: {
        buildCommand: 'npm run build',
        startCommand: 'npm start',
        environmentVariables: {
          REACT_APP_API_URL: 'https://api.finefinds.com',
          REACT_APP_ENV: 'production',
        },
      },
    },
    adminApp: {
      repository: 'finefinds-admin',
      owner: 'amalgamage',
      branch: 'main',
      buildSettings: {
        buildCommand: 'npm run build',
        startCommand: 'npm start',
        environmentVariables: {
          REACT_APP_API_URL: 'https://api.finefinds.com',
          REACT_APP_ENV: 'production',
        },
      },
    },
  },
}; 