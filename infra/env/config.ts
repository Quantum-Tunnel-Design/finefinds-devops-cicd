import { BaseConfig } from './base-config';
import { devConfig } from './dev';
import { qaConfig } from './qa';
import { stagingConfig } from './staging';
import { prodConfig } from './prod';

export function getConfig(environment: string): BaseConfig {
  switch (environment) {
    case 'dev':
      return devConfig;
    case 'qa':
      return qaConfig;
    case 'staging':
      return stagingConfig;
    case 'prod':
      return prodConfig;
    default:
      throw new Error(`Unknown environment: ${environment}`);
  }
} 