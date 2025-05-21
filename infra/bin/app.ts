#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { FineFindsStack } from '../lib/finefinds-stack';
import { FinefindsSonarqubeStack } from '../lib/sonarqube-stack';
import { devConfig } from '../env/dev';
import { uatConfig } from '../env/uat';
import { qaConfig } from '../env/qa';
import { prodConfig } from '../env/prod';

const app = new cdk.App();

// Create custom synthesizer with our qualifier
const customSynthesizer = new cdk.DefaultStackSynthesizer({
  qualifier: app.node.tryGetContext('qualifier') || 'ffdev',
});

// Check if SonarQube should be included
const includeSonarQube = app.node.tryGetContext('includeSonarQube') === 'true';

// Get environment from context or default to dev
const environment = app.node.tryGetContext('env') || 'dev';

// If SonarQube is explicitly requested, create only the shared SonarQube stack
if (includeSonarQube) {
  console.log('Creating SonarQube stack as requested via includeSonarQube context variable');
  
  // Use dev config for SonarQube shared instance
  new FinefindsSonarqubeStack(app, 'FinefindsSonarqubeStack', {
    env: {
      account: process.env.CDK_DEFAULT_ACCOUNT,
      region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
    },
    environment: 'shared',
    config: devConfig,
    synthesizer: customSynthesizer,
  });
  
  console.log('SonarQube stack created. No other stacks will be deployed in this run.');
} else {
  // Otherwise, create only the stack for the specified environment
  console.log(`Creating stack for ${environment} environment`);
  
  // Select configuration based on environment
  let config;
  switch (environment) {
    case 'prod':
      config = prodConfig;
      break;
    case 'uat':
      config = uatConfig;
      break;
    case 'qa':
      config = qaConfig;
      break;
    default:
      config = devConfig;
  }
  
  // Create the stack for the specified environment
  new FineFindsStack(app, `FineFinds-${environment}`, {
    env: {
      account: process.env.CDK_DEFAULT_ACCOUNT,
      region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
    },
    config,
    synthesizer: customSynthesizer,
  });
  
  console.log(`Stack FineFinds-${environment} created.`);
} 