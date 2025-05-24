import { BaseConfig } from './base-config';

export const devConfig: BaseConfig = {
  environment: 'dev',
  region: 'us-east-1',
  account: process.env.CDK_DEFAULT_ACCOUNT || '',
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
    healthCheckInterval: 30,
    healthCheckTimeout: 5,
    healthCheckHealthyThresholdCount: 2,
    healthCheckUnhealthyThresholdCount: 3,
  },
  ecr: {
    repositoryName: 'finefinds-dev',
  },
  monitoring: {
    alarmEmail: 'devops@finefindslk.com',
    slackChannel: '#devops-alerts',
    dashboard: {
      name: 'finefinds-dev-dashboard',
      description: 'FineFinds Dev Environment Dashboard',
    },
    alarms: {
      cpuUtilization: {
        threshold: 80,
        evaluationPeriods: 2,
        period: 300,
      },
      memoryUtilization: {
        threshold: 80,
        evaluationPeriods: 2,
        period: 300,
      },
      diskUtilization: {
        threshold: 80,
        evaluationPeriods: 2,
        period: 300,
      },
      requestCount: {
        threshold: 1000,
        evaluationPeriods: 2,
        period: 300,
      },
      errorRate: {
        threshold: 5,
        evaluationPeriods: 2,
        period: 300,
      },
      latency: {
        threshold: 5000,
        evaluationPeriods: 2,
        period: 300,
      },
    },
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
    rateLimit: 2000,
    enableManagedRules: true,
    enableRateLimit: true,
  },
  backup: {
    dailyRetention: 7,
    weeklyRetention: 4,
    monthlyRetention: 3,
    yearlyRetention: 1,
    vault: {
      name: 'finefinds-dev-vault',
      description: 'FineFinds Dev Environment Backup Vault',
    },
    plan: {
      name: 'finefinds-dev-plan',
      description: 'FineFinds Dev Environment Backup Plan',
    },
    schedule: {
      name: 'finefinds-dev-schedule',
      description: 'FineFinds Dev Environment Backup Schedule',
      startWindow: 60,
      completionWindow: 120,
    },
  },
  tags: {
    Environment: 'dev',
    Project: 'finefinds',
    ManagedBy: 'CDK',
  },
  cloudfront: {
    allowedCountries: ['US', 'CA', 'GB', 'AU', 'NZ'],
    priceClass: 'PriceClass_100',
    viewerProtocolPolicy: 'redirect-to-https',
    allowedMethods: ['GET', 'HEAD', 'OPTIONS'],
    cachedMethods: ['GET', 'HEAD', 'OPTIONS'],
    compress: true,
    defaultTtl: 86400,
    minTtl: 0,
    maxTtl: 31536000,
    forwardCookies: ['session'],
    forwardHeaders: ['Authorization'],
    forwardQueryStrings: true,
    viewerCertificate: {
      acmCertificateArn: '',
      sslSupportMethod: 'sni-only',
      minimumProtocolVersion: 'TLSv1.2_2021',
    },
  },
  smtp: {
    host: 'smtp.gmail.com',
    port: 587,
    username: 'noreply@finefindslk.com',
  },
  opensearch: {
    endpoint: 'https://search-finefinds-dev.us-east-1.es.amazonaws.com',
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
          REACT_APP_API_URL: 'https://api-dev.finefindslk.com',
          REACT_APP_ENV: 'dev',
          NEXT_PUBLIC_ENV: 'dev',
          REACT_APP_AWS_REGION: 'us-east-1',
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
          REACT_APP_API_URL: 'https://api-dev.finefindslk.com',
          REACT_APP_ENV: 'dev',
          NEXT_PUBLIC_ENV: 'dev',
          REACT_APP_AWS_REGION: 'us-east-1',
        },
      },
    },
  },
  dynamodb: {
    billingMode: 'PAY_PER_REQUEST',
    pointInTimeRecovery: false,
  },
  bastion: {
    keyName: 'finefinds-dev-bastion',
  },
  ses: {
    domainName: 'dev.finefinds.com',
    fromEmail: 'noreply@dev.finefinds.com',
    templates: {
      welcome: 'finefinds-dev-welcome-template',
      passwordReset: 'finefinds-dev-password-reset-template',
      emailVerification: 'finefinds-dev-email-verification-template',
    },
  },
}; 