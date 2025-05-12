#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { FineFindsStack } from '../lib/finefinds-stack';
import { devConfig } from '../env/dev';
import { prodConfig } from '../env/prod';
import { stagingConfig } from '../env/staging';
import { qaConfig } from '../env/qa';

const app = new cdk.App();

// Get environment from context or default to dev
const env = app.node.tryGetContext('env') || 'dev';

// Select configuration based on environment
let config;
switch (env) {
  case 'prod':
    config = prodConfig;
    break;
  case 'staging':
    config = stagingConfig;
    break;
  case 'qa':
    config = qaConfig;
    break;
  default:
    config = devConfig;
}

// Create the stack
new FineFindsStack(app, `FineFinds-${env}`, {
  env: {
    account: process.env.CDK_DEPLOY_ACCOUNT || app.node.tryGetContext(env)?.account || process.env.CDK_DEFAULT_ACCOUNT || '123456789012',
    region: process.env.CDK_DEPLOY_REGION || app.node.tryGetContext(env)?.region || process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
  config,
  description: `FineFinds Infrastructure Stack for ${env} environment`,
}); 