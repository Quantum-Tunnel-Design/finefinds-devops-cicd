import { BaseConfig } from './base-config';

export const prodConfig: BaseConfig = {
  environment: 'prod',
  dns: {
    domainName: 'finefindslk.com',
    hostedZoneId: 'Z1234567890',
    certificateValidation: true,
    subdomains: {
      client: 'finefindslk.com',
      admin: 'admin.finefindslk.com',
      api: 'api.finefindslk.com'
    }
  },
  vpc: {
    maxAzs: 3,
    natGateways: 3,
    cidr: '10.2.0.0/16',
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
    repositoryName: 'finefinds-client-web-app-prod',
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
    alarmEmail: 'prod-alerts@finefinds.com',
    slackChannel: '#prod-alerts',
  },
  s3: {
    versioned: true,
    lifecycleRules: true,
  },
  redis: {
    nodeType: 'cache.r6g.large',
    numNodes: 3,
    engineVersion: '7.0',
    snapshotRetentionLimit: 7,
    snapshotWindow: '03:00-04:00',
    maintenanceWindow: 'sun:04:00-sun:05:00',
  },
  rds: {
    instanceType: 'db.r6g.large',
    instanceClass: 'db.r6g',
    instanceSize: 'large',
    multiAz: true,
    backupRetentionDays: 35,
    performanceInsights: true,
  },
  waf: {
    rateLimit: 8000,
    enableManagedRules: true,
    enableRateLimit: true,
  },
  backup: {
    dailyRetention: 35,
    weeklyRetention: 20,
    monthlyRetention: 12,
    yearlyRetention: 5,
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
    endpoint: 'https://search-finefinds-prod-xxxxxxxxxxxx.us-east-1.es.amazonaws.com',
  },
  tags: {
    Environment: 'prod',
    Project: 'FineFinds',
    ManagedBy: 'CDK',
  },
  amplify: {
    clientWebApp: {
      repository: 'finefinds-client-web-app',
      owner: 'Quantum-Tunnel-Design',
      branch: 'main',
      buildSettings: {
        buildCommand: 'pnpm build',
        startCommand: 'pnpm start',
        environmentVariables: {
          NEXT_PUBLIC_API_URL: 'https://api.finefindslk.com',
          NODE_ENV: 'production',
        },
      },
    },
    adminApp: {
      repository: 'finefinds-admin',
      owner: 'Quantum-Tunnel-Design',
      branch: 'main',
      buildSettings: {
        buildCommand: 'pnpm build',
        startCommand: 'pnpm start',
        environmentVariables: {
          NEXT_PUBLIC_API_URL: 'https://api.finefindslk.com',
          NODE_ENV: 'production',
        },
      },
    },
  },
}; 