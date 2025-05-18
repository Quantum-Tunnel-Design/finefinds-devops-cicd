import { BaseConfig } from './base-config';

export const devConfig: BaseConfig = {
  environment: 'dev',
  vpc: {
    cidr: '10.0.0.0/16',
    maxAzs: 2,
    natGateways: 1,
  },
  ecs: {
    containerPort: 3000,
    cpu: 256,
    memoryLimitMiB: 512,
    desiredCount: 1,
    minCapacity: 1,
    maxCapacity: 2,
  },
  ecr: {
    repositoryName: 'finefinds-dev',
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
    instanceType: 'db.t3.micro',
    instanceClass: 'db.t3',
    instanceSize: 'micro',
    multiAz: false,
    backupRetentionDays: 7,
    performanceInsights: false,
  },
  cognito: {
    clientUsers: {
      userPoolName: 'finefinds-dev-client-users',
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
      userPoolName: 'finefinds-dev-admin-users',
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
    rateLimit: 2000,
    enableManagedRules: true,
    enableRateLimit: true,
  },
  backup: {
    dailyRetention: 7,
    weeklyRetention: 4,
    monthlyRetention: 3,
    yearlyRetention: 1,
  },
  tags: {
    Environment: 'dev',
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
    endpoint: 'https://search-finefinds-dev-xxxxx.us-east-1.es.amazonaws.com',
  },
  redis: {
    nodeType: 'cache.t3.micro',
    numNodes: 1,
    engineVersion: '7.0',
    snapshotRetentionLimit: 1,
    snapshotWindow: '03:00-04:00',
    maintenanceWindow: 'sun:04:00-sun:05:00',
  },
  amplify: {
    clientWebApp: {
      repository: 'finefinds-client-web',
      owner: 'amalgamage',
      branch: 'dev',
      buildSettings: {
        buildCommand: 'npm run build',
        startCommand: 'npm start',
        environmentVariables: {
          REACT_APP_API_URL: 'https://api.dev.finefinds.com',
          REACT_APP_ENV: 'dev',
        },
      },
    },
    adminApp: {
      repository: 'finefinds-admin',
      owner: 'amalgamage',
      branch: 'dev',
      buildSettings: {
        buildCommand: 'npm run build',
        startCommand: 'npm start',
        environmentVariables: {
          REACT_APP_API_URL: 'https://api.dev.finefinds.com',
          REACT_APP_ENV: 'dev',
        },
      },
    },
  },
}; 