import * as cdk from 'aws-cdk-lib';
import * as amplify from '@aws-cdk/aws-amplify-alpha';
import * as codebuild from 'aws-cdk-lib/aws-codebuild';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface AmplifyConstructProps {
  environment: string;
  config: BaseConfig;
}

export class AmplifyConstruct extends Construct {
  public readonly clientApp: amplify.App;
  public readonly adminApp: amplify.App;

  constructor(scope: Construct, id: string, props: AmplifyConstructProps) {
    super(scope, id);

    // Create client portal app
    this.clientApp = new amplify.App(this, 'ClientPortal', {
      appName: `finefinds-${props.environment}-client-portal`,
      sourceCodeProvider: new amplify.GitHubSourceCodeProvider({
        owner: 'your-org',
        repository: 'finefinds-client-portal',
        oauthToken: cdk.SecretValue.secretsManager('github-token'),
      }),
      environmentVariables: {
        REACT_APP_API_URL: `https://api.${props.config.dns.domainName}`,
        REACT_APP_COGNITO_USER_POOL_ID: props.config.cognito.clientUsers.userPoolName,
        REACT_APP_COGNITO_CLIENT_ID: props.config.cognito.clientUsers.userPoolName,
      },
      buildSpec: codebuild.BuildSpec.fromObject({
        version: '1.0',
        frontend: {
          phases: {
            preBuild: {
              commands: ['npm ci'],
            },
            build: {
              commands: ['npm run build'],
            },
          },
          artifacts: {
            baseDirectory: 'build',
            files: ['**/*'],
          },
          cache: {
            paths: ['node_modules/**/*'],
          },
        },
      }),
    });

    // Create admin portal app
    this.adminApp = new amplify.App(this, 'AdminPortal', {
      appName: `finefinds-${props.environment}-admin-portal`,
      sourceCodeProvider: new amplify.GitHubSourceCodeProvider({
        owner: 'your-org',
        repository: 'finefinds-admin-portal',
        oauthToken: cdk.SecretValue.secretsManager('github-token'),
      }),
      environmentVariables: {
        REACT_APP_API_URL: `https://api.${props.config.dns.domainName}`,
        REACT_APP_COGNITO_USER_POOL_ID: props.config.cognito.adminUsers.userPoolName,
        REACT_APP_COGNITO_CLIENT_ID: props.config.cognito.adminUsers.userPoolName,
      },
      buildSpec: codebuild.BuildSpec.fromObject({
        version: '1.0',
        frontend: {
          phases: {
            preBuild: {
              commands: ['npm ci'],
            },
            build: {
              commands: ['npm run build'],
            },
          },
          artifacts: {
            baseDirectory: 'build',
            files: ['**/*'],
          },
          cache: {
            paths: ['node_modules/**/*'],
          },
        },
      }),
    });

    // Add branches for each environment
    this.clientApp.addBranch('main', {
      stage: props.environment === 'prod' ? 'PRODUCTION' : 'DEVELOPMENT',
      autoBuild: true,
    });

    this.adminApp.addBranch('main', {
      stage: props.environment === 'prod' ? 'PRODUCTION' : 'DEVELOPMENT',
      autoBuild: true,
    });

    // Output app URLs
    new cdk.CfnOutput(this, 'ClientPortalUrl', {
      value: this.clientApp.defaultDomain,
      description: 'Client Portal URL',
      exportName: `finefinds-${props.environment}-client-portal-url`,
    });

    new cdk.CfnOutput(this, 'AdminPortalUrl', {
      value: this.adminApp.defaultDomain,
      description: 'Admin Portal URL',
      exportName: `finefinds-${props.environment}-admin-portal-url`,
    });
  }
} 