import { BaseConfig } from './base-config';
import { devConfig } from './dev';
import { qaConfig } from './qa';
import { uatConfig } from './uat';
import { prodConfig } from './prod';

export function getConfig(environment: string): BaseConfig {
  switch (environment) {
    case 'dev':
      return devConfig;
    case 'qa':
      return qaConfig;
    case 'uat':
      return uatConfig;
    case 'prod':
      return prodConfig;
    default:
      throw new Error(`Unknown environment: ${environment}`);
  }
} 