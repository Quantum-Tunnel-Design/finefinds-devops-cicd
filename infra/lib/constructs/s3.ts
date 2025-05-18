import * as cdk from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as kms from 'aws-cdk-lib/aws-kms';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface S3ConstructProps {
  environment: string;
  config: BaseConfig;
  kmsKey: kms.IKey;
}

export class S3Construct extends Construct {
  public readonly uploadsBucket: s3.Bucket;
  public readonly backupsBucket: s3.Bucket;
  public readonly logsBucket: s3.Bucket;
  public readonly mediaBucket: s3.Bucket;
  public readonly distribution: cloudfront.Distribution;
  private readonly account: string;

  constructor(scope: Construct, id: string, props: S3ConstructProps) {
    super(scope, id);

    // Get account from stack
    const stack = cdk.Stack.of(this);
    this.account = stack.account;

    // Common bucket configuration
    const commonBucketProps: s3.BucketProps = {
      encryption: s3.BucketEncryption.KMS,
      encryptionKey: props.kmsKey,
      enforceSSL: true,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      removalPolicy: props.environment === 'prod' 
        ? cdk.RemovalPolicy.RETAIN 
        : cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: props.environment !== 'prod',
      versioned: props.environment === 'prod' ? props.config.s3.versioned : false,
    };

    // Create Uploads Bucket
    this.uploadsBucket = new s3.Bucket(this, 'UploadsBucket', {
      ...commonBucketProps,
      bucketName: `finefinds-${props.environment}-uploads-${this.account}`,
      cors: [
        {
          allowedMethods: [
            s3.HttpMethods.GET,
            s3.HttpMethods.PUT,
            s3.HttpMethods.POST,
            s3.HttpMethods.DELETE,
          ],
          allowedOrigins: ['*'], // TODO: Replace with actual origins
          allowedHeaders: ['*'],
          maxAge: 3000,
        },
      ],
      lifecycleRules: props.environment === 'prod' 
        ? (props.config.s3.lifecycleRules ? [
            {
              abortIncompleteMultipartUploadAfter: cdk.Duration.days(7),
              enabled: true,
            },
            {
              noncurrentVersionExpiration: cdk.Duration.days(90),
              enabled: true,
            },
          ] : undefined)
        : [
            // More aggressive lifecycle rules for non-production
            {
              abortIncompleteMultipartUploadAfter: cdk.Duration.days(1),
              enabled: true,
            },
            {
              expiration: cdk.Duration.days(30), // Auto-delete after 30 days in non-prod
              enabled: true,
            },
            {
              transitions: [
                {
                  storageClass: s3.StorageClass.INFREQUENT_ACCESS,
                  transitionAfter: cdk.Duration.days(7), // Move to IA after 7 days
                }
              ],
              enabled: true,
            }
          ],
    });

    // Create Backups Bucket
    this.backupsBucket = new s3.Bucket(this, 'BackupsBucket', {
      ...commonBucketProps,
      bucketName: `finefinds-${props.environment}-backups-${this.account}`,
      lifecycleRules: props.environment === 'prod'
        ? (props.config.s3.lifecycleRules ? [
            {
              expiration: cdk.Duration.days(365),
              enabled: true,
            },
            {
              noncurrentVersionExpiration: cdk.Duration.days(90),
              enabled: true,
            },
            {
              transitions: [
                {
                  storageClass: s3.StorageClass.INFREQUENT_ACCESS,
                  transitionAfter: cdk.Duration.days(30),
                },
                {
                  storageClass: s3.StorageClass.GLACIER,
                  transitionAfter: cdk.Duration.days(90),
                },
              ],
              enabled: true,
            }
          ] : undefined)
        : [
            // Shorter retention for non-production backups
            {
              expiration: cdk.Duration.days(30), // Only keep backups for 30 days
              enabled: true,
            },
            {
              transitions: [
                {
                  storageClass: s3.StorageClass.INFREQUENT_ACCESS,
                  transitionAfter: cdk.Duration.days(7), // Move to IA after 7 days
                }
              ],
              enabled: true,
            }
          ],
    });

    // Create Logs Bucket
    this.logsBucket = new s3.Bucket(this, 'LogsBucket', {
      ...commonBucketProps,
      bucketName: `finefinds-${props.environment}-logs-${this.account}`,
      lifecycleRules: props.environment === 'prod'
        ? (props.config.s3.lifecycleRules ? [
            {
              expiration: cdk.Duration.days(90),
              enabled: true,
            },
            {
              transitions: [
                {
                  storageClass: s3.StorageClass.INFREQUENT_ACCESS,
                  transitionAfter: cdk.Duration.days(30),
                },
              ],
              enabled: true,
            }
          ] : undefined)
        : [
            // Minimal retention for non-production logs
            {
              expiration: cdk.Duration.days(7), // Only keep logs for 7 days in non-prod
              enabled: true,
            }
          ],
    });

    // Create media bucket
    this.mediaBucket = new s3.Bucket(this, 'MediaBucket', {
      bucketName: `finefinds-${props.environment}-media`,
      versioned: props.config.s3.versioned,
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      removalPolicy: props.environment === 'prod' 
        ? cdk.RemovalPolicy.RETAIN 
        : cdk.RemovalPolicy.DESTROY,
      lifecycleRules: props.config.s3.lifecycleRules ? [
        {
          enabled: true,
          expiration: cdk.Duration.days(365),
          transitions: [
            {
              storageClass: s3.StorageClass.INFREQUENT_ACCESS,
              transitionAfter: cdk.Duration.days(90),
            },
            {
              storageClass: s3.StorageClass.GLACIER,
              transitionAfter: cdk.Duration.days(180),
            },
          ],
        },
      ] : undefined,
      cors: [
        {
          allowedMethods: [
            s3.HttpMethods.GET,
            s3.HttpMethods.HEAD,
          ],
          allowedOrigins: [
            `https://*.${props.config.environment === 'prod' ? 'finefindslk.com' : `${props.config.environment}.finefindslk.com`}`,
          ],
          allowedHeaders: ['*'],
          maxAge: 3000,
        },
      ],
    });

    // Create CloudFront distribution
    this.distribution = new cloudfront.Distribution(this, 'MediaDistribution', {
      defaultBehavior: {
        origin: new origins.S3Origin(this.mediaBucket),
        viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
        allowedMethods: cloudfront.AllowedMethods.ALLOW_GET_HEAD,
        cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
        originRequestPolicy: cloudfront.OriginRequestPolicy.CORS_S3_ORIGIN,
        responseHeadersPolicy: cloudfront.ResponseHeadersPolicy.SECURITY_HEADERS,
        compress: true,
      },
      priceClass: props.environment === 'prod' 
        ? cloudfront.PriceClass.PRICE_CLASS_100 
        : cloudfront.PriceClass.PRICE_CLASS_200,
      enabled: true,
      comment: `FineFinds ${props.environment} Media Distribution`,
      defaultRootObject: 'index.html',
      errorResponses: [
        {
          httpStatus: 403,
          responseHttpStatus: 200,
          responsePagePath: '/index.html',
        },
        {
          httpStatus: 404,
          responseHttpStatus: 200,
          responsePagePath: '/index.html',
        },
      ],
      geoRestriction: cloudfront.GeoRestriction.allowlist(
        ...props.config.cloudfront.allowedCountries
      ),
      minimumProtocolVersion: cloudfront.SecurityPolicyProtocol.TLS_V1_2_2021,
      sslSupportMethod: cloudfront.SSLMethod.SNI,
    });

    // Create bucket policies
    this.createBucketPolicies(props.environment);

    // Output bucket names
    new cdk.CfnOutput(this, 'UploadsBucketName', {
      value: this.uploadsBucket.bucketName,
      description: 'Uploads Bucket Name',
    });

    new cdk.CfnOutput(this, 'BackupsBucketName', {
      value: this.backupsBucket.bucketName,
      description: 'Backups Bucket Name',
    });

    new cdk.CfnOutput(this, 'LogsBucketName', {
      value: this.logsBucket.bucketName,
      description: 'Logs Bucket Name',
    });

    new cdk.CfnOutput(this, 'MediaBucketName', {
      value: this.mediaBucket.bucketName,
      description: 'Media Bucket Name',
      exportName: `finefinds-${props.environment}-media-bucket-name`,
    });

    new cdk.CfnOutput(this, 'MediaDistributionDomain', {
      value: this.distribution.distributionDomainName,
      description: 'Media Distribution Domain',
      exportName: `finefinds-${props.environment}-media-distribution-domain`,
    });
  }

  private createBucketPolicies(environment: string): void {
    // Policy for ECS task role to access uploads bucket
    const uploadsBucketPolicy = new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        's3:GetObject',
        's3:PutObject',
        's3:DeleteObject',
        's3:ListBucket',
      ],
      resources: [
        this.uploadsBucket.bucketArn,
        `${this.uploadsBucket.bucketArn}/*`,
      ],
    });

    // Policy for backup operations
    const backupsBucketPolicy = new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        's3:GetObject',
        's3:PutObject',
        's3:ListBucket',
      ],
      resources: [
        this.backupsBucket.bucketArn,
        `${this.backupsBucket.bucketArn}/*`,
      ],
    });

    // Policy for log operations
    const logsBucketPolicy = new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        's3:PutObject',
        's3:GetObject',
        's3:ListBucket',
      ],
      resources: [
        this.logsBucket.bucketArn,
        `${this.logsBucket.bucketArn}/*`,
      ],
    });

    // Add bucket policies
    this.uploadsBucket.addToResourcePolicy(uploadsBucketPolicy);
    this.backupsBucket.addToResourcePolicy(backupsBucketPolicy);
    this.logsBucket.addToResourcePolicy(logsBucketPolicy);

    // Enable server access logging for all buckets
    this.uploadsBucket.addToResourcePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: ['s3:PutObject'],
        resources: [`${this.logsBucket.bucketArn}/*`],
        principals: [new iam.ServicePrincipal('logging.s3.amazonaws.com')],
      })
    );

    this.backupsBucket.addToResourcePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: ['s3:PutObject'],
        resources: [`${this.logsBucket.bucketArn}/*`],
        principals: [new iam.ServicePrincipal('logging.s3.amazonaws.com')],
      })
    );

    // Create IAM policy for ECS tasks to access media bucket
    const mediaPolicy = new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        's3:PutObject',
        's3:GetObject',
        's3:DeleteObject',
        's3:ListBucket',
      ],
      resources: [
        this.mediaBucket.bucketArn,
        `${this.mediaBucket.bucketArn}/*`,
      ],
    });

    // Add media bucket policy
    this.mediaBucket.addToResourcePolicy(mediaPolicy);
  }
} 