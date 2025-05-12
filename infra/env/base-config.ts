export interface BaseConfig {
  environment: string;
  vpc: {
    maxAzs: number;
    natGateways: number;
    cidr: string;
  };
  ecs: {
    containerPort: number;
    cpu: number;
    memoryLimitMiB: number;
    desiredCount: number;
    maxCapacity: number;
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
        parents: {
          name: string;
          description: string;
        };
        students: {
          name: string;
          description: string;
        };
        vendors: {
          name: string;
          description: string;
        };
        guests: {
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
        superAdmins: {
          name: string;
          description: string;
        };
        admins: {
          name: string;
          description: string;
        };
        support: {
          name: string;
          description: string;
        };
      };
    };
    identityProviders: {
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
  dns: {
    domainName: string;
    certificateValidation: boolean;
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
} 