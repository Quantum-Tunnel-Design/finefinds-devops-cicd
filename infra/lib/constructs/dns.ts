import * as cdk from 'aws-cdk-lib';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import * as targets from 'aws-cdk-lib/aws-route53-targets';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface DnsConstructProps {
  environment: string;
  config: BaseConfig;
  loadBalancer: elbv2.IApplicationLoadBalancer;
  domainName?: string;  // Make domain name optional
}

export class DnsConstruct extends Construct {
  public readonly hostedZone?: route53.IHostedZone;
  public readonly certificate?: acm.ICertificate;
  private readonly domainName?: string;

  constructor(scope: Construct, id: string, props: DnsConstructProps) {
    super(scope, id);

    // Only proceed with DNS setup if domain name is provided
    if (props.domainName) {
      // Set domain name based on environment
      this.domainName = props.environment === 'prod' 
        ? props.domainName 
        : `${props.environment}.${props.domainName}`;

      try {
        // Import existing hosted zone
        this.hostedZone = route53.HostedZone.fromLookup(this, 'HostedZone', {
          domainName: props.domainName,
        });

        // Create SSL certificate
        this.certificate = new acm.Certificate(this, 'Certificate', {
          domainName: this.domainName,
          validation: acm.CertificateValidation.fromDns(this.hostedZone),
        });

        // Create A record for the load balancer
        new route53.ARecord(this, 'AliasRecord', {
          zone: this.hostedZone,
          recordName: this.domainName,
          target: route53.RecordTarget.fromAlias(
            new targets.LoadBalancerTarget(props.loadBalancer)
          ),
        });

        // Output domain name
        new cdk.CfnOutput(this, 'DomainName', {
          value: this.domainName,
          description: 'Domain Name',
          exportName: `finefinds-${props.environment}-domain-name`,
        });

        // Output certificate ARN
        new cdk.CfnOutput(this, 'CertificateArn', {
          value: this.certificate.certificateArn,
          description: 'Certificate ARN',
          exportName: `finefinds-${props.environment}-certificate-arn`,
        });
      } catch (error: unknown) {
        if (error instanceof Error) {
          console.warn(`DNS setup skipped: ${error.message}`);
        } else {
          console.warn('DNS setup skipped due to an unknown error');
        }
      }
    }
  }
} 