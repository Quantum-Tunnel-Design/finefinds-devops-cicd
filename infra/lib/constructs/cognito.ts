import * as cdk from 'aws-cdk-lib';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as iam from 'aws-cdk-lib/aws-iam';
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

// Define the schema for custom attributes
const customRoleNameAttributeSchema = new cognito.StringAttribute({ mutable: true });
const customMetadataAttributeSchema = new cognito.StringAttribute({ mutable: true });

export class CognitoConstruct extends Construct {
  public readonly clientUserPool: cognito.UserPool;
  public readonly adminUserPool: cognito.UserPool;
  public readonly clientUserPoolClient: cognito.UserPoolClient;
  public readonly adminUserPoolClient: cognito.UserPoolClient;

  // Store the names of custom attributes for easy reference in UserPoolClient
  private readonly customAttributeNames = ['roleName', 'metadata'];

  constructor(scope: Construct, id: string, props: CognitoConstructProps) {
    super(scope, id);

    // Create user pools
    this.clientUserPool = this.createUserPool('Client', props.config.cognito.clientUsers, props.environment);
    this.adminUserPool = this.createUserPool('Admin', props.config.cognito.adminUsers, props.environment);

    // Create user groups
    this.createUserGroups(this.clientUserPool, props.config.cognito.clientUsers.userGroups, 'Client', props.environment);
    this.createUserGroups(this.adminUserPool, props.config.cognito.adminUsers.userGroups, 'Admin', props.environment);

    // Create app clients
    this.clientUserPoolClient = this.createUserPoolClient('Client', this.clientUserPool, props, this.customAttributeNames);
    this.adminUserPoolClient = this.createUserPoolClient('Admin', this.adminUserPool, props, this.customAttributeNames);

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
        email: { required: true, mutable: true },
        phoneNumber: { required: false, mutable: true },
        givenName: { required: true, mutable: true },
        familyName: { required: true, mutable: true },
        // Examples of other standard attributes you might want to customize:
        // address: { required: false, mutable: true },
        // birthdate: { required: false, mutable: true },
        // gender: { required: false, mutable: true },
        // locale: { required: false, mutable: true },
        // middleName: { required: false, mutable: true },
        // name: { required: false, mutable: true }, // typically a concatenation
        // nickname: { required: false, mutable: true },
        // preferredUsername: { required: false, mutable: true }, // often same as username or email
        // picture: { required: false, mutable: true },
        // profile: { required: false, mutable: true }, // URL to a profile page
        // updatedAt: { required: false, mutable: true }, // usually managed by Cognito
        // website: { required: false, mutable: true },
        // zoneinfo: { required: false, mutable: true },
      },
      customAttributes: {
        'roleName': customRoleNameAttributeSchema,
        'metadata': customMetadataAttributeSchema,
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
    type: 'Client' | 'Admin',
    environment: string
  ): void {
    const isProd = environment === 'prod';
    Object.entries(groups).forEach(([key, group]) => {
      const userGroup = new cognito.CfnUserPoolGroup(this, `${type}UserGroup-${key}`, {
        userPoolId: userPool.userPoolId,
        groupName: group.name,
        description: group.description,
      });
      
      userGroup.applyRemovalPolicy(isProd ? cdk.RemovalPolicy.RETAIN : cdk.RemovalPolicy.DESTROY);
    });
  }

  private createUserPoolClient(
    type: 'Client' | 'Admin',
    userPool: cognito.UserPool,
    props: CognitoConstructProps,
    customAttrNames: string[] // Parameter is now an array of custom attribute simple names
  ): cognito.UserPoolClient {
    const isProd = props.environment === 'prod';
    const clientName = `${props.environment}-${type}AppClient`;

    // Map simple names to full custom attribute names (e.g., 'roleName' -> 'custom:roleName')
    const fullCustomAttrNames = customAttrNames.map(name => `custom:${name}`);

    const clientReadAttributes = new cognito.ClientAttributes()
      .withStandardAttributes({ 
        email: true, 
        emailVerified: true, 
        phoneNumber: true, 
        phoneNumberVerified: true,
        givenName: true,
        familyName: true,
        // Add other standard attributes clients can read as needed
      })
      .withCustomAttributes(...fullCustomAttrNames);

    const clientWriteAttributes = new cognito.ClientAttributes()
      .withStandardAttributes({ 
        // Typically, clients might not write to emailVerified or phoneNumberVerified directly
        email: true, 
        phoneNumber: true,
        givenName: true,
        familyName: true,
        // Add other standard attributes clients can write as needed
      })
      .withCustomAttributes(...fullCustomAttrNames);

    return new cognito.UserPoolClient(this, `${type}AppClient`, {
      userPool,
      userPoolClientName: clientName,
      generateSecret: isProd,
      readAttributes: clientReadAttributes,
      writeAttributes: clientWriteAttributes,
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
          // For custom attributes to appear in id_token/access_token via OAuth scopes,
          // you need to set up a Resource Server on the User Pool and define scopes for them.
          // Then add those scopes here, e.g., cognito.OAuthScope.custom('my-resource-server/my.custom.scope')
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