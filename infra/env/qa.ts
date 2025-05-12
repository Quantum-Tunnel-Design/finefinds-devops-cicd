import { BaseConfig } from './base-config';

export const qaConfig: BaseConfig = {
  environment: 'qa',
  vpc: {
    maxAzs: 2,
    natGateways: 1,
    cidr: '10.1.0.0/16',
  },
  ecs: {
    containerPort: 3000,
    cpu: 512,
    memoryLimitMiB: 1024,
    desiredCount: 2,
    maxCapacity: 4,
  },
  monitoring: {
    alarmEmail: 'qa-alerts@finefinds.com',
    slackChannel: '#qa-alerts',
  },
  s3: {
    versioned: true,
    lifecycleRules: true,
  },
  tags: {
    Environment: 'qa',
    Project: 'FineFinds',
    ManagedBy: 'CDK',
  },
}; 