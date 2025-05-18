import { BaseConfig } from './base-config';

export const qaConfig: BaseConfig = {
  environment: 'qa',
  vpc: {
    cidr: '10.3.0.0/16',
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
    repositoryName: 'finefinds-qa',
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
    backupRetentionDays: 14,
    performanceInsights: true,
  },
  cognito: {
    clientUsers: {
      userPoolName: 'finefinds-qa-client-users',
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
      userPoolName: 'finefinds-qa-admin-users',
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
    Environment: 'qa',
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
    endpoint: 'https://search-finefinds-qa-xxxxx.us-east-1.es.amazonaws.com',
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
      branch: 'qa',
      buildSettings: {
        buildCommand: 'npm run build',
        startCommand: 'npm start',
        environmentVariables: {
          REACT_APP_API_URL: 'https://api.qa.finefinds.com',
          REACT_APP_ENV: 'qa',
        },
      },
    },
    adminApp: {
      repository: 'finefinds-admin',
      owner: 'amalgamage',
      branch: 'qa',
      buildSettings: {
        buildCommand: 'npm run build',
        startCommand: 'npm start',
        environmentVariables: {
          REACT_APP_API_URL: 'https://api.qa.finefinds.com',
          REACT_APP_ENV: 'qa',
        },
      },
    },
  },
}; 