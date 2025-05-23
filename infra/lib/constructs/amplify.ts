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

    const connectToRepo = this.node.tryGetContext('connectAmplifyToRepo') === 'true';

    let clientAppProps: amplify.AppProps = {
      appName: `finefinds-${props.environment}-client-web`,
      environmentVariables: {
        ...props.config.amplify.clientWebApp.buildSettings.environmentVariables,
        NEXT_PUBLIC_API_URL: `https://api-${props.config.environment}.finefindslk.com`,
        NEXT_PUBLIC_COGNITO_USER_POOL_ID: props.config.cognito.clientUsers.userPoolName,
        NEXT_PUBLIC_COGNITO_CLIENT_ID: props.config.cognito.clientUsers.userPoolName,
        NEXT_PUBLIC_AWS_REGION: props.config.region || 'us-east-1',
        NODE_ENV: props.environment.toLowerCase(),
        live_updates: '[{"name":"next","pkg":"@aws-amplify/cli"}]',
      },
      buildSpec: codebuild.BuildSpec.fromObject({
        version: '1.0',
        applications: [
          {
            appRoot: '.',
            frontend: {
              phases: {
                preBuild: {
                  commands: [
                    'npm ci'
                  ],
                },
                build: {
                  commands: [
                    'npm run build'
                  ],
                },
              },
              artifacts: {
                baseDirectory: '.next',
                files: [
                  '**/*'
                ],
              },
              cache: {
                paths: [
                  'node_modules/**/*',
                  '.next/cache/**/*'
                ],
              },
              buildPath: '/'
            }
          }
        ]
      }),
      platform: amplify.Platform.WEB_COMPUTE,
    };

    if (connectToRepo) {
      clientAppProps = {
        ...clientAppProps,
        sourceCodeProvider: new amplify.GitHubSourceCodeProvider({
          owner: 'Quantum-Tunnel-Design',
          repository: 'finefinds-client-web-app',
          oauthToken: cdk.SecretValue.secretsManager(`finefinds-${props.environment}-github-token`, {
            jsonField: 'token',
          }),
        }),
      };
    }

    // Create client web app
    this.clientApp = new amplify.App(this, 'ClientWebApp', clientAppProps);

    let adminAppProps: amplify.AppProps = {
      appName: `finefinds-${props.environment}-admin`,
      environmentVariables: {
        ...props.config.amplify.adminApp.buildSettings.environmentVariables,
        NEXT_PUBLIC_API_URL: `https://api-${props.config.environment}.finefindslk.com`,
        NEXT_PUBLIC_COGNITO_USER_POOL_ID: props.config.cognito.adminUsers.userPoolName,
        NEXT_PUBLIC_COGNITO_CLIENT_ID: props.config.cognito.adminUsers.userPoolName,
        NEXT_PUBLIC_AWS_REGION: props.config.region || 'us-east-1',
        NODE_ENV: props.environment.toLowerCase(),
        live_updates: '[{"name":"next","pkg":"@aws-amplify/cli"}]',
      },
      buildSpec: codebuild.BuildSpec.fromObject({
        version: '1.0',
        applications: [
          {
            appRoot: '.',
            frontend: {
              phases: {
                preBuild: {
                  commands: [
                    'npm ci'
                  ],
                },
                build: {
                  commands: [
                    'npm run build'
                  ],
                },
              },
              artifacts: {
                baseDirectory: '.next',
                files: [
                  '**/*'
                ],
              },
              cache: {
                paths: [
                  'node_modules/**/*',
                  '.next/cache/**/*'
                ],
              },
              buildPath: '/'
            }
          }
        ]
      }),
      platform: amplify.Platform.WEB_COMPUTE,
    };

    if (connectToRepo) {
      adminAppProps = {
        ...adminAppProps,
        sourceCodeProvider: new amplify.GitHubSourceCodeProvider({
          owner: 'Quantum-Tunnel-Design',
          repository: 'finefinds-admin',
          oauthToken: cdk.SecretValue.secretsManager(`finefinds-${props.environment}-github-token`, {
            jsonField: 'token',
          }),
        }),
      };
    }
    // Create admin app
    this.adminApp = new amplify.App(this, 'AdminApp', adminAppProps);

    // Add branches for each environment only if connecting to repo
    if (connectToRepo) {
      const branchName = props.environment === 'prod' ? 'main' : props.environment;
      
      // Client Web App branches
      this.clientApp.addBranch(branchName, {
        stage: props.environment === 'prod' ? 'PRODUCTION' : 'DEVELOPMENT',
        autoBuild: true,
        environmentVariables: {
          ...props.config.amplify.clientWebApp.buildSettings.environmentVariables,
          NEXT_PUBLIC_API_URL: `https://api-${props.config.environment}.finefindslk.com`,
          NEXT_PUBLIC_COGNITO_USER_POOL_ID: props.config.cognito.clientUsers.userPoolName,
          NEXT_PUBLIC_COGNITO_CLIENT_ID: props.config.cognito.clientUsers.userPoolName,
          NEXT_PUBLIC_AWS_REGION: props.config.region || 'us-east-1',
          NODE_ENV: props.environment.toLowerCase(),
        },
      });

      // Admin App branches
      this.adminApp.addBranch(branchName, {
        stage: props.environment === 'prod' ? 'PRODUCTION' : 'DEVELOPMENT',
        autoBuild: true,
        environmentVariables: {
          ...props.config.amplify.adminApp.buildSettings.environmentVariables,
          NEXT_PUBLIC_API_URL: `https://api-${props.config.environment}.finefindslk.com`,
          NEXT_PUBLIC_COGNITO_USER_POOL_ID: props.config.cognito.adminUsers.userPoolName,
          NEXT_PUBLIC_COGNITO_CLIENT_ID: props.config.cognito.adminUsers.userPoolName,
          NEXT_PUBLIC_AWS_REGION: props.config.region || 'us-east-1',
          NODE_ENV: props.environment.toLowerCase(),
        },
      });
    }

    // Output app URLs
    new cdk.CfnOutput(this, 'ClientWebAppUrl', {
      value: this.clientApp.defaultDomain,
      description: 'Client Web App URL',
      exportName: `finefinds-${props.environment}-client-web-url`,
    });

    new cdk.CfnOutput(this, 'AdminAppUrl', {
      value: this.adminApp.defaultDomain,
      description: 'Admin App URL',
      exportName: `finefinds-${props.environment}-admin-url`,
    });
  }
} 