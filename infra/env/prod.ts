import { BaseConfig } from './base-config';

export const prodConfig: BaseConfig = {
  environment: 'prod',
  region: 'us-east-1',
  account: process.env.CDK_DEFAULT_ACCOUNT || '',
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
    healthCheckPath: '/health',
    healthCheckInterval: 30,
    healthCheckTimeout: 5,
    healthCheckHealthyThresholdCount: 2,
    healthCheckUnhealthyThresholdCount: 3,
  },
  ecr: {
    repositoryName: 'finefinds-prod',
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
    instanceType: 't3.large',
    allocatedStorage: 200,
    maxAllocatedStorage: 400,
    backupRetention: 35,
    multiAz: true,
    deletionProtection: true,
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
          REACT_APP_API_URL: 'https://api-finefindslk.com',
          REACT_APP_ENV: 'production',
          NEXT_PUBLIC_ENV: 'production',
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
          REACT_APP_API_URL: 'https://api-finefindslk.com',
          REACT_APP_ENV: 'production',
          NEXT_PUBLIC_ENV: 'production',
        },
      },
    },
  },
  dynamodb: {
    billingMode: 'PAY_PER_REQUEST',
    pointInTimeRecovery: true,
  },
}; 