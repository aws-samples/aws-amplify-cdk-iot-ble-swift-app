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

/*
 * nanoblesense
 * BLE Interface
 * 
 * Arduino script to demonstrate BLE data exchange
 * with an iOS application.
 * 
 * Author:  Ashu Joshi
 * October 2020
 * 
 */

#include "constants.h"
#include <ArduinoBLE.h>
#include <Arduino_LSM9DS1.h>
#include <Arduino_LPS22HB.h>
#include <Arduino_HTS221.h>
#include <ArduinoJson.h>
const float CALIBRATION_FACTOR = -4.0; // Temperature calibration factor (celsius)

// BLE Service
BLEService nanoService(uuidOfService);

// Setup the incoming data characteristic (RX).
const int WRITE_BUFFER_SIZE = 256;
bool WRITE_BUFFER_FIZED_LENGTH = false;

// RX / TX Characteristics
BLECharacteristic rxChar(uuidOfRxChar, BLEWriteWithoutResponse | BLEWrite, WRITE_BUFFER_SIZE, WRITE_BUFFER_FIZED_LENGTH);
BLECharacteristic txChar(uuidOfTxChar, BLERead | BLENotify | BLEBroadcast, 256);

// Buffer to read samples into, each sample is 16-bits
char sampleBuffer[256];

// Number of samples read
volatile int samplesRead;

String bleAddress;

bool captureReadings = false;

struct imudata {
  float ax;
  float ay;
  float az;
  float gx;
  float gy;
  float gz;
  float mx;
  float my;
  float mz;
};


void setup() {
  // Start serial.
  Serial.begin(9600);

  // Ensure serial port is ready.
  // Comment out the next line if you want to
  // run the Nano without it being connected to
  // a PC/Mac/Linux with a microusb cable.
  while (!Serial);

  // Prepare LED pins.
  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(LEDR, OUTPUT);
  pinMode(LEDG, OUTPUT);

  startIMU();

  Serial.println("Init Pressure Sensor - LPS22HB");
  if (!BARO.begin()) {
    Serial.println("Failed to initialize pressure sensor!");
    while (1);
  }

  Serial.println("Init Temp & Humi Sensor - HTS221");
  if (!HTS.begin()) {  // Initialize HTS22 sensor
    Serial.println("Failed to initialize humidity temperature sensor!");
    while (1);
  }

  // Start BLE.
  startBLE();

  bleAddress = BLE.address();
  Serial.print("Local address is: ");
  Serial.println(bleAddress);

  // Create BLE service and characteristics.
  BLE.setLocalName(nameOfPeripheral);
  BLE.setDeviceName(nameOfPeripheral);
  BLE.setAdvertisedService(nanoService);
  nanoService.addCharacteristic(rxChar);
  nanoService.addCharacteristic(txChar);
  BLE.addService(nanoService);

  // Bluetooth LE connection handlers.
  BLE.setEventHandler(BLEConnected, onBLEConnected);
  BLE.setEventHandler(BLEDisconnected, onBLEDisconnected);
  
  // Event driven reads.
  rxChar.setEventHandler(BLEWritten, onRxCharValueUpdate);
  
  // Let's tell devices about us.
  BLE.advertise();
  
  // Print out full UUID and MAC address.
  Serial.println("Peripheral advertising info: ");
  Serial.print("Name: ");
  Serial.println(nameOfPeripheral);
  Serial.print("MAC: ");
  Serial.println(BLE.address());
  Serial.print("Service UUID: ");
  Serial.println(nanoService.uuid());
  Serial.print("rxCharacteristic UUID: ");
  Serial.println(uuidOfRxChar);
  Serial.print("txCharacteristics UUID: ");
  Serial.println(uuidOfTxChar);

  Serial.println("Bluetooth device active, waiting for connections...");
} // End of setup()

// rounds a number to 2 decimal places
// example: round(3.14159) -> 3.14
double round2(double value) {
   return (int)(value * 100 + 0.5) / 100.0;
}

void loop() {
  BLEDevice central = BLE.central();
  if (central && central.connected()) {
    connectedLight();
    if (captureReadings) {

      StaticJsonDocument<256> doc;
      imudata imuData;
      readIMU(&imuData);

      doc["ax"] = round2(imuData.ax);
      doc["ay"] = round2(imuData.ay);
      doc["az"] = round2(imuData.az);

      doc["gx"] = round2(imuData.gx);
      doc["gy"] = round2(imuData.gy);
      doc["gz"] = round2(imuData.gz);

      doc["mx"] = round2(imuData.mx);
      doc["my"] = round2(imuData.my);
      doc["mz"] = round2(imuData.mz);

      float pressure = BARO.readPressure();
//      doc["temperature"] = getTemperature(CALIBRATION_FACTOR);
      doc["temperature"] = round2(HTS.readTemperature() + CALIBRATION_FACTOR);
//      doc["humidity"] = getHumidity();
      doc["humidity"] = round2(HTS.readHumidity());
      doc["pressure"] = round2(pressure);
//      doc["DeviceId"] = serialized(bleAddress);
      doc["DeviceId"] = bleAddress;

      char buffer[256];
      size_t n = serializeJson(doc, buffer);
      txChar.writeValue(buffer, n);      
      serializeJson(doc, Serial);
      Serial.println();

            
  } else {
    disconnectedLight();
  }
 }
  delay(1000);
}


/* 
 * LSM9DS1 
 */

void startIMU() {

  if (!IMU.begin()) {
    Serial.println("Failed to initialize IMU!");
    while (1);
  }

  Serial.print("Accelerometer sample rate = ");
  Serial.print(IMU.accelerationSampleRate());
  Serial.println(" Hz");
  Serial.println("Acceleration in G's");
  Serial.println();

  Serial.print("Gyroscope sample rate = ");
  Serial.print(IMU.gyroscopeSampleRate());
  Serial.println(" Hz");
  Serial.println("Gyroscope in degrees/second");
  Serial.println();

  Serial.print("Magnetic field sample rate = ");
  Serial.print(IMU.magneticFieldSampleRate());
  Serial.println(" uT");
  Serial.println("Magnetic Field in uT");
  Serial.println();
  
}

void readIMU(struct imudata *imuData) {
  float x, y, z;
  
  if (IMU.accelerationAvailable()) {
    IMU.readAcceleration(x, y, z);
    
    Serial.print(x);
    Serial.print('\t');
    Serial.print(y);
    Serial.print('\t');
    Serial.println(z);

    imuData->ax = x;
    imuData->ay = y;
    imuData->az = z;
    
  }

  if (IMU.gyroscopeAvailable()) {
    IMU.readGyroscope(x, y, z);

    Serial.print(x);
    Serial.print('\t');
    Serial.print(y);
    Serial.print('\t');
    Serial.println(z);

    imuData->gx = x;
    imuData->gy = y;
    imuData->gz = z;
  }

  if (IMU.magneticFieldAvailable()) {
    IMU.readMagneticField(x, y, z);

    Serial.print(x);
    Serial.print('\t');
    Serial.print(y);
    Serial.print('\t');
    Serial.println(z);
    
    imuData->mx = x;
    imuData->my = y;
    imuData->mz = z;
  }
  
}


int getTemperature(float calibration) {
  // Get calibrated temperature as signed 16-bit int for BLE characteristic
  return (int) (HTS.readTemperature() * 100) + (int) (calibration * 100);
}

unsigned int getHumidity() {
  // Get humidity as unsigned 16-bit int for BLE characteristic
  return (unsigned int) (HTS.readHumidity() * 100);
}

/*
 *  BLUETOOTH
 */
void startBLE() {
  if (!BLE.begin())
  {
    Serial.println("starting BLE failed!");
    while (1);
  }
}

void onRxCharValueUpdate(BLEDevice central, BLECharacteristic characteristic) {
  // central wrote new value to characteristic, update LED
  Serial.print("Characteristic event, read: ");
  byte test[256];
  int dataLength = rxChar.readValue(test, 256);
  
  String data;
  for(int i = 0; i < dataLength; i++) {
    Serial.print((char)test[i]);
    data += (char)test[i];
  }
  Serial.println();
//  String data;
//  for (char c : test) data += c;
  Serial.println(data);
  Serial.println(data.length());

  if (data == "Start") {
    captureReadings = true;  
  }

  if (data == "Stop") {
    captureReadings = false;  
  }


  Serial.print("Value length = ");
  Serial.println(rxChar.valueLength());
}

void onBLEConnected(BLEDevice central) {
  Serial.print("Connected event, central: ");
  Serial.println(central.address());
  connectedLight();
  captureReadings = false;
}

void onBLEDisconnected(BLEDevice central) {
  Serial.print("Disconnected event, central: ");
  Serial.println(central.address());
  disconnectedLight();
  captureReadings = false;
}

/*
 * LEDS
 */
void connectedLight() {
  digitalWrite(LEDR, LOW);
  digitalWrite(LEDG, HIGH);
}


void disconnectedLight() {
  digitalWrite(LEDR, HIGH);
  digitalWrite(LEDG, LOW);
}
