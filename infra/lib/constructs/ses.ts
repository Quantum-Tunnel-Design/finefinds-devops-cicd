import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as ses from 'aws-cdk-lib/aws-ses';
import * as sns from 'aws-cdk-lib/aws-sns';
import { BaseConfig } from '../../env/base-config';

export interface SesConstructProps {
  config: BaseConfig['ses'];
  envIdentifier: string; // e.g., 'dev', 'prod' to make names unique
}

export class SesConstruct extends Construct {
  public readonly configurationSetName: string;
  public readonly emailIdentityName: string;

  constructor(scope: Construct, id: string, props: SesConstructProps) {
    super(scope, id);

    const uniqueName = (baseName: string) => `${baseName}-${props.envIdentifier}`.toLowerCase();

    // SNS Topic for Bounces, Complaints, and Deliveries
    // For simplicity, using one topic. Can be split later if needed.
    const sesNotificationsTopic = new sns.Topic(this, 'SesNotificationsTopic', {
      displayName: uniqueName('FineFindsSESNotifications'),
      topicName: uniqueName('FineFindsSESNotificationsTopic'),
    });

    // SES Configuration Set
    const configurationSet = new ses.CfnConfigurationSet(this, 'ConfigurationSet', {
      name: uniqueName('FineFindsConfigSet'),
      reputationOptions: {
        reputationMetricsEnabled: true,
      },
      sendingOptions: {
        sendingEnabled: true,
      },
      // Suppress all bounces and complaints by default (good for dev/test)
      // For prod, you'd likely want more granular control or to send to a dead-letter queue
      suppressionOptions: {
        suppressedReasons: ['BOUNCE', 'COMPLAINT'],
      },
      trackingOptions: {
        customRedirectDomain: `tracking.${props.config.domainName}`,
      },
    });

    this.configurationSetName = configurationSet.name!;

    // Event Destination to SNS
    new ses.CfnConfigurationSetEventDestination(this, 'EventDestinationToSns', {
      configurationSetName: this.configurationSetName,
      eventDestination: {
        enabled: true,
        matchingEventTypes: ['bounce', 'complaint', 'delivery', 'send', 'reject', 'open', 'click'],
        name: uniqueName('FineFindsSnsEventDestination'),
        snsDestination: {
          topicArn: sesNotificationsTopic.topicArn,
        },
      },
    });

    // Email Identity for the domain
    const emailIdentity = new ses.CfnEmailIdentity(this, 'EmailIdentity', {
      emailIdentity: props.config.domainName, // Using domain name for identity
      // DKIM and MailFrom attributes are omitted due to potential CDK version issues
      // These should be configured manually in the AWS console post-deployment if needed
    });

    this.emailIdentityName = emailIdentity.ref; // ref returns the identity name (e.g., the domain)

    // CDK Outputs
    new cdk.CfnOutput(this, 'SesConfigurationSetOutput', {
      value: this.configurationSetName,
      description: 'SES Configuration Set Name',
      exportName: uniqueName('SesConfigurationSetName'),
    });

    new cdk.CfnOutput(this, 'SesEmailIdentityOutput', {
      value: this.emailIdentityName,
      description: 'SES Email Identity Name (Domain)',
      exportName: uniqueName('SesEmailIdentityName'),
    });
  }
} 