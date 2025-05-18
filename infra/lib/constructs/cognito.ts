import * as cdk from 'aws-cdk-lib';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as iam from 'aws-cdk-lib/aws-iam';
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
      // Use advancedSecurityMode (enable only in production to save costs ~$0.05/MAU)
      advancedSecurityMode: props.environment === 'prod'
        ? cognito.AdvancedSecurityMode.ENFORCED
        : cognito.AdvancedSecurityMode.OFF,
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
      // Use advancedSecurityMode (enable only in production to save costs)
      advancedSecurityMode: props.environment === 'prod'
        ? cognito.AdvancedSecurityMode.ENFORCED
        : cognito.AdvancedSecurityMode.OFF,
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
    // Create parent group
    new cognito.CfnUserPoolGroup(this, 'ParentGroup', {
      userPoolId: this.clientUserPool.userPoolId,
      groupName: props.config.cognito.clientUsers.userGroups.parents.name,
      description: props.config.cognito.clientUsers.userGroups.parents.description,
    });

    // Create student group
    new cognito.CfnUserPoolGroup(this, 'StudentGroup', {
      userPoolId: this.clientUserPool.userPoolId,
      groupName: props.config.cognito.clientUsers.userGroups.students.name,
      description: props.config.cognito.clientUsers.userGroups.students.description,
    });

    // Create vendor group
    new cognito.CfnUserPoolGroup(this, 'VendorGroup', {
      userPoolId: this.clientUserPool.userPoolId,
      groupName: props.config.cognito.clientUsers.userGroups.vendors.name,
      description: props.config.cognito.clientUsers.userGroups.vendors.description,
    });

    // Create guest group
    new cognito.CfnUserPoolGroup(this, 'GuestGroup', {
      userPoolId: this.clientUserPool.userPoolId,
      groupName: props.config.cognito.clientUsers.userGroups.guests.name,
      description: props.config.cognito.clientUsers.userGroups.guests.description,
    });
  }

  private createAdminUserGroups(props: CognitoConstructProps): void {
    // Create super admin group
    new cognito.CfnUserPoolGroup(this, 'SuperAdminGroup', {
      userPoolId: this.adminUserPool.userPoolId,
      groupName: props.config.cognito.adminUsers.userGroups.superAdmins.name,
      description: props.config.cognito.adminUsers.userGroups.superAdmins.description,
    });

    // Create admin group
    new cognito.CfnUserPoolGroup(this, 'AdminGroup', {
      userPoolId: this.adminUserPool.userPoolId,
      groupName: props.config.cognito.adminUsers.userGroups.admins.name,
      description: props.config.cognito.adminUsers.userGroups.admins.description,
    });

    // Create support group
    new cognito.CfnUserPoolGroup(this, 'SupportGroup', {
      userPoolId: this.adminUserPool.userPoolId,
      groupName: props.config.cognito.adminUsers.userGroups.support.name,
      description: props.config.cognito.adminUsers.userGroups.support.description,
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
        clientSecret: identityProviders.google.clientSecret,
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
        },
      });
    }
  }
} 