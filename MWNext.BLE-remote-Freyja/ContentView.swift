//
//  ContentView.swift
//  MWNext-BLE-remote
//
//  Created by Nicolas LEFEBVRE on 11/9/21.
//

import SwiftUI
import CoreBluetooth

struct TopStatusBar: View {
    var connected: Bool
    var tagPresent: Bool
    var tagWriteRequest: Bool // gross, we should probably just hold a reference to the costume controller itself instead of this + accessing it directly
    
    var width: CGFloat = 100.0
    
    var body: some View {
        HStack {
            if (connected) {
                Label("Connected", systemImage: "wifi")
                    .labelStyle(.titleAndIcon)
                    .foregroundColor(.green)
                    .font(.footnote)
                    .frame(width: width)
            } else {
                Label("Scanning...", systemImage: "wifi.slash")
                    .labelStyle(.titleAndIcon)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            Spacer()
            Text("Freyja's Castle").font(.title2)
            Spacer()
            Button(!tagPresent ? "No tag..." : (tagWriteRequest ? "Writing..." : "Write tag")) {
                print("Requested tag write")
                costumeController.tagWriteRequest = true
            }
            .font(.footnote)
            .frame(width: width)
            .buttonStyle(.borderedProminent)
            .disabled(!tagPresent || tagWriteRequest)
        }
    }
}

struct ContentView: View {
    @ObservedObject var _mwNextMgr: MWNextBLEManager = mwNextBLEMgr
    @ObservedObject var _costumeController: CostumeController = costumeController
    var centralManager: CBCentralManager!
    
    init() {
        centralManager = CBCentralManager(delegate: _mwNextMgr, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        UITableView.appearance().tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 10))
    }
    
    var body: some View {
        NavigationView {
            if (!_mwNextMgr.connected) {
                Text(_mwNextMgr.bluetoothOff ? "Please turn Bluetooth on in Settings." : (_mwNextMgr.bluetoothUnavailable ? "Please allow \(Bundle.main.displayName) access to Bluetooth" : "Please turn on costume or programming device") )
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .principal) { TopStatusBar(connected: _mwNextMgr.connected, tagPresent: costumeController.tagPresent, tagWriteRequest: _costumeController.tagWriteRequest) } }
            } else {
                Form {
                    LightControlView(device: costumeController.getDeviceByUUID(MWNEXT_BLE_WINDOWS_SERVICE_UUID))
                    LightControlView(device: costumeController.getDeviceByUUID(MWNEXT_BLE_CLOUDS_SERVICE_UUID))
                    LightControlView(device: costumeController.getDeviceByUUID(MWNEXT_BLE_WALLS_SERVICE_UUID))
                    LightControlView(device: costumeController.getDeviceByUUID(MWNEXT_BLE_MOAT_SERVICE_UUID))
                    LightControlView(device: costumeController.getDeviceByUUID(MWNEXT_BLE_STARS_SERVICE_UUID))
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .principal) { TopStatusBar(connected: _mwNextMgr.connected, tagPresent: _costumeController.tagPresent, tagWriteRequest: _costumeController.tagWriteRequest) } }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
