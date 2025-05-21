import * as cdk from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface LambdaConstructProps {
  environment: string;
  config: BaseConfig;
}

export class LambdaConstruct extends Construct {
  public readonly api: apigateway.RestApi;
  public readonly authFunction: lambda.Function;
  public readonly notificationFunction: lambda.Function;
  public readonly searchFunction: lambda.Function;

  constructor(scope: Construct, id: string, props: LambdaConstructProps) {
    super(scope, id);

    // Create API Gateway
    this.api = new apigateway.RestApi(this, 'Api', {
      restApiName: `finefinds-${props.environment}-api`,
      description: 'finefinds api gateway',
      deployOptions: {
        stageName: props.environment,
        loggingLevel: apigateway.MethodLoggingLevel.INFO,
        dataTraceEnabled: props.environment === 'prod',
        metricsEnabled: props.environment === 'prod',
        tracingEnabled: props.environment === 'prod',
      },
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
        allowHeaders: [
          'Content-Type',
          'X-Amz-Date',
          'Authorization',
          'X-Api-Key',
          'X-Amz-Security-Token',
        ],
      },
    });

    // Create auth Lambda function
    this.authFunction = new lambda.Function(this, 'AuthFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/auth'),
      environment: {
        ENVIRONMENT: props.environment,
        USER_POOL_ID: props.config.cognito.clientUsers.userPoolName,
        USER_POOL_CLIENT_ID: props.config.cognito.clientUsers.userPoolName,
      },
      timeout: cdk.Duration.seconds(30),
      memorySize: props.environment === 'prod' ? 256 : 128,
      tracing: props.environment === 'prod' ? lambda.Tracing.ACTIVE : lambda.Tracing.DISABLED,
      logRetention: props.environment === 'prod' 
        ? logs.RetentionDays.ONE_MONTH 
        : logs.RetentionDays.ONE_WEEK,
    });

    // Add auth permissions to Lambda function
    this.authFunction.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'cognito-idp:AdminInitiateAuth',
          'cognito-idp:AdminCreateUser',
          'cognito-idp:AdminSetUserPassword',
          'cognito-idp:AdminGetUser',
          'cognito-idp:AdminUpdateUserAttributes',
        ],
        resources: ['*'],
      })
    );

    // Create notification Lambda function
    this.notificationFunction = new lambda.Function(this, 'NotificationFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/notification'),
      environment: {
        ENVIRONMENT: props.environment,
        SMTP_HOST: props.config.smtp.host,
        SMTP_PORT: props.config.smtp.port.toString(),
        SMTP_USERNAME: props.config.smtp.username,
      },
      timeout: cdk.Duration.seconds(30),
      memorySize: props.environment === 'prod' ? 256 : 128,
      tracing: props.environment === 'prod' ? lambda.Tracing.ACTIVE : lambda.Tracing.DISABLED,
      logRetention: props.environment === 'prod' 
        ? logs.RetentionDays.ONE_MONTH 
        : logs.RetentionDays.ONE_WEEK,
    });

    // Add notification permissions to Lambda function
    this.notificationFunction.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'secretsmanager:GetSecretValue',
          'ses:SendEmail',
          'ses:SendRawEmail',
        ],
        resources: ['*'],
      })
    );

    // Create search Lambda function
    this.searchFunction = new lambda.Function(this, 'SearchFunction', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/search'),
      environment: {
        ENVIRONMENT: props.environment,
        OPENSEARCH_ENDPOINT: props.environment === 'prod' ? props.config.opensearch.endpoint : '',
      },
      timeout: cdk.Duration.seconds(30),
      memorySize: props.environment === 'prod' ? 512 : 256,
      tracing: props.environment === 'prod' ? lambda.Tracing.ACTIVE : lambda.Tracing.DISABLED,
      logRetention: props.environment === 'prod' 
        ? logs.RetentionDays.ONE_MONTH 
        : logs.RetentionDays.ONE_WEEK,
    });

    // Add search permissions to Lambda function
    this.searchFunction.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'es:ESHttp*',
          'secretsmanager:GetSecretValue',
        ],
        resources: ['*'],
      })
    );

    // Create API Gateway resources and methods
    const authResource = this.api.root.addResource('auth');
    const notificationResource = this.api.root.addResource('notification');
    const searchResource = this.api.root.addResource('search');

    // Add auth endpoints
    authResource.addMethod('POST', new apigateway.LambdaIntegration(this.authFunction));
    authResource.addResource('verify').addMethod('POST', new apigateway.LambdaIntegration(this.authFunction));
    authResource.addResource('refresh').addMethod('POST', new apigateway.LambdaIntegration(this.authFunction));

    // Add notification endpoints
    notificationResource.addMethod('POST', new apigateway.LambdaIntegration(this.notificationFunction));
    notificationResource.addResource('email').addMethod('POST', new apigateway.LambdaIntegration(this.notificationFunction));
    notificationResource.addResource('sms').addMethod('POST', new apigateway.LambdaIntegration(this.notificationFunction));

    // Add search endpoints
    searchResource.addMethod('GET', new apigateway.LambdaIntegration(this.searchFunction));
    searchResource.addResource('suggest').addMethod('GET', new apigateway.LambdaIntegration(this.searchFunction));
    searchResource.addResource('autocomplete').addMethod('GET', new apigateway.LambdaIntegration(this.searchFunction));

    // Output API Gateway URL
    new cdk.CfnOutput(this, 'ApiUrl', {
      value: this.api.url,
      description: 'API Gateway URL',
      exportName: `finefinds-${props.environment}-api-url`,
    });
  }
} 