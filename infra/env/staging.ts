import { BaseConfig } from './base-config';

export const stagingConfig: BaseConfig = {
  environment: 'staging',
  vpc: {
    cidr: '10.1.0.0/16',
    maxAzs: 2,
    natGateways: 1,
  },
  ecs: {
    containerPort: 3000,
    cpu: 512,
    memoryLimitMiB: 1024,
    desiredCount: 2,
    minCapacity: 2,
    maxCapacity: 4,
  },
  ecr: {
    repositoryName: 'finefinds-staging',
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
    instanceType: 'db.t3.medium',
    instanceClass: 'db.t3',
    instanceSize: 'medium',
    multiAz: true,
    backupRetentionDays: 21,
    performanceInsights: true,
  },
  cognito: {
    clientUsers: {
      userPoolName: 'finefinds-staging-client-users',
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
      userPoolName: 'finefinds-staging-admin-users',
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
    rateLimit: 4000,
    enableManagedRules: true,
    enableRateLimit: true,
  },
  backup: {
    dailyRetention: 14,
    weeklyRetention: 8,
    monthlyRetention: 6,
    yearlyRetention: 2,
  },
  tags: {
    Environment: 'staging',
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
    endpoint: 'https://search-finefinds-staging-xxxxx.us-east-1.es.amazonaws.com',
  },
  redis: {
    nodeType: 'cache.t3.medium',
    numNodes: 2,
    engineVersion: '7.0',
    snapshotRetentionLimit: 3,
    snapshotWindow: '03:00-04:00',
    maintenanceWindow: 'sun:04:00-sun:05:00',
  },
  amplify: {
    clientWebApp: {
      repository: 'finefinds-client-web',
      owner: 'amalgamage',
      branch: 'staging',
      buildSettings: {
        buildCommand: 'npm run build',
        startCommand: 'npm start',
        environmentVariables: {
          REACT_APP_API_URL: 'https://api.staging.finefinds.com',
          REACT_APP_ENV: 'staging',
        },
      },
    },
    adminApp: {
      repository: 'finefinds-admin',
      owner: 'amalgamage',
      branch: 'staging',
      buildSettings: {
        buildCommand: 'npm run build',
        startCommand: 'npm start',
        environmentVariables: {
          REACT_APP_API_URL: 'https://api.staging.finefinds.com',
          REACT_APP_ENV: 'staging',
        },
      },
    },
  },
}; 