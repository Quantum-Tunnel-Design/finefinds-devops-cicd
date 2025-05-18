import * as cdk from 'aws-cdk-lib';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as cr from 'aws-cdk-lib/custom-resources';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

interface CognitoConstructProps {
  environment: string;
  config: BaseConfig;
}

interface UserPoolConfig {
  userPoolName: string;
  selfSignUpEnabled: boolean;
  passwordPolicy: {
    minLength: number;
    requireLowercase: boolean;
    requireUppercase: boolean;
    requireNumbers: boolean;
    requireSymbols: boolean;
  };
  userGroups: Record<string, { name: string; description: string }>;
}

export class CognitoConstruct extends Construct {
  public readonly clientUserPool: cognito.UserPool;
  public readonly adminUserPool: cognito.UserPool;
  public readonly clientUserPoolClient: cognito.UserPoolClient;
  public readonly adminUserPoolClient: cognito.UserPoolClient;
  private readonly awsSdkLayer: lambda.LayerVersion;

  constructor(scope: Construct, id: string, props: CognitoConstructProps) {
    super(scope, id);

    // Create Lambda layer with aws-sdk
    this.awsSdkLayer = new lambda.LayerVersion(this, 'AwsSdkLayer', {
      code: lambda.Code.fromAsset('../../lambda/layers/aws-sdk'),
      compatibleRuntimes: [lambda.Runtime.NODEJS_18_X],
      description: 'Layer containing aws-sdk for Cognito user group handlers',
    });

    // Create user pools
    this.clientUserPool = this.createUserPool('Client', props.config.cognito.clientUsers, props.environment);
    this.adminUserPool = this.createUserPool('Admin', props.config.cognito.adminUsers, props.environment);

    // Create user groups
    this.createUserGroups(this.clientUserPool, props.config.cognito.clientUsers.userGroups, 'Client');
    this.createUserGroups(this.adminUserPool, props.config.cognito.adminUsers.userGroups, 'Admin');

    // Create app clients
    this.clientUserPoolClient = this.createUserPoolClient('Client', this.clientUserPool, props);
    this.adminUserPoolClient = this.createUserPoolClient('Admin', this.adminUserPool, props);

    // Configure identity providers
    this.configureIdentityProviders(props);

    // Output user pool IDs
    this.createOutputs(props.environment);
  }

  private createUserPool(
    type: 'Client' | 'Admin',
    config: UserPoolConfig,
    environment: string
  ): cognito.UserPool {
    const isProd = environment === 'prod';
    const passwordPolicy = this.getPasswordPolicy(config.passwordPolicy, isProd);

    return new cognito.UserPool(this, `${type}UserPool`, {
      userPoolName: config.userPoolName,
      selfSignUpEnabled: config.selfSignUpEnabled,
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
      passwordPolicy,
      mfa: isProd ? cognito.Mfa.REQUIRED : cognito.Mfa.OFF,
      ...(isProd ? {
        mfaSecondFactor: {
          sms: true,
          otp: true
        }
      } : {}),
      accountRecovery: cognito.AccountRecovery.EMAIL_ONLY,
      removalPolicy: isProd ? cdk.RemovalPolicy.RETAIN : cdk.RemovalPolicy.DESTROY,
    });
  }

  private getPasswordPolicy(
    policy: UserPoolConfig['passwordPolicy'],
    isProd: boolean
  ): cognito.PasswordPolicy {
    return {
      minLength: isProd ? policy.minLength : Math.min(policy.minLength, 6),
      requireLowercase: isProd ? policy.requireLowercase : false,
      requireUppercase: isProd ? policy.requireUppercase : false,
      requireDigits: isProd ? policy.requireNumbers : true,
      requireSymbols: isProd ? policy.requireSymbols : false,
    };
  }

  private createUserGroups(
    userPool: cognito.UserPool,
    groups: Record<string, { name: string; description: string }>,
    type: 'Client' | 'Admin'
  ): void {
    Object.entries(groups).forEach(([key, group]) => {
      new cognito.CfnUserPoolGroup(this, `${type}UserGroup-${key}`, {
        userPoolId: userPool.userPoolId,
        groupName: group.name,
        description: group.description,
      });
    });
  }

  private createUserPoolClient(
    type: 'Client' | 'Admin',
    userPool: cognito.UserPool,
    props: CognitoConstructProps
  ): cognito.UserPoolClient {
    const isProd = props.environment === 'prod';
    const clientName = `${props.environment}-${type}AppClient`;

    return new cognito.UserPoolClient(this, `${type}AppClient`, {
      userPool,
      userPoolClientName: clientName,
      generateSecret: isProd,
      oAuth: {
        flows: {
          authorizationCodeGrant: true,
          implicitCodeGrant: true,
        },
        callbackUrls: [
          ...(isProd ? [] : ['http://localhost:3000/callback', 'http://localhost:3000/signin']),
        ],
        logoutUrls: [
          ...(isProd ? [] : ['http://localhost:3000/signout']),
        ],
        scopes: [
          cognito.OAuthScope.EMAIL,
          cognito.OAuthScope.OPENID,
          cognito.OAuthScope.PROFILE,
        ],
      },
      preventUserExistenceErrors: isProd,
      accessTokenValidity: cdk.Duration.hours(isProd ? 1 : 8),
      idTokenValidity: cdk.Duration.hours(isProd ? 1 : 8),
      refreshTokenValidity: cdk.Duration.days(isProd ? 30 : 90),
    });
  }

  private configureIdentityProviders(props: CognitoConstructProps): void {
    const { identityProviders } = props.config.cognito;
    if (!identityProviders) return;

    const providers = [
      {
        type: 'Google' as const,
        config: identityProviders.google,
        attributeMapping: {
          email: cognito.ProviderAttribute.GOOGLE_EMAIL,
          givenName: cognito.ProviderAttribute.GOOGLE_GIVEN_NAME,
          familyName: cognito.ProviderAttribute.GOOGLE_FAMILY_NAME,
        },
      },
      {
        type: 'Facebook' as const,
        config: identityProviders.facebook,
        attributeMapping: {
          email: cognito.ProviderAttribute.FACEBOOK_EMAIL,
          givenName: cognito.ProviderAttribute.FACEBOOK_FIRST_NAME,
          familyName: cognito.ProviderAttribute.FACEBOOK_LAST_NAME,
        },
      },
      {
        type: 'Amazon' as const,
        config: identityProviders.amazon,
        attributeMapping: {
          email: cognito.ProviderAttribute.AMAZON_EMAIL,
          givenName: cognito.ProviderAttribute.AMAZON_NAME,
          familyName: cognito.ProviderAttribute.AMAZON_NAME,
        },
      },
    ];

    providers.forEach(({ type, config, attributeMapping }) => {
      if (!config) return;

      const provider = new cognito[`UserPoolIdentityProvider${type}`](this, `${type}Provider`, {
        userPool: this.clientUserPool,
        clientId: config.clientId,
        clientSecret: config.clientSecret,
        attributeMapping,
      });

      this.clientUserPoolClient.node.addDependency(provider);
    });
  }

  private createOutputs(environment: string): void {
    new cdk.CfnOutput(this, 'ClientUserPoolId', {
      value: this.clientUserPool.userPoolId,
      description: 'Client User Pool ID',
      exportName: `finefinds-${environment}-client-user-pool-id`,
    });

    new cdk.CfnOutput(this, 'AdminUserPoolId', {
      value: this.adminUserPool.userPoolId,
      description: 'Admin User Pool ID',
      exportName: `finefinds-${environment}-admin-user-pool-id`,
    });
  }
} 