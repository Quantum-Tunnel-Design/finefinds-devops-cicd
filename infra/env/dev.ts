import { BaseConfig } from './base-config';

export const devConfig: BaseConfig = {
  environment: 'dev',
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
    maxCapacity: 2,
  },
  monitoring: {
    alarmEmail: 'dev-alerts@finefinds.com',
    slackChannel: '#dev-alerts',
  },
  s3: {
    versioned: true,
    lifecycleRules: true,
  },
  tags: {
    Environment: 'dev',
    Project: 'FineFinds',
    ManagedBy: 'CDK',
  },
}; 