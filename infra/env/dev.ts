import { BaseConfig } from './base-config';

export const devConfig: BaseConfig = {
  environment: 'dev',
  dns: {
    domainName: '', // Using AWS default domains
    hostedZoneId: '', // No Route53 hosted zone needed
    certificateValidation: false, // No custom domain validation needed
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
    repositoryName: 'finefinds-services-dev',
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
    alarmEmail: 'dev-alerts@finefinds.com',
    slackChannel: '#dev-alerts',
  },
  s3: {
    versioned: true,
    lifecycleRules: true,
  },
  redis: {
    nodeType: 'cache.t3.micro',  // Small instance for dev
    numNodes: 1,                 // Single node for dev
    engineVersion: '7.0',        // Latest stable Redis version
    snapshotRetentionLimit: 1,   // Keep 1 snapshot for dev
    snapshotWindow: '03:00-04:00', // UTC time
    maintenanceWindow: 'sun:04:00-sun:05:00', // UTC time
  },
  rds: {
    instanceType: 'db.t3.micro',
    instanceClass: 'db.t3',
    instanceSize: 'micro',
    multiAz: false,
    backupRetentionDays: 7,
    performanceInsights: false,
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
  cloudfront: {
    allowedCountries: ['US', 'CA'],
  },
  smtp: {
    host: 'email-smtp.us-east-1.amazonaws.com',
    port: 587,
    username: 'AKIAXXXXXXXXXXXXXXXX', // Replace with your SMTP username
  },
  opensearch: {
    endpoint: 'https://search-finefinds-dev-xxxxxxxxxxxx.us-east-1.es.amazonaws.com', // Replace with your OpenSearch endpoint
  },
  tags: {
    Environment: 'dev',
    Project: 'FineFinds',
    ManagedBy: 'CDK',
  },
}; 