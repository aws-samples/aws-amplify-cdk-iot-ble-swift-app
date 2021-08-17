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
//  ViewController.swift
//  BLEX
// 	
//  Created by Joshi, Ashu on 10/19/20.
//

import UIKit
import CoreBluetooth
import AWSIoT
import AWSMobileClient

struct NANOBLESENSESENSORS: Codable {
    let ax: Float
    let ay: Float
    let az: Float
    let gx: Float
    let gy: Float
    let gz: Float
    let mx: Float
    let my: Float
    let mz: Float
    let pressure: Float
    let temperature: Float
    let humidity: Float
    let DeviceId: String
}
struct messageData: Codable {
    var nanoData: NANOBLESENSESENSORS
    var timestamp: Int64
}

struct iotCommand: Codable {
    let Command: String
}

class ViewController: UIViewController {

    @IBOutlet weak var dataCaptureControlButton: UIButton!
    @IBOutlet weak var deviceSacnControlButton: UIButton!
    
    var blePoweredOn = false
    var deviceScanningStatus = false
    var dataCaptureStatus = false
    var mqttConnected = false
    var iotDataManager: AWSIoTDataManager!
    var iotManager: AWSIoTManager!
    var iot: AWSIoT!
    var clientId: String!
    var attachedPolicyToCognitoID: AWSIoTListAttachedPoliciesRequest!
    var policyResponse: AWSIoTListAttachedPoliciesResponse!
    var attachCognitoIdToPolicy: AWSIoTAttachPolicyRequest!

    @IBOutlet weak var blePeripheralsTableView: UITableView!
    
    var centralManager: CBCentralManager!
    var bleConnectedSensor: CBPeripheral!
    var bleSensorWriteCharacterstic: CBCharacteristic!
    var bleSensorReadCharacterstic: CBCharacteristic!

    let activityIndicatorView = UIActivityIndicatorView(style: .large)

    
    var blePeripherals = [CBPeripheral](){
        didSet {
            DispatchQueue.main.async {
                self.blePeripheralsTableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        activityIndicatorView.frame = view.frame
        activityIndicatorView.hidesWhenStopped = true
        
        dataCaptureControlButton.isEnabled = false

        centralManager = CBCentralManager(delegate: self, queue: nil)
        centralManager.delegate = self
        self.initAWSIoT()
        
        // Initialize the Class AWSIoTListAttachedPoliciesRequest to request attached policies
        // for the Cognito ID associated with the authenticated user.
        self.attachedPolicyToCognitoID = AWSIoTListAttachedPoliciesRequest.init()
        self.attachedPolicyToCognitoID.target = self.clientId
        
        iot.listAttachedPolicies(self.attachedPolicyToCognitoID).continueWith(block: { (task) -> AnyObject? in
            if (task.error != nil) {
                print("Error: ")
                print(task.error as Any)
                print("Failed to list attached policues")
            }
            else {
                print("No Error in Task for getting policies")
                self.policyResponse = task.result!
                print(self.policyResponse.policies?.count as Any)
                if (self.policyResponse.policies?.count == 0) {
                    print("No Cognito ID attached to the Policy")
                    self.attachCognitoIdToPolicy = AWSIoTAttachPolicyRequest.init()
                    self.attachCognitoIdToPolicy.policyName = IOT_POLICY
                    self.attachCognitoIdToPolicy.target = self.clientId
                    self.iot.attachPolicy(self.attachCognitoIdToPolicy).continueWith(block: { (task) -> AnyObject? in
                        print(task.error as Any)
                        if (task.error != nil) {
                            print("Error: ")
                            print(task.error as Any)
                            print("Attach Failed")
                        }
                        else {
                            print("Attaching Cognito ID to Policy Success")
                            self.mqttConnect()
                        }
                        return task;
                    })
                } else {
                    print("Cognito ID already attached to Policy")
                    self.mqttConnect()
                }
            }
            return task;
        })
    }

    func showAlertWithTitle(_ title: String, message: String? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: false)
    }

    func showActivityIndicator() {
        self.view.addSubview(activityIndicatorView)
        self.activityIndicatorView.startAnimating()
        
    }
    
    func hideActivityIndicator() {
        DispatchQueue.main.async {
            self.activityIndicatorView.stopAnimating()
        }
    }

    
    @IBAction func deviceScanningControl(_ sender: Any) {
        if blePoweredOn == true && deviceScanningStatus == false {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            deviceSacnControlButton.setTitle("Stop Device Scan", for: UIControl.State.normal)
            deviceScanningStatus = true
            
        } else if blePoweredOn == true && deviceScanningStatus == true {
            centralManager.stopScan()
            deviceScanningStatus = false
            deviceSacnControlButton.setTitle("Start Device Scan", for: UIControl.State.normal)
        }
    }
    
    
    @IBAction func dataCaptureControl(_ sender: Any) {
        if dataCaptureStatus == false {
//            let message = "Start"
//            let d1 = NSData(bytes: message, length: message.count)
//            self.bleConnectedSensor.writeValue(d1 as Data, for: self.bleSensorWriteCharacterstic, type: CBCharacteristicWriteType.withoutResponse)
//            dataCaptureStatus = true

            self.startCapture()
            dataCaptureControlButton.setTitle("Stop Data Capture", for: UIControl.State.normal)
            
        } else if dataCaptureStatus == true {
            
//            let message = "Stop"
//            let d1 = NSData(bytes: message, length: message.count)
//            self.bleConnectedSensor.writeValue(d1 as Data, for: self.bleSensorWriteCharacterstic, type: CBCharacteristicWriteType.withoutResponse)
//            dataCaptureStatus = false
//            dataCaptureControlButton.setTitle("Start Data Capture", for: UIControl.State.normal)
            self.stopCapture()
            dataCaptureControlButton.setTitle("Start Data Capture", for: UIControl.State.normal)


        }
    }
    
    func startCapture() {
        let message = "Start"
        let d1 = NSData(bytes: message, length: message.count)
        self.bleConnectedSensor.writeValue(d1 as Data, for: self.bleSensorWriteCharacterstic, type: CBCharacteristicWriteType.withoutResponse)
        self.dataCaptureStatus = true
    }
    
    func stopCapture() {
        
        let message = "Stop"
        let d1 = NSData(bytes: message, length: message.count)
        self.bleConnectedSensor.writeValue(d1 as Data, for: self.bleSensorWriteCharacterstic, type: CBCharacteristicWriteType.withoutResponse)
        self.dataCaptureStatus = false
        
    }
    
    
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        blePeripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = blePeripherals[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedBLEPeripheral = blePeripherals[indexPath.row]
        print(selectedBLEPeripheral)
        centralManager.connect(selectedBLEPeripheral, options: nil)

    }
}

extension ViewController: CBCentralManagerDelegate, CBPeripheralDelegate {
 
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            print("BLE powered on")
            // Turned on
            blePoweredOn = true
//            central.scanForPeripherals(withServices: nil, options: nil)

        }
        else {
            print("Something wrong with BLE")
            // Not on, but can have different issues
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi   RSSI: NSNumber) {
        
        if peripheral.name != nil && !blePeripherals.contains(peripheral) {
            print("Name: \(String(describing: peripheral.name)), ID: \(peripheral.identifier)")
            blePeripherals.append(peripheral)
        }
        
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        if (blePeripherals.contains(peripheral)) {
            print("Peripheral found in array: \(peripheral.name as Any), and connected.")
            bleConnectedSensor = peripheral
            centralManager.stopScan()
            self.deviceScanningStatus = false
            self.deviceSacnControlButton.setTitle("Start Device Scan", for: UIControl.State.normal)
            // Start discovering services for this peripheral
            bleConnectedSensor.delegate = self

            self.showActivityIndicator()
            bleConnectedSensor.discoverServices(nil)

        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if (peripheral == bleConnectedSensor) {
            if let services = bleConnectedSensor.services {
                for service in services {
                    print("Service:: \(service)")
                    print("Service found:\(service.uuid.uuidString) for device \(peripheral.name as Any) \n")
                    bleConnectedSensor.discoverCharacteristics(nil, for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (peripheral == bleConnectedSensor) {
            if let characteristics = service.characteristics {
                for characteristic in characteristics {
                    print("Characteristic found:\(characteristic.uuid.uuidString) for Service:\(service.uuid.uuidString) for device \(peripheral.name as Any)")
                    print(characteristic.uuid.uuidString)

                    if (characteristic.uuid == CBUUID(string: WRITE_CHARACTERSTIC)) {
                        print("Discovered Write Characterstic")
                        self.bleSensorWriteCharacterstic = characteristic
//                        self.dataCaptureControlButton.isEnabled = true
                    }

                    if (characteristic.uuid == CBUUID(string: READ_CHARACTERSTIC)) {
                        print("Discovered Read Characterstic")
                        self.bleConnectedSensor.setNotifyValue(true, for: characteristic)
                        self.bleSensorReadCharacterstic = characteristic
                    }
                }
                // Hide activity indicator after both characterstics have been discovered.
                self.hideActivityIndicator()
                self.dataCaptureControlButton.isEnabled = true
            }
        }
    }
    
    func parseBLEData(sensorData: NSData) {
        let decoder = JSONDecoder()
        guard let blenanosensordata = try? decoder.decode(NANOBLESENSESENSORS.self, from: sensorData as Data) else {
            print("Error converting to JSON decoder")
            return
        }
        let timestamp = Date().currentTimeMillis()
        if mqttConnected {
            let encoder = JSONEncoder()
            guard let message = try? encoder.encode(messageData(nanoData: blenanosensordata, timestamp: timestamp)) else {
                print("Error in encoding")
                return
            }
            iotDataManager.publishData(message as Data, onTopic: IOT_PUBLISH_TOPIC, qoS: .messageDeliveryAttemptedAtMostOnce)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if peripheral == bleConnectedSensor {
            let sensorData = characteristic.value! as NSData
            parseBLEData(sensorData: sensorData)
        }
    }
}

extension ViewController {
    
    private func initAWSIoT() {
        print("Initializing AWS IoT")
        let iotEndPoint = AWSEndpoint(
            urlString: MQTT_IOT_ENDPOINT)
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWS_REGION, identityPoolId: IDENTITY_POOL_ID)
        
        
        // Retrieve your Amazon Cognito ID
        credentialsProvider.getIdentityId().continueWith(block: { (task) -> AnyObject? in
            if (task.error != nil) {
                print("Error: ")
                print(task.error as Any)
            }
            else {
                // the task result will contain the identity id
                let cognitoId = task.result!
                print("Cognito id: \(cognitoId)")
            }
            return task;
        })
        
        self.clientId = credentialsProvider.identityId
        print(self.clientId as Any)
        
        //Initialize control plane
        // Initialize the Amazon Cognito credentials provider
        let controlPlaneServiceConfiguration = AWSServiceConfiguration(region:AWS_REGION, credentialsProvider:credentialsProvider)
        
        //IoT control plane seem to operate on iot.<region>.amazonaws.com
        //Set the defaultServiceConfiguration so that when we call AWSIoTManager.default(), it will get picked up
        AWSServiceManager.default().defaultServiceConfiguration = controlPlaneServiceConfiguration
        self.iotManager = AWSIoTManager.default()
        self.iot = AWSIoT.default()

        let iotDataConfiguration = AWSServiceConfiguration(
            region: AWSRegionType.USEast2,
            endpoint: iotEndPoint,
            credentialsProvider: AWSMobileClient.default()
        )
        AWSIoTDataManager.register(with: iotDataConfiguration!, forKey: AWS_IOT_DATA_MANAGER_KEY)
        self.iotDataManager = AWSIoTDataManager(forKey: AWS_IOT_DATA_MANAGER_KEY)
    }
    
    private func mqttConnect() {
        print("Connecting to MQTT ...")
        self.iotDataManager.connectUsingWebSocket(withClientId: self.clientId, cleanSession: true, statusCallback: mqttEventCallback(_:))
    }
    
    private func mqttEventCallback( _ status: AWSIoTMQTTStatus ) {
        DispatchQueue.main.async {
            print("connection status = \(status.rawValue)")

            switch status {
            case .connecting:
                print("Connecting...")
                print("connection status = \(status.rawValue)")
                
            case .connected:
                print("ConnectED")
                print("connection status = \(status.rawValue)")
                self.mqttConnected = true
                self.iotDataManager.subscribe(toTopic: IOT_SUBSCRIBE_TOPIC, qoS: .messageDeliveryAttemptedAtMostOnce, messageCallback: self.mqttMessageReceivedCallback(payload:))
                
            case .disconnected:
                print("DISConnectED")
                print("connection status = \(status.rawValue)")

                self.mqttConnected = false
                
            case .connectionRefused:
                print("CONNECTION REFUSED")
                print("connection status = \(status.rawValue)")

            case .connectionError:
                print("Conn Error")
                print("connection status = \(status.rawValue)")

            case .protocolError:
                print("Protocol Error")
                print("connection status = \(status.rawValue)")

                
            default:
                print("Somehow in DEFAULT CASE")
                print("unknown state: \(status.rawValue)")
            }
            
        }
    }
    
    private func mqttMessageReceivedCallback(payload: Data) {
        let stringValue = NSString(data: payload, encoding: String.Encoding.utf8.rawValue)!
        print("Message received: \(stringValue)")
        
        let decoder = JSONDecoder()
        guard let command = try? decoder.decode(iotCommand.self, from: payload as Data) else {
            print("Error converting to JSON decoder")
            return
        }
        
        print(command.Command)
        
        if (command.Command == "Start") {
            print("Starting Capture")
            self.startCapture()
            DispatchQueue.main.async {
                self.dataCaptureControlButton.setTitle("Stop Data Capture", for: UIControl.State.normal)
            }

        }
        
        if (command.Command == "Stop") {
            print("Stopping Capture")
            self.stopCapture()
            DispatchQueue.main.async {
                self.dataCaptureControlButton.setTitle("Start Data Capture", for: UIControl.State.normal)
            }
        }
        

    }
 

}

extension Date {
    func currentTimeMillis() -> Int64 {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
}
