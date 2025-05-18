import * as cdk from 'aws-cdk-lib';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as cr from 'aws-cdk-lib/custom-resources';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface CognitoConstructProps {
  environment: string;
  config: BaseConfig;
}

export class CognitoConstruct extends Construct {
  public readonly clientUserPool: cognito.UserPool;
  public readonly adminUserPool: cognito.UserPool;
  public readonly clientUserPoolClient: cognito.UserPoolClient;
  public readonly adminUserPoolClient: cognito.UserPoolClient;

  constructor(scope: Construct, id: string, props: CognitoConstructProps) {
    super(scope, id);

    // Create client user pool
    this.clientUserPool = new cognito.UserPool(this, 'ClientUserPool', {
      userPoolName: props.config.cognito.clientUsers.userPoolName,
      selfSignUpEnabled: props.config.cognito.clientUsers.selfSignUpEnabled,
      signInAliases: {
        email: true,
        phone: true,
      },
      standardAttributes: {
        email: {
          required: true,
          mutable: true,
        },
        phoneNumber: {
          required: false,
          mutable: true,
        },
        givenName: {
          required: true,
          mutable: true,
        },
        familyName: {
          required: true,
          mutable: true,
        },
      },
      passwordPolicy: {
        minLength: props.environment === 'prod' 
          ? props.config.cognito.clientUsers.passwordPolicy.minLength
          : Math.min(props.config.cognito.clientUsers.passwordPolicy.minLength, 6),
        requireLowercase: props.environment === 'prod' 
          ? props.config.cognito.clientUsers.passwordPolicy.requireLowercase
          : false,
        requireUppercase: props.environment === 'prod' 
          ? props.config.cognito.clientUsers.passwordPolicy.requireUppercase
          : false,
        requireDigits: props.environment === 'prod' 
          ? props.config.cognito.clientUsers.passwordPolicy.requireNumbers
          : true,
        requireSymbols: props.environment === 'prod' 
          ? props.config.cognito.clientUsers.passwordPolicy.requireSymbols
          : false,
      },
      // Disable MFA for non-prod, enable for prod
      mfa: props.environment === 'prod' ? cognito.Mfa.REQUIRED : cognito.Mfa.OFF,
      // Only specify mfaSecondFactor for production
      ...(props.environment === 'prod' ? {
        mfaSecondFactor: {
          sms: true,
          otp: true
        }
      } : {}),
      accountRecovery: cognito.AccountRecovery.EMAIL_ONLY,
      removalPolicy: props.environment === 'prod' 
        ? cdk.RemovalPolicy.RETAIN 
        : cdk.RemovalPolicy.DESTROY,
    });

    // Create admin user pool
    this.adminUserPool = new cognito.UserPool(this, 'AdminUserPool', {
      userPoolName: props.config.cognito.adminUsers.userPoolName,
      selfSignUpEnabled: props.config.cognito.adminUsers.selfSignUpEnabled,
      signInAliases: {
        email: true,
        phone: true,
      },
      standardAttributes: {
        email: {
          required: true,
          mutable: true,
        },
        givenName: {
          required: true,
          mutable: true,
        },
        familyName: {
          required: true,
          mutable: true,
        },
      },
      passwordPolicy: {
        minLength: props.environment === 'prod' 
          ? props.config.cognito.adminUsers.passwordPolicy.minLength
          : 8,
        requireLowercase: props.environment === 'prod' 
          ? props.config.cognito.adminUsers.passwordPolicy.requireLowercase
          : true,
        requireUppercase: props.environment === 'prod' 
          ? props.config.cognito.adminUsers.passwordPolicy.requireUppercase
          : true,
        requireDigits: props.environment === 'prod' 
          ? props.config.cognito.adminUsers.passwordPolicy.requireNumbers
          : true,
        requireSymbols: props.environment === 'prod' 
          ? props.config.cognito.adminUsers.passwordPolicy.requireSymbols
          : false,
      },
      // Disable MFA for non-prod, enable for prod
      mfa: props.environment === 'prod' ? cognito.Mfa.REQUIRED : cognito.Mfa.OFF,
      // Only specify mfaSecondFactor for production
      ...(props.environment === 'prod' ? {
        mfaSecondFactor: {
          sms: true,
          otp: true
        }
      } : {}),
      accountRecovery: cognito.AccountRecovery.EMAIL_ONLY,
      removalPolicy: props.environment === 'prod' 
        ? cdk.RemovalPolicy.RETAIN 
        : cdk.RemovalPolicy.DESTROY,
    });

    // Create user groups for client pool
    this.createClientUserGroups(props);

    // Create user groups for admin pool
    this.createAdminUserGroups(props);

    // Create app clients
    this.clientUserPoolClient = this.createUserPoolClient(
      'ClientAppClient',
      this.clientUserPool,
      props
    );

    this.adminUserPoolClient = this.createUserPoolClient(
      'AdminAppClient',
      this.adminUserPool,
      props
    );

    // Configure identity providers if provided
    this.configureIdentityProviders(props);

    // Output user pool IDs
    new cdk.CfnOutput(this, 'ClientUserPoolId', {
      value: this.clientUserPool.userPoolId,
      description: 'Client User Pool ID',
      exportName: `finefinds-${props.environment}-client-user-pool-id`,
    });

    new cdk.CfnOutput(this, 'AdminUserPoolId', {
      value: this.adminUserPool.userPoolId,
      description: 'Admin User Pool ID',
      exportName: `finefinds-${props.environment}-admin-user-pool-id`,
    });
  }

  private createClientUserGroups(props: CognitoConstructProps): void {
    // Create user groups for client user pool
    Object.entries(props.config.cognito.clientUsers.userGroups).forEach(([key, group]) => {
      const customResource = new cdk.CustomResource(this, `ClientUserGroup-${key}`, {
        serviceToken: new cr.Provider(this, `ClientUserGroupProvider-${key}`, {
          onEventHandler: new lambda.Function(this, `ClientUserGroupHandler-${key}`, {
            runtime: lambda.Runtime.NODEJS_18_X,
            handler: 'index.handler',
            code: lambda.Code.fromInline(`
              const AWS = require('aws-sdk');
              const cognito = new AWS.CognitoIdentityServiceProvider();
              
              exports.handler = async (event) => {
                if (event.RequestType === 'Delete') {
                  return;
                }
                
                const params = {
                  UserPoolId: '${this.clientUserPool.userPoolId}',
                  GroupName: '${group.name}',
                  Description: '${group.description}'
                };
                
                try {
                  await cognito.getGroup(params).promise();
                  console.log('Group already exists');
                } catch (error) {
                  if (error.code === 'ResourceNotFoundException') {
                    await cognito.createGroup(params).promise();
                    console.log('Group created');
                  } else {
                    throw error;
                  }
                }
                
                return {
                  PhysicalResourceId: '${group.name}',
                  Data: {
                    GroupName: '${group.name}'
                  }
                };
              }
            `),
            timeout: cdk.Duration.seconds(30),
          }),
        }).serviceToken,
        properties: {
          GroupName: group.name,
          Description: group.description,
        },
      });
    });
  }

  private createAdminUserGroups(props: CognitoConstructProps): void {
    // Create user groups for admin user pool
    Object.entries(props.config.cognito.adminUsers.userGroups).forEach(([key, group]) => {
      const customResource = new cdk.CustomResource(this, `AdminUserGroup-${key}`, {
        serviceToken: new cr.Provider(this, `AdminUserGroupProvider-${key}`, {
          onEventHandler: new lambda.Function(this, `AdminUserGroupHandler-${key}`, {
            runtime: lambda.Runtime.NODEJS_18_X,
            handler: 'index.handler',
            code: lambda.Code.fromInline(`
              const AWS = require('aws-sdk');
              const cognito = new AWS.CognitoIdentityServiceProvider();
              
              exports.handler = async (event) => {
                if (event.RequestType === 'Delete') {
                  return;
                }
                
                const params = {
                  UserPoolId: '${this.adminUserPool.userPoolId}',
                  GroupName: '${group.name}',
                  Description: '${group.description}'
                };
                
                try {
                  await cognito.getGroup(params).promise();
                  console.log('Group already exists');
                } catch (error) {
                  if (error.code === 'ResourceNotFoundException') {
                    await cognito.createGroup(params).promise();
                    console.log('Group created');
                  } else {
                    throw error;
                  }
                }
                
                return {
                  PhysicalResourceId: '${group.name}',
                  Data: {
                    GroupName: '${group.name}'
                  }
                };
              }
            `),
            timeout: cdk.Duration.seconds(30),
          }),
        }).serviceToken,
        properties: {
          GroupName: group.name,
          Description: group.description,
        },
      });
    });
  }

  private createUserPoolClient(
    id: string,
    userPool: cognito.UserPool,
    props: CognitoConstructProps
  ): cognito.UserPoolClient {
    return new cognito.UserPoolClient(this, id, {
      userPool,
      userPoolClientName: `${props.environment}-${id}`,
      generateSecret: props.environment === 'prod',
      oAuth: {
        flows: {
          authorizationCodeGrant: true,
          implicitCodeGrant: true,
        },
        callbackUrls: [
          // Add localhost for non-prod environments
          ...(props.environment !== 'prod' ? ['http://localhost:3000/callback', 'http://localhost:3000/signin'] : []),
        ],
        logoutUrls: [
          // Add localhost for non-prod environments
          ...(props.environment !== 'prod' ? ['http://localhost:3000/signout'] : []),
        ],
        scopes: [
          cognito.OAuthScope.EMAIL,
          cognito.OAuthScope.OPENID,
          cognito.OAuthScope.PROFILE,
        ],
      },
      preventUserExistenceErrors: props.environment === 'prod',
      accessTokenValidity: cdk.Duration.hours(props.environment === 'prod' ? 1 : 8),
      idTokenValidity: cdk.Duration.hours(props.environment === 'prod' ? 1 : 8),
      refreshTokenValidity: cdk.Duration.days(props.environment === 'prod' ? 30 : 90),
    });
  }

  private configureIdentityProviders(props: CognitoConstructProps): void {
    const { identityProviders } = props.config.cognito;

    if (identityProviders.google) {
      new cognito.UserPoolIdentityProviderGoogle(this, 'GoogleProvider', {
        userPool: this.clientUserPool,
        clientId: identityProviders.google.clientId,
        clientSecretValue: cdk.SecretValue.unsafePlainText(identityProviders.google.clientSecret),
        scopes: ['email', 'profile'],
        attributeMapping: {
          email: cognito.ProviderAttribute.GOOGLE_EMAIL,
          givenName: cognito.ProviderAttribute.GOOGLE_GIVEN_NAME,
          familyName: cognito.ProviderAttribute.GOOGLE_FAMILY_NAME,
        },
      });
    }

    if (identityProviders.facebook) {
      new cognito.UserPoolIdentityProviderFacebook(this, 'FacebookProvider', {
        userPool: this.clientUserPool,
        clientId: identityProviders.facebook.clientId,
        clientSecret: identityProviders.facebook.clientSecret,
        scopes: ['email', 'public_profile'],
        attributeMapping: {
          email: cognito.ProviderAttribute.FACEBOOK_EMAIL,
          givenName: cognito.ProviderAttribute.FACEBOOK_FIRST_NAME,
          familyName: cognito.ProviderAttribute.FACEBOOK_LAST_NAME,
        },
      });
    }

    if (identityProviders.amazon) {
      new cognito.UserPoolIdentityProviderAmazon(this, 'AmazonProvider', {
        userPool: this.clientUserPool,
        clientId: identityProviders.amazon.clientId,
        clientSecret: identityProviders.amazon.clientSecret,
        scopes: ['profile', 'postal_code'],
        attributeMapping: {
          email: cognito.ProviderAttribute.AMAZON_EMAIL,
          givenName: cognito.ProviderAttribute.AMAZON_NAME,
          familyName: cognito.ProviderAttribute.AMAZON_NAME,
        },
      });
    }
  }
} 