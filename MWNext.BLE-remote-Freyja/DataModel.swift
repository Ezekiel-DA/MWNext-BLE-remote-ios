//
//  DataModel.swift
//  MWNext-BLE-remote
//
//  Created by Nicolas LEFEBVRE on 11/12/21.
//

import Foundation
import CoreBluetooth
import Combine

var _internalID = 0

class LightDevice : ObservableObject, DebugPrintable {
    let uuid: CBUUID
    
    @Published var name: String?
    @Published var type: UInt8?
    @Published var mode: UInt8?
    @Published var hue: UInt8?
    @Published var saturation: UInt8?
    @Published var rainbowMode: Bool?
    
    var isOn: Bool {
        get {
            guard mode != nil else {
                return false
            }
            
            return mode != 0
        }
        
        set(newVal) {
            if (newVal) {
                self.mode = self.type == 2 ? 8 : 1
            } else {
                self.mode = 0
            }
        }
    }
    
    var whiteMode: Bool {
        get {
            guard saturation != nil else { return false }
            
            return saturation == 0
        }
        
        set(isWhite) {
            guard saturation != nil else { return }
            
            saturation = isWhite ? 0 : 255
        }
    }
        
    internal var _modeCharacteristic: CBCharacteristic?
    internal var _hueCharacteristic: CBCharacteristic?
    internal var _saturationCharacteristic: CBCharacteristic?
    internal var _rainbowModeCharacteristic: CBCharacteristic?
    
    private var subscribers: Set<AnyCancellable> = []
    
    init(uuid: CBUUID) {
        self.uuid = uuid
        
        mode = 0
        
        $mode.sink { val in
            guard val != nil && mwNextBLEMgr.mwPeripheral != nil else { return }
            mwNextBLEMgr.mwPeripheral!.writeValue(Data([val!]), for: self._modeCharacteristic!, type: .withResponse)
        }.store(in: &subscribers)

        $hue.sink { val in
            guard val != nil && mwNextBLEMgr.mwPeripheral != nil else { return }
            mwNextBLEMgr.mwPeripheral!.writeValue(Data([val!]), for: self._hueCharacteristic!, type: .withResponse)
        }.store(in: &subscribers)

        $saturation.sink { val in
            guard val != nil && mwNextBLEMgr.mwPeripheral != nil else { return }
            mwNextBLEMgr.mwPeripheral!.writeValue(Data([val!]), for: self._saturationCharacteristic!, type: .withResponse)
        }.store(in: &subscribers)

        $rainbowMode.sink { val in
            guard val != nil && mwNextBLEMgr.mwPeripheral != nil else { return }
            mwNextBLEMgr.mwPeripheral!.writeValue(Data([val! ? 1 : 0]), for: self._rainbowModeCharacteristic!, type: .withResponse)
        }.store(in: &subscribers)
    }
}

struct DeviceList {
    let _devices = [
        LightDevice(uuid: MWNEXT_BLE_WINDOWS_SERVICE_UUID),
        LightDevice(uuid: MWNEXT_BLE_CLOUDS_SERVICE_UUID),
        LightDevice(uuid: MWNEXT_BLE_WALLS_SERVICE_UUID),
        LightDevice(uuid: MWNEXT_BLE_MOAT_SERVICE_UUID),
        LightDevice(uuid: MWNEXT_BLE_STARS_SERVICE_UUID)
    ]
    
    func getDeviceByUUID(_ uuid: CBUUID) -> LightDevice! {
        let deviceIdx = _devices.firstIndex(where: { return $0.uuid == uuid } )
        
        if deviceIdx == nil {
            return nil
        }
        
        return _devices[deviceIdx!]
    }
}

let devices = DeviceList()
