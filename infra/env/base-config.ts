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
    dashboard: {
      name: string;
      description: string;
    };
    alarms: {
      cpuUtilization: {
        threshold: number;
        evaluationPeriods: number;
        period: number;
      };
      memoryUtilization: {
        threshold: number;
        evaluationPeriods: number;
        period: number;
      };
      diskUtilization: {
        threshold: number;
        evaluationPeriods: number;
        period: number;
      };
      requestCount: {
        threshold: number;
        evaluationPeriods: number;
        period: number;
      };
      errorRate: {
        threshold: number;
        evaluationPeriods: number;
        period: number;
      };
      latency: {
        threshold: number;
        evaluationPeriods: number;
        period: number;
      };
    };
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
    vault: {
      name: string;
      description: string;
    };
    plan: {
      name: string;
      description: string;
    };
    schedule: {
      name: string;
      description: string;
      startWindow: number;
      completionWindow: number;
    };
  };
  tags: {
    [key: string]: string;
  };
  cloudfront: {
    allowedCountries: string[];
    priceClass: string;
    viewerProtocolPolicy: string;
    allowedMethods: string[];
    cachedMethods: string[];
    compress: boolean;
    defaultTtl: number;
    minTtl: number;
    maxTtl: number;
    forwardCookies: string[];
    forwardHeaders: string[];
    forwardQueryStrings: boolean;
    viewerCertificate: {
      acmCertificateArn: string;
      sslSupportMethod: string;
      minimumProtocolVersion: string;
    };
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
    domainName: string;
    fromEmail: string;
    templates: {
      welcome: string;
      passwordReset: string;
      emailVerification: string;
    };
  };
} 