import { DescribeVpcEndpointServicesCommand, EC2Client, ServiceDetail, ServiceTypeDetail } from '@aws-sdk/client-ec2';

const ec2 = new EC2Client({});

// Define types for CloudFormation Custom Resource event and context if not available globally
// This is for type-checking; actual AWSLambda types are available in the Lambda runtime
// Fallback to 'any' if AWSLambda types are not available in the current linting context
type CdkCustomResourceEvent = any; 
type CdkCustomResourceContext = any;

export async function handler(event: CdkCustomResourceEvent, context: CdkCustomResourceContext) {
  console.log('Event: ', JSON.stringify(event, null, 2));
  const requestType = event.RequestType;
  const physicalResourceId = event.PhysicalResourceId || `cognito-service-name-lookup-${event.LogicalResourceId}-${event.RequestId}`;

  if (requestType === 'Delete') {
    // No action needed on delete
    return { PhysicalResourceId: physicalResourceId, Data: {} };
  }

  try {
    // Region is passed in ResourceProperties by the CDK construct
    const region = event.ResourceProperties.Region;
    if (!region) {
      throw new Error('Region not provided in ResourceProperties.');
    }

    const describeParams = {}; // No filters, get all interface services for the region
    const command = new DescribeVpcEndpointServicesCommand(describeParams);
    const response = await ec2.send(command);

    let cognitoIdpServiceName = '';
    let cognitoIdentityServiceName = '';

    if (response.ServiceDetails) {
      for (const service of response.ServiceDetails as ServiceDetail[]) { // Added type assertion
        if (service.ServiceName && service.ServiceTypeDetails) { // Changed ServiceType to ServiceTypeDetails
          // Check if ServiceTypeDetails array contains an object with ServiceType 'Interface'
          if (service.ServiceTypeDetails.some((st: ServiceTypeDetail) => st.ServiceType === 'Interface')) { 
            if (service.ServiceName.endsWith('.cognito-idp')) {
              cognitoIdpServiceName = service.ServiceName;
            }
            if (service.ServiceName.endsWith('.cognito-identity')) {
              cognitoIdentityServiceName = service.ServiceName;
            }
          }
        }
      }
    }

    if (!cognitoIdpServiceName) {
      console.warn(`Could not find Cognito IDP service name in region ${region}. Available services: ${JSON.stringify(response.ServiceDetails?.map((s: ServiceDetail) => s.ServiceName))}`);
    }
    if (!cognitoIdentityServiceName) {
      console.warn(`Could not find Cognito Identity service name in region ${region}. Available services: ${JSON.stringify(response.ServiceDetails?.map((s: ServiceDetail) => s.ServiceName))}`);
    }

    const responseData = {
      CognitoIdpServiceName: cognitoIdpServiceName,
      CognitoIdentityServiceName: cognitoIdentityServiceName,
    };

    console.log('Returning data:', responseData);
    return { PhysicalResourceId: physicalResourceId, Data: responseData };

  } catch (error: any) {
    console.error('Error fetching Cognito service names:', error);
    return { PhysicalResourceId: physicalResourceId, Data: { Error: 'Failed to fetch service names. Check logs for: ' + context.logGroupName + '/' + context.logStreamName } }; 
  }
} 