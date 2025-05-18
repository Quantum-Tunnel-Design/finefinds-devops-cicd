const AWS = require('aws-sdk');
const cognito = new AWS.CognitoIdentityServiceProvider();

exports.handler = async (event) => {
  if (event.RequestType === 'Delete') {
    return;
  }

  const params = {
    UserPoolId: process.env.USER_POOL_ID,
    GroupName: process.env.GROUP_NAME,
    Description: process.env.GROUP_DESCRIPTION
  };

  try {
    await cognito.getGroup(params).promise();
    console.log('Group already exists');
  } catch (error) {
    if (error.code === 'ResourceNotFoundException') {
      await cognito.createGroup(params).promise();
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
}; 