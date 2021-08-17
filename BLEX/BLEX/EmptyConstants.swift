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

//
//  Constants.swift
//  BLEX
//
//  Created by Ashu Joshi on 1/9/21.
//

import Foundation
import AWSCore

// Specify the region, for example US East 2 it will AWSRegion.USEast2
let AWS_REGION = AWSRegionType


// This is the endpoint in your AWS IoT console. eg: https://xxxxxxxxxx.iot.<region>.amazonaws.com
// Using the output of the 'aws iot describe-endpoint' provide the MQTT and IOT Endpoints below
let IOT_ENDPOINT = "https://XXXXXXXXXXXXXX-ats.iot.us-yyyy-z.amazonaws.com"
let MQTT_IOT_ENDPOINT = "wss://XXXXXXXXXXXXXX-ats.iot.us-yyyy-z.amazonaws.com"

// Fill the output from CDK Deploy for Cognito Pool ID
let IDENTITY_POOL_ID = ""

// Fill the output for the IoT Policy Name below
let IOT_POLICY = ""

// You can choose to keep the Publish and Subscribe topic used by the iOS app same as below
// Remember to change the IoT Rules and Actions if you change these to listen to the right topics
let IOT_PUBLISH_TOPIC = "blex"
let IOT_SUBSCRIBE_TOPIC = "blex/command"

//Used as keys to look up a reference of each manager
let AWS_IOT_DATA_MANAGER_KEY = "bleIoTData"
let AWS_IOT_MANAGER_KEY = "bleIoTManager"
