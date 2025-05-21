import { BaseConfig } from './base-config';

export const uatConfig: BaseConfig = {
  environment: 'uat',
  region: 'us-east-1',
  account: process.env.CDK_DEFAULT_ACCOUNT || '',
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
    healthCheckPath: '/health',
    healthCheckInterval: 30,
    healthCheckTimeout: 5,
    healthCheckHealthyThresholdCount: 2,
    healthCheckUnhealthyThresholdCount: 3,
  },
  ecr: {
    repositoryName: 'finefinds-uat',
  },
  monitoring: {
    alarmEmail: 'devops@finefindslk.com',
    slackChannel: '#devops-alerts',
  },
  s3: {
    versioned: true,
    lifecycleRules: true,
  },
  rds: {
    instanceType: 't3.medium',
    allocatedStorage: 100,
    maxAllocatedStorage: 200,
    backupRetention: 21,
    multiAz: true,
    deletionProtection: true,
  },
  cognito: {
    clientUsers: {
      userPoolName: 'finefinds-uat-client-users',
      selfSignUpEnabled: true,
      passwordPolicy: {
        minLength: 8,
        requireLowercase: true,
        requireUppercase: true,
        requireNumbers: true,
        requireSymbols: true,
      },
      userGroups: {
        parents: {
          name: 'parents',
          description: 'Parent users who can browse and purchase items',
        },
        students: {
          name: 'students',
          description: 'Student users who can browse items',
        },
        vendors: {
          name: 'vendors',
          description: 'Vendor users who can list items for sale',
        },
        guests: {
          name: 'guests',
          description: 'Guest users with limited access',
        },
      },
    },
    adminUsers: {
      userPoolName: 'finefinds-uat-admin-users',
      selfSignUpEnabled: false,
      passwordPolicy: {
        minLength: 12,
        requireLowercase: true,
        requireUppercase: true,
        requireNumbers: true,
        requireSymbols: true,
      },
      userGroups: {
        superAdmins: {
          name: 'super-admins',
          description: 'Super administrators with full system access',
        },
        admins: {
          name: 'admins',
          description: 'Administrators with elevated privileges',
        },
        support: {
          name: 'support',
          description: 'Support staff with limited administrative access',
        },
      },
    },
    identityProviders: {
      google: {
        clientId: 'your-google-client-id',
        clientSecret: 'your-google-client-secret',
      },
      facebook: {
        clientId: 'your-facebook-client-id',
        clientSecret: 'your-facebook-client-secret',
      },
      amazon: {
        clientId: 'your-amazon-client-id',
        clientSecret: 'your-amazon-client-secret',
      },
    },
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
    Environment: 'uat',
    Project: 'finefinds',
    ManagedBy: 'CDK',
  },
  cloudfront: {
    allowedCountries: ['US', 'CA', 'GB', 'AU', 'NZ'],
  },
  smtp: {
    host: 'smtp.gmail.com',
    port: 587,
    username: 'noreply@finefindslk.com',
  },
  opensearch: {
    endpoint: 'https://search-finefinds-uat.us-east-1.es.amazonaws.com',
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
      branch: 'uat',
      buildSettings: {
        buildCommand: 'npm run build',
        startCommand: 'npm start',
        environmentVariables: {
          REACT_APP_API_URL: 'https://api-uat.finefindslk.com',
          REACT_APP_ENV: 'uat',
          NEXT_PUBLIC_ENV: 'uat',
        },
      },
    },
    adminApp: {
      repository: 'finefinds-admin',
      owner: 'amalgamage',
      branch: 'uat',
      buildSettings: {
        buildCommand: 'npm run build',
        startCommand: 'npm start',
        environmentVariables: {
          REACT_APP_API_URL: 'https://api-uat.finefindslk.com',
          REACT_APP_ENV: 'uat',
          NEXT_PUBLIC_ENV: 'uat',
        },
      },
    },
  },
  dynamodb: {
    billingMode: 'PAY_PER_REQUEST',
    pointInTimeRecovery: true,
  },
}; 