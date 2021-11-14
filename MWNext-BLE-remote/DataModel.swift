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
    @Published var cycleColor: Bool?
    
    private var subscribers: Set<AnyCancellable> = []
    
    var _id = 0;
    
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
    
    init(uuid: CBUUID) {
        self.uuid = uuid
        
        mode = 0
        
        self._id = _internalID
        _internalID += 1
        
        $mode.sink { mode in
            print("mode change: \(String(describing: mode))")
        }.store(in: &subscribers)
        
        $hue.sink { hue in
            print("hue change: \(String(describing: hue))")
        }.store(in: &subscribers)
        
        $saturation.sink { saturation in
            print("saturation change: \(String(describing: saturation))")
        }.store(in: &subscribers)
        
        $cycleColor.sink { cycleColor in
            print("cycleColor change: \(String(describing: cycleColor))")
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
