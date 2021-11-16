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
    
    var width: CGFloat = 100.0
    
    var body: some View {
        HStack {
            if (connected) {
                Label("Connected", sys	temImage: "wifi")
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
            Button(connected ? "Write tag" : "No tag...") {
                print("Todo: write to tag!")
            }
            .font(.footnote)
            .frame(width: width)
            .buttonStyle(.borderedProminent)
            .disabled(!connected)
        }
    }
}

struct ContentView: View {
    @ObservedObject var mwNextMgr = MWNextBLEManager()
    var centralManager: CBCentralManager!
    
    init() {
        centralManager = CBCentralManager(delegate: mwNextMgr, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        UITableView.appearance().tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 10))
    }
    
    var body: some View {
        NavigationView {
            Form {
                LightControlView(device: devices.getDeviceByUUID(MWNEXT_BLE_WINDOWS_SERVICE_UUID))
                LightControlView(device: devices.getDeviceByUUID(MWNEXT_BLE_CLOUDS_SERVICE_UUID))
                LightControlView(device: devices.getDeviceByUUID(MWNEXT_BLE_WALLS_SERVICE_UUID))
                LightControlView(device: devices.getDeviceByUUID(MWNEXT_BLE_MOAT_SERVICE_UUID))
                LightControlView(device: devices.getDeviceByUUID(MWNEXT_BLE_STARS_SERVICE_UUID))
            }
            .alert("Bluetooth required.", isPresented: $mwNextMgr.bluetoothUnavailable, actions: {} , message: { Text("Please enable Bluetooth for \(Bundle.main.displayName) in Settings.") })
            .alert("Bluetooth required.", isPresented: $mwNextMgr.bluetoothOff, actions: {} , message: { Text("Please turn Bluetooth On in Settings.") })
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    TopStatusBar(connected: mwNextMgr.connected)
                }
            }
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
