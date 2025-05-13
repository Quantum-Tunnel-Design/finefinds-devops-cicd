import * as cdk from 'aws-cdk-lib';
import * as events from 'aws-cdk-lib/aws-events';
import * as targets from 'aws-cdk-lib/aws-events-targets';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import { Construct } from 'constructs';
import { BaseConfig } from '../../env/base-config';

export interface AutoShutdownConstructProps {
  environment: string;
  config: BaseConfig;
  cluster: ecs.ICluster;
  service: ecs.IFargateService;
}

export class AutoShutdownConstruct extends Construct {
  constructor(scope: Construct, id: string, props: AutoShutdownConstructProps) {
    super(scope, id);

    // Only create auto-shutdown for non-production environments
    if (['dev', 'sandbox', 'qa'].includes(props.environment)) {
      // Create Lambda function for stopping ECS services
      const shutdownFunction = new lambda.Function(this, 'ShutdownFunction', {
        runtime: lambda.Runtime.NODEJS_18_X,
        handler: 'index.handler',
        code: lambda.Code.fromInline(`
          const AWS = require('aws-sdk');
          const ecs = new AWS.ECS();
          
          exports.handler = async () => {
            try {
              // Get the cluster name from environment variable
              const clusterName = process.env.CLUSTER_NAME;
              const serviceName = process.env.SERVICE_NAME;
              
              console.log(\`Scaling down service \${serviceName} in cluster \${clusterName}\`);
              
              // Update the service to have 0 desired count
              await ecs.updateService({
                cluster: clusterName,
                service: serviceName,
                desiredCount: 0
              }).promise();
              
              console.log('Successfully scaled down service');
              return { statusCode: 200, body: 'Service scaled down successfully' };
            } catch (error) {
              console.error('Error scaling down service:', error);
              throw error;
            }
          };
        `),
        environment: {
          CLUSTER_NAME: props.cluster.clusterName,
          SERVICE_NAME: props.service.serviceName,
        },
        timeout: cdk.Duration.seconds(30),
      });
      
      // Grant permissions to the Lambda function
      shutdownFunction.addToRolePolicy(
        new iam.PolicyStatement({
          actions: ['ecs:UpdateService', 'ecs:DescribeServices'],
          resources: ['*'],
        })
      );
      
      // Create Lambda function for starting ECS services
      const startupFunction = new lambda.Function(this, 'StartupFunction', {
        runtime: lambda.Runtime.NODEJS_18_X,
        handler: 'index.handler',
        code: lambda.Code.fromInline(`
          const AWS = require('aws-sdk');
          const ecs = new AWS.ECS();
          
          exports.handler = async () => {
            try {
              // Get the cluster name from environment variable
              const clusterName = process.env.CLUSTER_NAME;
              const serviceName = process.env.SERVICE_NAME;
              const desiredCount = process.env.DESIRED_COUNT;
              
              console.log(\`Scaling up service \${serviceName} in cluster \${clusterName} to \${desiredCount}\`);
              
              // Update the service to have desired count
              await ecs.updateService({
                cluster: clusterName,
                service: serviceName,
                desiredCount: parseInt(desiredCount, 10)
              }).promise();
              
              console.log('Successfully scaled up service');
              return { statusCode: 200, body: 'Service scaled up successfully' };
            } catch (error) {
              console.error('Error scaling up service:', error);
              throw error;
            }
          };
        `),
        environment: {
          CLUSTER_NAME: props.cluster.clusterName,
          SERVICE_NAME: props.service.serviceName,
          DESIRED_COUNT: '1',
        },
        timeout: cdk.Duration.seconds(30),
      });
      
      // Grant permissions to the Lambda function
      startupFunction.addToRolePolicy(
        new iam.PolicyStatement({
          actions: ['ecs:UpdateService', 'ecs:DescribeServices'],
          resources: ['*'],
        })
      );
      
      // Create EventBridge rule for shutdown (Monday-Friday at 8 PM)
      const shutdownRule = new events.Rule(this, 'ShutdownRule', {
        schedule: events.Schedule.cron({ 
          hour: '20', 
          minute: '0', 
          weekDay: 'MON-FRI' 
        }),
        description: 'Shuts down dev resources on weeknights to save costs',
      });
      
      // Add target to the shutdown rule
      shutdownRule.addTarget(new targets.LambdaFunction(shutdownFunction));
      
      // Create EventBridge rule for startup (Monday-Friday at 7 AM)
      const startupRule = new events.Rule(this, 'StartupRule', {
        schedule: events.Schedule.cron({ 
          hour: '7', 
          minute: '0', 
          weekDay: 'MON-FRI' 
        }),
        description: 'Starts up dev resources on weekday mornings',
      });
      
      // Add target to the startup rule
      startupRule.addTarget(new targets.LambdaFunction(startupFunction));
    }
  }
} 