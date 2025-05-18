export interface BaseConfig {
  environment: string;
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
    instanceClass: string;
    instanceSize: string;
    multiAz: boolean;
    backupRetentionDays: number;
    performanceInsights: boolean;
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
      userGroups: {
        [key: string]: {
          name: string;
          description: string;
        };
      };
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
      userGroups: {
        [key: string]: {
          name: string;
          description: string;
        };
      };
    };
    identityProviders: Record<string, any>;
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
} 