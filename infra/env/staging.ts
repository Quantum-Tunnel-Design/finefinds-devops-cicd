import { BaseConfig } from './base-config';

export const stagingConfig: BaseConfig = {
  environment: 'staging',
  dns: {
    domainName: '', // Using AWS default domains
    hostedZoneId: '', // No Route53 hosted zone needed
    certificateValidation: false, // No custom domain validation needed
  },
  vpc: {
    maxAzs: 3,
    natGateways: 2,
    cidr: '10.2.0.0/16',
  },
  ecs: {
    containerPort: 3000,
    cpu: 1024,
    memoryLimitMiB: 2048,
    desiredCount: 2,
    minCapacity: 2,
    maxCapacity: 6,
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
    alarmEmail: 'staging-alerts@finefinds.com',
    slackChannel: '#staging-alerts',
  },
  s3: {
    versioned: true,
    lifecycleRules: true,
  },
  redis: {
    nodeType: 'cache.t3.medium',  // Medium instance for staging
    numNodes: 2,                  // Multi-node for staging
    engineVersion: '7.0',         // Latest stable Redis version
    snapshotRetentionLimit: 5,    // Keep 5 snapshots for staging
    snapshotWindow: '03:00-04:00', // UTC time
    maintenanceWindow: 'sun:04:00-sun:05:00', // UTC time
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
    username: 'AKIAXXXXXXXXXXXXXXXX', // Replace with your SMTP username
  },
  opensearch: {
    endpoint: 'https://search-finefinds-staging-xxxxxxxxxxxx.us-east-1.es.amazonaws.com', // Replace with your OpenSearch endpoint
  },
  tags: {
    Environment: 'staging',
    Project: 'FineFinds',
    ManagedBy: 'CDK',
  },
}; 