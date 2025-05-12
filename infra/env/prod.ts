import { BaseConfig } from './base-config';

export const prodConfig: BaseConfig = {
  environment: 'prod',
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
    maxCapacity: 10,
  },
  monitoring: {
    alarmEmail: 'prod-alerts@finefinds.com',
    slackChannel: '#prod-alerts',
  },
  s3: {
    versioned: true,
    lifecycleRules: true,
  },
  tags: {
    Environment: 'prod',
    Project: 'FineFinds',
    ManagedBy: 'CDK',
  },
}; 