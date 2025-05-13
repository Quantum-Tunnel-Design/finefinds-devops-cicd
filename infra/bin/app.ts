#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { FineFindsStack } from '../lib/finefinds-stack';
import { FineFindsSonarQubeStack } from '../lib/sonarqube-stack';
import { devConfig } from '../env/dev';
import { stagingConfig } from '../env/staging';
import { qaConfig } from '../env/qa';
import { prodConfig } from '../env/prod';

const app = new cdk.App();

// Check if SonarQube should be included
const includeSonarQube = app.node.tryGetContext('includeSonarQube') === 'true';

// If SonarQube is explicitly requested, create only the shared SonarQube stack
if (includeSonarQube) {
  // Use dev config for SonarQube shared instance
  new FineFindsSonarQubeStack(app, 'FineFindsSonarQubeStack', {
    env: {
      account: process.env.CDK_DEFAULT_ACCOUNT,
      region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
    },
    config: devConfig,
  });
} else {
  // Otherwise, create the normal environment stacks

  // Development Stack
  new FineFindsStack(app, 'FineFinds-dev', {
    env: {
      account: process.env.CDK_DEFAULT_ACCOUNT,
      region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
    },
    config: devConfig,
  });

  // QA Stack
  new FineFindsStack(app, 'FineFinds-qa', {
    env: {
      account: process.env.CDK_DEFAULT_ACCOUNT,
      region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
    },
    config: qaConfig,
  });

  // Staging Stack
  new FineFindsStack(app, 'FineFinds-staging', {
    env: {
      account: process.env.CDK_DEFAULT_ACCOUNT,
      region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
    },
    config: stagingConfig,
  });

  // Production Stack
  new FineFindsStack(app, 'FineFinds-prod', {
    env: {
      account: process.env.CDK_DEFAULT_ACCOUNT,
      region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
    },
    config: prodConfig,
  });
} 