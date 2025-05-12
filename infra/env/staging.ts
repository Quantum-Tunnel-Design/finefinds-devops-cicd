import { BaseConfig } from './base-config';

export const stagingConfig: BaseConfig = {
  environment: 'staging',
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
    maxCapacity: 6,
  },
  monitoring: {
    alarmEmail: 'staging-alerts@finefinds.com',
    slackChannel: '#staging-alerts',
  },
  s3: {
    versioned: true,
    lifecycleRules: true,
  },
  tags: {
    Environment: 'staging',
    Project: 'FineFinds',
    ManagedBy: 'CDK',
  },
}; 