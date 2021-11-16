//
//  BLE.swift
//  MWNext-BLE-remote
//
//  Created by Nicolas LEFEBVRE on 11/12/21.
//

import Foundation
import CoreBluetooth

// Identification service; doesn't do anything, but is advertised so we can find the peripheral
let MWNEXT_BLE_COSTUME_CONTROL_SERVICE_UUID     = CBUUID(string: "47191881-ebb3-4a9f-9645-3a5c6dae4900")

// Light control services for various on-board devices
let MWNEXT_BLE_WINDOWS_SERVICE_UUID             = CBUUID(string: "c3f48cdf-18bb-4947-bef2-f804d59d74da")
let MWNEXT_BLE_CLOUDS_SERVICE_UUID              = CBUUID(string: "f248fd08-0326-482e-b023-db6e3f6bb250")
let MWNEXT_BLE_WALLS_SERVICE_UUID               = CBUUID(string: "b3701981-4955-49d5-bd2d-e2ea57e8e64c")
let MWNEXT_BLE_MOAT_SERVICE_UUID                = CBUUID(string: "5180f077-a430-4a6d-b6ea-cdf1075a0dd9")
let MWNEXT_BLE_STARS_SERVICE_UUID               = CBUUID(string: "c634d6bf-0f7b-4580-b342-7aa2d42dedab")

// Characteristics exposed by the light control services
let MWNEXT_BLE_DEVICE_TYPE_CHARACTERISTIC_UUID  = CBUUID(string: "8106f98f-fb24-4b97-a995-47a1695cea75")
let MWNEXT_BLE_MODE_CHARACTERISTIC_UUID         = CBUUID(string: "b54fc13b-4374-4a6f-861f-dd198f88f299")
let MWNEXT_BLE_HUE_CHARACTERISTIC_UUID          = CBUUID(string: "19dfe175-aa12-404b-843d-b625937cffff")
let MWNEXT_BLE_CYCLE_COLOR_CHARACTERISTIC_UUID  = CBUUID(string: "dfe34849-2d42-4222-b6b1-617a4f4d0869")
let MWNEXT_BLE_SATURATION_CHARACTERISTIC_UUID   = CBUUID(string: "946d22e6-2b2f-49e7-b941-150b023f2261")

// As far as I can tell CoreBluetooth doesn't define constants for the official SIG UUIDs?
let SIG_BLE_OBJECTNAME_CHARACTERISTIC_UUID      = CBUUID(string: "0x2ABE")

let allMWNextLightControlServiceUUIDs = [
    MWNEXT_BLE_WINDOWS_SERVICE_UUID,
    MWNEXT_BLE_CLOUDS_SERVICE_UUID,
    MWNEXT_BLE_WALLS_SERVICE_UUID,
    MWNEXT_BLE_MOAT_SERVICE_UUID,
    MWNEXT_BLE_STARS_SERVICE_UUID
]

let allMWNextLightControlCharacteristicUUIDs = [
    SIG_BLE_OBJECTNAME_CHARACTERISTIC_UUID,
    MWNEXT_BLE_DEVICE_TYPE_CHARACTERISTIC_UUID,
    MWNEXT_BLE_MODE_CHARACTERISTIC_UUID,
    MWNEXT_BLE_HUE_CHARACTERISTIC_UUID,
    MWNEXT_BLE_CYCLE_COLOR_CHARACTERISTIC_UUID,
    MWNEXT_BLE_SATURATION_CHARACTERISTIC_UUID
]

class MWNextBLEManager : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject {
    var mwPeripheral: CBPeripheral?
    
    @Published var bluetoothUnavailable = false
    @Published var bluetoothOff = false
    @Published var connected = false
    
    @Published var tagPresent = false
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("BLE Central ready, scanning...")
            bluetoothOff = false
            central.scanForPeripherals(withServices: [MWNEXT_BLE_COSTUME_CONTROL_SERVICE_UUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        case .unknown:
            print("CBCentralManager state changed to: unknown")
        case .resetting:
            print("reset")
        case .unsupported:
            print("unsupported")
        case .unauthorized:
            print("unauthorized")
            bluetoothUnavailable = true
        case .poweredOff:
            bluetoothOff = true
        @unknown default:
            print("WTF")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.name!)")
        mwPeripheral = nil
        connected = false
        central.scanForPeripherals(withServices: [MWNEXT_BLE_COSTUME_CONTROL_SERVICE_UUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard RSSI.intValue >= -90
        else {
            print("Connection too weak; RSSI is \(RSSI)")
            return
        }
        
        //print("Discovered \(peripheral.name!) at \(RSSI.intValue)")
        
        if ((mwPeripheral == nil)) {
            mwPeripheral = peripheral
            central.connect(peripheral, options: nil)
            print("Connecting to MW peripheral...")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connected = true
        central.stopScan()
        peripheral.delegate = self
        peripheral.discoverServices(allMWNextLightControlServiceUUIDs)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if (error != nil) {
            print(error!)
        }
        
        print("Found MWNext services")
        assert(peripheral.services != nil)
        assert(peripheral.services!.count == allMWNextLightControlServiceUUIDs.count)
        
        for service in peripheral.services! {
            peripheral.discoverCharacteristics(allMWNextLightControlCharacteristicUUIDs, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            let device: LightDevice! = devices.getDeviceByUUID(service.uuid)
            switch characteristic.uuid {
            case MWNEXT_BLE_MODE_CHARACTERISTIC_UUID:
                device._modeCharacteristic = characteristic
            case MWNEXT_BLE_HUE_CHARACTERISTIC_UUID:
                device._hueCharacteristic = characteristic
            case MWNEXT_BLE_CYCLE_COLOR_CHARACTERISTIC_UUID:
                device._rainbowModeCharacteristic = characteristic
            case MWNEXT_BLE_SATURATION_CHARACTERISTIC_UUID:
                device._saturationCharacteristic = characteristic
            default:
                break
            }
            peripheral.setNotifyValue(true, for: characteristic)
            peripheral.readValue(for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        assert(error == nil)
        assert(characteristic.value != nil)
        assert(characteristic.service != nil)
        
        let device = devices.getDeviceByUUID(characteristic.service!.uuid)
        assert(device != nil)
        
        if characteristic.uuid == SIG_BLE_OBJECTNAME_CHARACTERISTIC_UUID { // object name is the only characteristic that needs decoding as a UTF8 string...
            let name = String(decoding: characteristic.value!, as: UTF8.self)
            device!.name = name
        } else { // ... everything else is just a 1 byte value
            assert(characteristic.value!.count == 1)
            let val = characteristic.value!.first!
            
            switch characteristic.uuid {
            case MWNEXT_BLE_DEVICE_TYPE_CHARACTERISTIC_UUID:
                device!.type = val
            case MWNEXT_BLE_MODE_CHARACTERISTIC_UUID:
                device!.mode = val
            case MWNEXT_BLE_HUE_CHARACTERISTIC_UUID:
                device!.hue = val
            case MWNEXT_BLE_SATURATION_CHARACTERISTIC_UUID:
                device!.saturation = val
            case MWNEXT_BLE_CYCLE_COLOR_CHARACTERISTIC_UUID:
                device!.rainbowMode = val != 0
            default:
                assert(false, "Unexpected characteristic")
            }
        }
        
        // print("Device is now: \(device!)")
    }
}
