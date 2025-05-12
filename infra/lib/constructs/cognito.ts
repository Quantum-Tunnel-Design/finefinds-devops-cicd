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
        minLength: props.config.cognito.clientUsers.passwordPolicy.minLength,
        requireLowercase: props.config.cognito.clientUsers.passwordPolicy.requireLowercase,
        requireUppercase: props.config.cognito.clientUsers.passwordPolicy.requireUppercase,
        requireDigits: props.config.cognito.clientUsers.passwordPolicy.requireNumbers,
        requireSymbols: props.config.cognito.clientUsers.passwordPolicy.requireSymbols,
      },
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
        minLength: props.config.cognito.adminUsers.passwordPolicy.minLength,
        requireLowercase: props.config.cognito.adminUsers.passwordPolicy.requireLowercase,
        requireUppercase: props.config.cognito.adminUsers.passwordPolicy.requireUppercase,
        requireDigits: props.config.cognito.adminUsers.passwordPolicy.requireNumbers,
        requireSymbols: props.config.cognito.adminUsers.passwordPolicy.requireSymbols,
      },
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
      generateSecret: true,
      oAuth: {
        flows: {
          authorizationCodeGrant: true,
          implicitCodeGrant: true,
        },
        callbackUrls: [
          `https://${props.config.dns.domainName}/callback`,
          `https://${props.config.dns.domainName}/signin`,
        ],
        logoutUrls: [
          `https://${props.config.dns.domainName}/signout`,
        ],
        scopes: [
          cognito.OAuthScope.EMAIL,
          cognito.OAuthScope.OPENID,
          cognito.OAuthScope.PROFILE,
        ],
      },
      preventUserExistenceErrors: true,
      accessTokenValidity: cdk.Duration.hours(1),
      idTokenValidity: cdk.Duration.hours(1),
      refreshTokenValidity: cdk.Duration.days(30),
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