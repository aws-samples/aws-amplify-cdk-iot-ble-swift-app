#!/usr/bin/env node
import 'source-map-support/register';
import { App } from 'aws-cdk-lib';
import { BlexstackStack } from '../lib/blexstack-stack';

const app = new App();
new BlexstackStack(app, 'BlexstackStack');
