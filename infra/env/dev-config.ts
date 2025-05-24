import { BaseConfig } from './base-config';

export const devConfig: BaseConfig = {
  environment: 'dev',
  region: 'us-east-1',
  account: '891076991993',
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
    healthCheckPath: '/health',
    healthCheckInterval: 60,
    healthCheckTimeout: 30,
    healthCheckHealthyThresholdCount: 2,
    healthCheckUnhealthyThresholdCount: 4,
  },
  ecr: {
    repositoryName: 'finefinds-services-dev',
  },
  monitoring: {
    alarmEmail: 'devops@finefinds.com',
    slackChannel: '#finefinds-dev-alerts',
  },
  s3: {
    versioned: true,
    lifecycleRules: true,
  },
  rds: {
    instanceType: 't3.micro',
    allocatedStorage: 20,
    maxAllocatedStorage: 100,
    backupRetention: 7,
    multiAz: false,
    deletionProtection: false,
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
        customers: {
          name: 'customers',
          description: 'Regular customers',
        },
        premium: {
          name: 'premium',
          description: 'Premium customers',
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
          name: 'admins',
          description: 'Administrators',
        },
        support: {
          name: 'support',
          description: 'Support team',
        },
      },
    },
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
  },
  cloudfront: {
    allowedCountries: ['US', 'CA'],
  },
  smtp: {
    host: 'email-smtp.us-east-1.amazonaws.com',
    port: 587,
    username: 'AKIAXXXXXXXXXXXXXXXX',
  },
  opensearch: {
    endpoint: 'https://search-finefinds-dev-xxxxxxxxxxxx.us-east-1.es.amazonaws.com',
  },
  redis: {
    nodeType: 'cache.t3.micro',
    numNodes: 1,
    engineVersion: '6.2',
    snapshotRetentionLimit: 1,
    snapshotWindow: '03:00-05:00',
    maintenanceWindow: 'sun:05:00-sun:09:00',
  },
  amplify: {
    clientWebApp: {
      repository: 'finefinds-client-web',
      owner: 'finefinds',
      branch: 'develop',
      buildSettings: {
        buildCommand: 'npm run build',
        startCommand: 'npm start',
        environmentVariables: {
          NODE_ENV: 'development',
        },
      },
    },
    adminApp: {
      repository: 'finefinds-admin',
      owner: 'finefinds',
      branch: 'develop',
      buildSettings: {
        buildCommand: 'npm run build',
        startCommand: 'npm start',
        environmentVariables: {
          NODE_ENV: 'development',
        },
      },
    },
  },
  dynamodb: {
    billingMode: 'PAY_PER_REQUEST',
    pointInTimeRecovery: true,
  },
  ses: {
    fromEmail: 'noreply@dev.finefinds.com',
    domainName: 'dev.finefinds.com',
    templates: {
      welcome: 'finefinds-dev-welcome-template',
      passwordReset: 'finefinds-dev-password-reset-template',
      emailVerification: 'finefinds-dev-email-verification-template',
    },
  },
}; 