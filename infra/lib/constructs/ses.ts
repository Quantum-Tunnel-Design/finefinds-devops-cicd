import * as cdk from 'aws-cdk-lib';
import * as ses from 'aws-cdk-lib/aws-ses';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

export interface SesConstructProps {
  environment: string;
  domainName: string;
  fromEmail: string;
}

export class SesConstruct extends Construct {
  public readonly configurationSet: ses.CfnConfigurationSet;
  public readonly bounceTopic: sns.Topic;
  public readonly complaintTopic: sns.Topic;
  public readonly deliveryTopic: sns.Topic;

  constructor(scope: Construct, id: string, props: SesConstructProps) {
    super(scope, id);

    // Create SNS topics for email notifications
    this.bounceTopic = new sns.Topic(this, 'BounceTopic', {
      topicName: `finefinds-${props.environment}-ses-bounce-topic`,
    });

    this.complaintTopic = new sns.Topic(this, 'ComplaintTopic', {
      topicName: `finefinds-${props.environment}-ses-complaint-topic`,
    });

    this.deliveryTopic = new sns.Topic(this, 'DeliveryTopic', {
      topicName: `finefinds-${props.environment}-ses-delivery-topic`,
    });

    // Create SES configuration set
    this.configurationSet = new ses.CfnConfigurationSet(this, 'ConfigurationSet', {
      name: `finefinds-${props.environment}-config`,
      deliveryOptions: {
        tlsPolicy: 'REQUIRE',
      },
      reputationOptions: {
        reputationMetricsEnabled: true,
      },
      sendingOptions: {
        sendingEnabled: true,
      },
      trackingOptions: {
        customRedirectDomain: props.domainName,
      },
    });

    // Add event destinations for bounce, complaint, and delivery notifications
    new ses.CfnConfigurationSetEventDestination(this, 'BounceEventDestination', {
      configurationSetName: this.configurationSet.name!,
      eventDestination: {
        name: 'BounceEventDestination',
        enabled: true,
        matchingEventTypes: ['bounce'],
        snsDestination: {
          topicArn: this.bounceTopic.topicArn,
        },
      },
    });

    new ses.CfnConfigurationSetEventDestination(this, 'ComplaintEventDestination', {
      configurationSetName: this.configurationSet.name!,
      eventDestination: {
        name: 'ComplaintEventDestination',
        enabled: true,
        matchingEventTypes: ['complaint'],
        snsDestination: {
          topicArn: this.complaintTopic.topicArn,
        },
      },
    });

    new ses.CfnConfigurationSetEventDestination(this, 'DeliveryEventDestination', {
      configurationSetName: this.configurationSet.name!,
      eventDestination: {
        name: 'DeliveryEventDestination',
        enabled: true,
        matchingEventTypes: ['delivery'],
        snsDestination: {
          topicArn: this.deliveryTopic.topicArn,
        },
      },
    });

    // Create email identity
    const emailIdentity = new ses.CfnEmailIdentity(this, 'EmailIdentity', {
      emailIdentity: props.fromEmail,
    });

    // Output the configuration set name
    new cdk.CfnOutput(this, 'ConfigurationSetName', {
      value: this.configurationSet.name!,
      description: 'SES Configuration Set Name',
      exportName: `finefinds-${props.environment}-ses-config-set-name`,
    });

    // Output the email identity
    new cdk.CfnOutput(this, 'EmailIdentity', {
      value: emailIdentity.emailIdentity,
      description: 'SES Email Identity',
      exportName: `finefinds-${props.environment}-ses-email-identity`,
    });
  }
} 