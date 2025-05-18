import { BaseConfig } from './base-config';

export const stagingConfig: BaseConfig = {
  environment: 'staging',
  dns: {
    domainName: 'finefindslk.com',
    hostedZoneId: 'Z1234567890',
    certificateValidation: true,
    subdomains: {
      client: 'staging-app.finefindslk.com',
      admin: 'staging-admin.finefindslk.com',
      api: 'staging-api.finefindslk.com'
    }
  },
  vpc: {
    maxAzs: 2,
    natGateways: 1,
    cidr: '10.1.0.0/16',
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
    repositoryName: 'finefinds-client-web-app-staging',
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
        parents: {
          name: 'Parents',
          description: 'Parent users',
        },
        students: {
          name: 'Students',
          description: 'Student users',
        },
        vendors: {
          name: 'Vendors',
          description: 'Vendor users',
        },
        guests: {
          name: 'Guests',
          description: 'Guest users',
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
        superAdmins: {
          name: 'SuperAdmins',
          description: 'Super administrator users',
        },
        admins: {
          name: 'Admins',
          description: 'Administrator users',
        },
        support: {
          name: 'Support',
          description: 'Support team users',
        },
      },
    },
    identityProviders: {},
  },
  monitoring: {
    alarmEmail: 'staging-alerts@finefinds.com',
    slackChannel: '#staging-alerts',
  },
  s3: {
    versioned: true,
    lifecycleRules: true,
  },
  redis: {
    nodeType: 'cache.t3.medium',
    numNodes: 2,
    engineVersion: '7.0',
    snapshotRetentionLimit: 5,
    snapshotWindow: '03:00-04:00',
    maintenanceWindow: 'sun:04:00-sun:05:00',
  },
  rds: {
    instanceType: 'db.t3.medium',
    instanceClass: 'db.t3',
    instanceSize: 'medium',
    multiAz: true,
    backupRetentionDays: 21,
    performanceInsights: true,
  },
  waf: {
    rateLimit: 4000,
    enableManagedRules: true,
    enableRateLimit: true,
  },
  backup: {
    dailyRetention: 21,
    weeklyRetention: 10,
    monthlyRetention: 8,
    yearlyRetention: 3,
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
    endpoint: 'https://search-finefinds-staging-xxxxxxxxxxxx.us-east-1.es.amazonaws.com',
  },
  tags: {
    Environment: 'staging',
    Project: 'FineFinds',
    ManagedBy: 'CDK',
  },
  amplify: {
    clientWebApp: {
      repository: 'finefinds-client-web-app',
      owner: 'Quantum-Tunnel-Design',
      branch: 'staging',
      buildSettings: {
        buildCommand: 'pnpm build',
        startCommand: 'pnpm start',
        environmentVariables: {
          NEXT_PUBLIC_API_URL: 'https://staging-api.finefindslk.com',
          NODE_ENV: 'staging',
        },
      },
    },
    adminApp: {
      repository: 'finefinds-admin',
      owner: 'Quantum-Tunnel-Design',
      branch: 'staging',
      buildSettings: {
        buildCommand: 'pnpm build',
        startCommand: 'pnpm start',
        environmentVariables: {
          NEXT_PUBLIC_API_URL: 'https://staging-api.finefindslk.com',
          NODE_ENV: 'staging',
        },
      },
    },
  },
}; 