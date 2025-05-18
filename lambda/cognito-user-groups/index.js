const AWS = require('aws-sdk');
const cognito = new AWS.CognitoIdentityServiceProvider();

// Helper function to wait
const wait = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// Helper function to handle retries with exponential backoff
async function retryWithBackoff(operation, maxRetries = 5, initialDelay = 1000) {
  let retries = 0;
  let delay = initialDelay;

  while (true) {
    try {
      return await operation();
    } catch (error) {
      if (error.code === 'TooManyRequestsException' && retries < maxRetries) {
        console.log(`Rate limited, retrying in ${delay}ms (attempt ${retries + 1}/${maxRetries})`);
        await wait(delay);
        delay *= 2; // Exponential backoff
        retries++;
        continue;
      }
      throw error;
    }
  }
}

exports.handler = async (event) => {
  const params = {
    UserPoolId: process.env.USER_POOL_ID,
    GroupName: process.env.GROUP_NAME
  };

  try {
    if (event.RequestType === 'Delete') {
      try {
        await retryWithBackoff(() => cognito.deleteGroup(params).promise());
        console.log('Group deleted successfully');
      } catch (error) {
        if (error.code === 'ResourceNotFoundException') {
          console.log('Group already deleted');
        } else {
          throw error;
        }
      }
      return;
    }

    // For Create/Update operations
    try {
      await retryWithBackoff(() => cognito.getGroup(params).promise());
      console.log('Group already exists');
    } catch (error) {
      if (error.code === 'ResourceNotFoundException') {
        await retryWithBackoff(() => cognito.createGroup({
          ...params,
          Description: process.env.GROUP_DESCRIPTION
        }).promise());
        console.log('Group created');
      } else {
        throw error;
      }
    }

    return {
      PhysicalResourceId: process.env.GROUP_NAME,
      Data: {
        GroupName: process.env.GROUP_NAME
      }
    };
  } catch (error) {
    console.error('Error:', error);
    throw error;
  }
}; 