import { BaseConfig } from './base-config';

export const qaConfig: BaseConfig = {
  environment: 'qa',
  dns: {
    domainName: 'finefindslk.com',
    hostedZoneId: 'Z1234567890',
    certificateValidation: true,
    subdomains: {
      client: 'qa-app.finefindslk.com',
      admin: 'qa-admin.finefindslk.com',
      api: 'qa-api.finefindslk.com'
    }
  },
  vpc: {
    maxAzs: 2,
    natGateways: 1,
    cidr: '10.0.0.0/16',
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
    repositoryName: 'finefinds-client-web-app-qa',
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
        parents: {
          name: 'Parents',
          description: 'Parent users group',
        },
        students: {
          name: 'Students',
          description: 'Student users group',
        },
        vendors: {
          name: 'Vendors',
          description: 'Vendor users group',
        },
        guests: {
          name: 'Guests',
          description: 'Guest users group',
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
        superAdmins: {
          name: 'SuperAdmins',
          description: 'Super admin users group',
        },
        admins: {
          name: 'Admins',
          description: 'Admin users group',
        },
        support: {
          name: 'Support',
          description: 'Support users group',
        },
      },
    },
    identityProviders: {},
  },
  monitoring: {
    alarmEmail: 'qa-alerts@finefinds.com',
    slackChannel: '#qa-alerts',
  },
  s3: {
    versioned: true,
    lifecycleRules: true,
  },
  redis: {
    nodeType: 'cache.t3.small',  // Small instance for qa
    numNodes: 1,                 // Single node for qa
    engineVersion: '7.0',        // Latest stable Redis version
    snapshotRetentionLimit: 3,   // Keep 3 snapshots for qa
    snapshotWindow: '03:00-04:00', // UTC time
    maintenanceWindow: 'sun:04:00-sun:05:00', // UTC time
  },
  rds: {
    instanceType: 'db.t3.small',
    instanceClass: 'db.t3',
    instanceSize: 'small',
    multiAz: false,
    backupRetentionDays: 14,
    performanceInsights: false,
  },
  waf: {
    rateLimit: 3000,
    enableManagedRules: true,
    enableRateLimit: true,
  },
  backup: {
    dailyRetention: 14,
    weeklyRetention: 8,
    monthlyRetention: 6,
    yearlyRetention: 2,
  },
  cloudfront: {
    allowedCountries: ['US', 'CA'],
  },
  smtp: {
    host: 'email-smtp.us-east-1.amazonaws.com',
    port: 587,
    username: 'AKIAXXXXXXXXXXXXXXXX', // Replace with your SMTP username
  },
  opensearch: {
    endpoint: 'https://search-finefinds-qa-xxxxxxxxxxxx.us-east-1.es.amazonaws.com', // Replace with your OpenSearch endpoint
  },
  tags: {
    Environment: 'qa',
    Project: 'FineFinds',
    ManagedBy: 'CDK',
  },
  amplify: {
    clientWebApp: {
      repository: 'finefinds-client-web-app',
      owner: 'Quantum-Tunnel-Design',
      branch: 'qa',
      buildSettings: {
        buildCommand: 'pnpm build',
        startCommand: 'pnpm start',
        environmentVariables: {
          NEXT_PUBLIC_API_URL: 'https://qa-api.finefindslk.com',
          NODE_ENV: 'qa',
        },
      },
    },
    adminApp: {
      repository: 'finefinds-admin',
      owner: 'Quantum-Tunnel-Design',
      branch: 'qa',
      buildSettings: {
        buildCommand: 'pnpm build',
        startCommand: 'pnpm start',
        environmentVariables: {
          NEXT_PUBLIC_API_URL: 'https://qa-api.finefindslk.com',
          NODE_ENV: 'qa',
        },
      },
    },
  },
}; 