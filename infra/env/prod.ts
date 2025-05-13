import { BaseConfig } from './base-config';

export const prodConfig: BaseConfig = {
  environment: 'prod',
  dns: {
    domainName: '', // Using AWS default domains
    hostedZoneId: '', // No Route53 hosted zone needed
    certificateValidation: false, // No custom domain validation needed
  },
  vpc: {
    maxAzs: 3,
    natGateways: 3,
    cidr: '10.3.0.0/16',
  },
  ecs: {
    containerPort: 3000,
    cpu: 2048,
    memoryLimitMiB: 4096,
    desiredCount: 3,
    minCapacity: 3,
    maxCapacity: 10,
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
    alarmEmail: 'prod-alerts@finefinds.com',
    slackChannel: '#prod-alerts',
  },
  s3: {
    versioned: true,
    lifecycleRules: true,
  },
  redis: {
    nodeType: 'cache.t3.medium',  // Medium instance for prod
    numNodes: 2,                  // Multi-node for prod
    engineVersion: '7.0',         // Latest stable Redis version
    snapshotRetentionLimit: 7,    // Keep 7 snapshots for prod
    snapshotWindow: '03:00-04:00', // UTC time
    maintenanceWindow: 'sun:04:00-sun:05:00', // UTC time
  },
  rds: {
    instanceType: 'db.t3.medium',
    instanceClass: 'db.t3',
    instanceSize: 'medium',
    multiAz: true,
    backupRetentionDays: 30,
    performanceInsights: true,
  },
  waf: {
    rateLimit: 5000,
    enableManagedRules: true,
    enableRateLimit: true,
  },
  backup: {
    dailyRetention: 30,
    weeklyRetention: 12,
    monthlyRetention: 12,
    yearlyRetention: 5,
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
    endpoint: 'https://search-finefinds-prod-xxxxxxxxxxxx.us-east-1.es.amazonaws.com', // Replace with your OpenSearch endpoint
  },
  tags: {
    Environment: 'prod',
    Project: 'FineFinds',
    ManagedBy: 'CDK',
  },
}; 