// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0
// Permission is hereby granted, free of charge, to any person obtaining a copy of this
// software and associated documentation files (the "Software"), to deal in the Software
// without restriction, including without limitation the rights to use, copy, modify,
// merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
// PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import * as cdk from '@aws-cdk/core';
import * as iam from '@aws-cdk/aws-iam';
import * as iot from '@aws-cdk/aws-iot';
import * as cognito from '@aws-cdk/aws-cognito';
import * as s3 from '@aws-cdk/aws-s3';
import { CfnAccessKey } from '@aws-cdk/aws-iam';
import { RemovalPolicy } from '@aws-cdk/core';

export class BlexstackStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // The code that defines your stack goes here
    const stack = BlexstackStack.of(this);

    // All the Constants used in this Stack
    const iotPolicyName = "blexMobileAppIoTPermissionsPolicy";
    const blexDataIoTRuleRoleName = "blexDataIoTRuleRole";
    const blexDataIoTRuleName = "blexIoTActionRule";
    const sourceTopic = "blex";
    const republishTopic = "data"

    // Setup Cognito User Pool & Identity Pool
    const userPool = new cognito.UserPool(this, 'blexMobileAppUserPool', {
      autoVerify: {email: true},
      selfSignUpEnabled: true,
      passwordPolicy: {
        minLength: 8,
        requireSymbols: true,
        requireLowercase: true,
        requireDigits: true,
        requireUppercase: true
      }
    });

    userPool.applyRemovalPolicy(RemovalPolicy.DESTROY);

    const userPoolClient = new cognito.UserPoolClient(this, 'blexMobileAppPoolClient', {
      generateSecret: false,
      userPool: userPool,
      userPoolClientName: 'blexMobileApp'
    });

    userPoolClient.applyRemovalPolicy(RemovalPolicy.DESTROY);

    const identityPool = new cognito.CfnIdentityPool(this, 'blexMobileAppIdentityPool', {
      allowUnauthenticatedIdentities: false,
      cognitoIdentityProviders: [{
        clientId: userPoolClient.userPoolClientId,
        providerName: userPool.userPoolProviderName,
      }]
    });

    identityPool.applyRemovalPolicy(RemovalPolicy.DESTROY);

    const authenticatedRole = new iam.Role(this, 'blexMobileAppAuthenticatedRole', {
      roleName: 'blexMobileAppAccessRole',
      assumedBy: new iam.FederatedPrincipal('cognito-identity.amazonaws.com', {
        "StringEquals": { "cognito-identity.amazonaws.com:aud": identityPool.ref },
        "ForAnyValue:StringLike": { "cognito-identity.amazonaws.com:amr": "authenticated"},
      }, "sts:AssumeRoleWithWebIdentity"),
    });

    authenticatedRole.applyRemovalPolicy(RemovalPolicy.DESTROY);

    authenticatedRole.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        "mobileanalytics:PutEvents",
        // These permissions are not needed for this demo, commenting them out.
        // "cognito-sync:*", 
        // "cognito-identity:*"
      ],
      resources: ["*"]
    }));

    // Setup the IoT Policy that will be attached to the Cognito ID of the authenticated user.
    // The connectResource restricts connection to Region/Account and Cognito IDs only.
    // Publish & Subscribe allowed on all topics for the IoT Endpoint belonging to this Account-Region.
    const connectResource = 'arn:aws:iot:' + stack.region + ':' + stack.account + ':client/${cognito-identity.amazonaws.com:sub}';
    const allotherIoTResource = 'arn:aws:iot:' + stack.region + ':' + stack.account + ':*';

    authenticatedRole.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        "iot:Connect",
      ],
      resources: [
        connectResource
    ]
    }));

    authenticatedRole.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        "iot:Subscribe",
        "iot:Receive",
        "iot:Publish"
      ],
      resources: [
        allotherIoTResource
        // "*"
    ]
    }));

    authenticatedRole.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        "iot:AttachPolicy",
        "iot:ListAttachedPolicies",
      ],
      resources: [
        "*"
    ]
    }));

    const defaultPolicy = new cognito.CfnIdentityPoolRoleAttachment(this, 'DefaultValid', {
      identityPoolId: identityPool.ref,
      roles: {
        'authenticated': authenticatedRole.roleArn 
      }
    })

    defaultPolicy.applyRemovalPolicy(RemovalPolicy.DESTROY);

    const blexIoTPolicy = new iot.CfnPolicy(this, 'blexIoTPolicy', {
      policyName: iotPolicyName,
      policyDocument: {
        "Version":"2012-10-17",
        "Statement":[
           {
              "Effect":"Allow",
              "Action":[
                 "iot:Connect"
              ],
              "Resource":[
                  connectResource
              ]
           },
           {
            "Effect":"Allow",
            "Action":[
               "iot:Publish",
               "iot:Subscribe",
               "iot:Receive"
            ],
            "Resource":[
                allotherIoTResource
            ]
         },
        ]
     },
    })

    blexIoTPolicy.applyRemovalPolicy(RemovalPolicy.DESTROY);

    // Setup Topic, Rule and Role for routing traffic coming in from the app
    // 1. Start with the IAM role that will be used for IoT Actions and Rules
    // 2. For this demo - we will use this Role with appropriate permissions for 
    //    all rules
    
    const blexDataIoTRuleRole = new iam.Role(this, 'blexDataIoTRuleRole', {
      roleName: blexDataIoTRuleRoleName,
      assumedBy: new iam.ServicePrincipal('iot.amazonaws.com')
    });

    blexDataIoTRuleRole.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      resources: [
        `arn:aws:iot:${stack.region}:${stack.account}:*`
      ],
      actions: [
        'iot:Publish'
      ]
    }));

    blexDataIoTRuleRole.applyRemovalPolicy(RemovalPolicy.DESTROY);

    const SQL_STATEMENT = `SELECT *, clientid() as cid, principal() as userid FROM '${sourceTopic}'`;
    const topicRepublish = republishTopic + "/${clientid()}";

    const blexIoTRule = new iot.CfnTopicRule(this, 'blexIoTRule', {
      ruleName: blexDataIoTRuleName,
      topicRulePayload: {
        awsIotSqlVersion: '2016-03-23',
        sql: SQL_STATEMENT,
        ruleDisabled: false,
        actions: [
          { republish: {
            topic: topicRepublish,
            roleArn: blexDataIoTRuleRole.roleArn
          }}
        ]
      }        
    });

    // Create a bucket, this is the bucket where IOT Messages will be stored.
    const blexIOTBucket = new s3.Bucket(this, 'DemoIoTBucket', {
      bucketName: "blexbucket-demoiotmessages",
      versioned: true,
      removalPolicy: RemovalPolicy.DESTROY,
      autoDeleteObjects: true
    });

    blexDataIoTRuleRole.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      resources: [
        `arn:aws:s3:::${blexIOTBucket.bucketName}/*`
      ],
      actions: [
        's3:*'
      ]
    }));

    const blexIoTDataStoreRuleName = 'blexIoTRuleToStoreData';
    // const SQL_IOTDATASTORE = `SELECT timestamp, cid, nanoData.DeviceId as DeviceId, nanoData.temperature, nanoData.humidity, nanoData.pressure FROM '${republishTopic}/+'`;
    const SQL_IOTDATASTORE = `SELECT timestamp, cid, regexp_replace(nanoData.DeviceId, ":", "") as deviceId, nanoData.temperature, nanoData.humidity, nanoData.pressure FROM '${republishTopic}/+'`;
    const checkIoTDataStoreTopic = "datastore"
    const blexIoTDataStoreRule = new iot.CfnTopicRule(this, 'blexIoTDataStoreRule', {
      ruleName: blexIoTDataStoreRuleName,
      topicRulePayload: {
        awsIotSqlVersion: '2016-03-23',
        sql: SQL_IOTDATASTORE,
        ruleDisabled: false,
        actions: [
          { republish: {
            topic: checkIoTDataStoreTopic,
            roleArn: blexDataIoTRuleRole.roleArn
          }},
          {
            s3: {
              bucketName: blexIOTBucket.bucketName,
              roleArn: blexDataIoTRuleRole.roleArn,
              key: '${get(*,"cid")}/${nanoData.DeviceId}/${get(*,"timestamp")}.json'
            }
          }
        ]
      }
    })


    new cdk.CfnOutput(this, 'AwsProjectRegion', { value: stack.region })
    new cdk.CfnOutput(this, 'AwsCognitoPoolId', { value: identityPool.ref })
    new cdk.CfnOutput(this, 'AwsCognitoRegion', { value: stack.region})
    new cdk.CfnOutput(this, 'AwsUserPoolId', { value: userPool.userPoolId })
    new cdk.CfnOutput(this, 'AwsUserPoolClientID', { value: userPoolClient.userPoolClientId })
    new cdk.CfnOutput(this, 'AwsIoTPolicy', { value: iotPolicyName })

  }
}
