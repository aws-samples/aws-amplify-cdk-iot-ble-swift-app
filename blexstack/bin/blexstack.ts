#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from '@aws-cdk/core';
import { BlexstackStack } from '../lib/blexstack-stack';

const app = new cdk.App();
new BlexstackStack(app, 'BlexstackStack');
