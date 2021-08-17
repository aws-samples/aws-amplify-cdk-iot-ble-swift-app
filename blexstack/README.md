# Stack

This setups the AWS infrastructure required for the project.
These are the resources it creates and configures them:

1. Cognito User Pool
2. Cognito Identity Pool
3. Authenticated Role - the IAM role that will be assumed by the Authenticated Identity
4. IOT Policy - grants the permissions to the authenticated identity
5. IAM Role for IoT Actions & Rules
6. IOT Rule to republish data ingested from the Smartphone App
7. An S3 Bucket
8. IOT Rule & Action to save data in S3 from the Smartphone App
