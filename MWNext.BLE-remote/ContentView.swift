//
//  ContentView.swift
//  MWNext-BLE-remote
//
//  Created by Nicolas LEFEBVRE on 11/9/21.
//

import SwiftUI
import CoreBluetooth

enum LightModes: UInt8, CaseIterable, Identifiable {
    case steady = 1
    case pulse
    case candle
    case strobe
    case flicker
    case water
    
    var id: UInt8 { self.rawValue }
}
	
// NB: removing some of the boring ones from the UI; careful when sending values...
enum wallLightModes: String, CaseIterable, Identifiable {
    case steady // technically mode 8 on the controller - again, careful later when coding this up!
    //    case cycle
    case wave
    // case sequential
    case glow
    // case chase // basically the same thing as twinkle
    case fade
    case twinkle
    
    var id: String { self.rawValue }
}

let FastLEDHueGradient = Gradient(colors: [
    .red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink, .red
])

struct LightControlView : View {
    @ObservedObject var device: LightDevice
    
    @State private var whiteMode = false
    
    var body: some View {
                
        Section() {
            if (device.name != nil && device.type != nil && device.mode != nil) {
                Toggle(isOn: $device.isOn) { Text(device.name!)
                        .fontWeight(.heavy)
                }
                if (device.isOn) {
                    if (device.type != 3) {
                        if (device.hue != nil && device.saturation != nil && device.cycleColor != nil) {
                            VStack {
                                Slider(value: Binding($device.hue)!.double, in: 0...255)
                                    .background(LinearGradient(gradient: FastLEDHueGradient, startPoint: .leading, endPoint: .trailing).cornerRadius(/*@START_MENU_TOKEN@*/10.0/*@END_MENU_TOKEN@*/))
                                    .disabledAndGreyedOut(device.cycleColor! || whiteMode || (device.type! == 1 && device.mode == 6))
                                
                                HStack {
                                    Toggle("Rainbow", isOn: Binding($device.cycleColor)!).disabled(whiteMode).onChange(of: device.cycleColor) { _cycleColor in
                                        whiteMode = false
                                    }.disabledAndGreyedOut(device.type! == 1 && device.mode == 6)
                                    Divider()
                                    Toggle("White", isOn: $whiteMode).disabled(device.cycleColor!).onChange(of: whiteMode) { _isOn in
                                        device.cycleColor = false
                                        device.saturation = _isOn ? 0 : 255
                                    }.disabledAndGreyedOut(device.type! == 1 && device.mode == 6)
                                }
                            }
                        }
                        
                        Picker(selection: Binding($device.mode)!, label: Text("Mode")) {
                            if (device.type == 1) { // NB: .tag's type MUST match the binding's type, or everything will fail silently, which is fun
                                //Text("off").tag(UInt8(0))
                                Text("steady").tag(UInt8(1))
                                Text("pulse").tag(UInt8(2))
                                Text("candle").tag(UInt8(3))
                                Text("strobe").tag(UInt8(4))
                                Text("flicker").tag(UInt8(5))
                                Text("water").tag(UInt8(6))
                            }
                            else if (device.type == 2) {
                                Text("steady").tag(UInt8(8))
                                //Text("off").tag(UInt8(0))
                                //Text("cycle").tag(UInt8(1))
                                Text("wave").tag(UInt8(2))
                                //Text("sequential").tag(UInt8(3))
                                Text("glow").tag(UInt8(4))
                                //Text("chase").tag(UInt8(5))
                                Text("fade").tag(UInt8(6))
                                Text("twinkle").tag(UInt8(7))
                            }
                        }.pickerStyle(SegmentedPickerStyle())
                    }
                }
            }
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
            //            Text("Freyja's Castle").font(.largeTitle)
            Form {
                LightControlView(device: devices.getDeviceByUUID(MWNEXT_BLE_WINDOWS_SERVICE_UUID))
                LightControlView(device: devices.getDeviceByUUID(MWNEXT_BLE_CLOUDS_SERVICE_UUID))
                LightControlView(device: devices.getDeviceByUUID(MWNEXT_BLE_WALLS_SERVICE_UUID))
                LightControlView(device: devices.getDeviceByUUID(MWNEXT_BLE_MOAT_SERVICE_UUID))
                LightControlView(device: devices.getDeviceByUUID(MWNEXT_BLE_STARS_SERVICE_UUID))
            }
            .alert("Bluetooth required.", isPresented: $mwNextMgr.bluetoothUnavailable, actions: {} , message: { Text("Please enable Bluetooth for \(Bundle.main.displayName) in Settings.") })
            .alert("Bluetooth required.", isPresented: $mwNextMgr.bluetoothOff, actions: {} , message: { Text("Please turn Bluetooth On in Settings.") })
            //.navigationTitle("Freyja's Castle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Freyja's Castle").font(.title)
                        Spacer()
                        if (mwNextMgr.connected) {
                            Label("Connected", systemImage: "wifi")
                                .labelStyle(.titleAndIcon)
                                .foregroundColor(.green)
                        } else {
                            Label("Disconnected", systemImage: "wifi.slash")
                                .labelStyle(.titleAndIcon)
                                .foregroundColor(.red)
                        }
                    }
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
