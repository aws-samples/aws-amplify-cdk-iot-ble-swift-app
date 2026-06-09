import { App } from 'aws-cdk-lib';
import { Template } from 'aws-cdk-lib/assertions';
import { BlexstackStack } from '../lib/blexstack-stack';

test('Stack creates resources', () => {
    const app = new App();
    const stack = new BlexstackStack(app, 'MyTestStack');
    const template = Template.fromStack(stack);
    template.resourceCountIs('AWS::Cognito::UserPool', 1);
    template.resourceCountIs('AWS::IoT::Policy', 1);
});
