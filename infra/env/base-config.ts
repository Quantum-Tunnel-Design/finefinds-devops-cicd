export interface BaseConfig {
  environment: string;
  region: string;
  account: string;
  vpc: {
    cidr: string;
    maxAzs: number;
    natGateways: number;
  };
  ecs: {
    containerPort: number;
    cpu: number;
    memoryLimitMiB: number;
    desiredCount: number;
    minCapacity: number;
    maxCapacity: number;
    healthCheckPath: string;
    healthCheckInterval: number;
    healthCheckTimeout: number;
    healthCheckHealthyThresholdCount: number;
    healthCheckUnhealthyThresholdCount: number;
  };
  ecr: {
    repositoryName: string;
  };
  monitoring: {
    alarmEmail: string;
    slackChannel: string;
  };
  s3: {
    versioned: boolean;
    lifecycleRules: boolean;
  };
  rds: {
    instanceType: string;
    allocatedStorage: number;
    maxAllocatedStorage: number;
    backupRetention: number;
    multiAz: boolean;
    deletionProtection: boolean;
  };
  cognito: {
    clientUsers: {
      userPoolName: string;
      selfSignUpEnabled: boolean;
      passwordPolicy: {
        minLength: number;
        requireLowercase: boolean;
        requireUppercase: boolean;
        requireNumbers: boolean;
        requireSymbols: boolean;
      };
      userGroups: Record<string, { name: string; description: string }>;
    };
    adminUsers: {
      userPoolName: string;
      selfSignUpEnabled: boolean;
      passwordPolicy: {
        minLength: number;
        requireLowercase: boolean;
        requireUppercase: boolean;
        requireNumbers: boolean;
        requireSymbols: boolean;
      };
      userGroups: Record<string, { name: string; description: string }>;
    };
    identityProviders?: {
      google?: {
        clientId: string;
        clientSecret: string;
      };
      facebook?: {
        clientId: string;
        clientSecret: string;
      };
      amazon?: {
        clientId: string;
        clientSecret: string;
      };
    };
  };
  waf: {
    rateLimit: number;
    enableManagedRules: boolean;
    enableRateLimit: boolean;
  };
  backup: {
    dailyRetention: number;
    weeklyRetention: number;
    monthlyRetention: number;
    yearlyRetention: number;
  };
  tags: {
    [key: string]: string;
  };
  cloudfront: {
    allowedCountries: string[];
  };
  smtp: {
    host: string;
    port: number;
    username: string;
  };
  opensearch: {
    endpoint: string;
  };
  redis: {
    nodeType: string;
    numNodes: number;
    engineVersion: string;
    snapshotRetentionLimit: number;
    snapshotWindow: string;
    maintenanceWindow: string;
  };
  amplify: {
    clientWebApp: {
      repository: string;
      owner: string;
      branch: string;
      buildSettings: {
        buildCommand: string;
        startCommand: string;
        environmentVariables: {
          [key: string]: string;
        };
      };
    };
    adminApp: {
      repository: string;
      owner: string;
      branch: string;
      buildSettings: {
        buildCommand: string;
        startCommand: string;
        environmentVariables: {
          [key: string]: string;
        };
      };
    };
  };
  dynamodb: {
    billingMode: string;
    pointInTimeRecovery: boolean;
  };
  bastion?: {
    keyName?: string;
  };
  ses: {
    fromEmail: string;
    domainName: string;
    templates: {
      welcome: {
        subject: string;
        templateName: string;
      };
      passwordReset: {
        subject: string;
        templateName: string;
      };
      emailVerification: {
        subject: string;
        templateName: string;
      };
    };
  };
} 