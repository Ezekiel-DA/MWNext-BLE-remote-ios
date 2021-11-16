//
//  LightControlView.swift
//  MWNext-BLE-remote
//
//  Created by Nicolas LEFEBVRE on 11/15/21.
//

import SwiftUI

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
                                    .background(LinearGradient(gradient: FastLEDHueGradient, startPoint: .leading, endPoint: .trailing)).clipShape(Capsule())
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

struct LightControlView_Previews: PreviewProvider {
    
    static var previews: some View {
        let testDevice = LightDevice(uuid: MWNEXT_BLE_WINDOWS_SERVICE_UUID)
        testDevice.mode = 1
        testDevice.name = "Test"
        testDevice.type = 1
        testDevice.hue = 255
        testDevice.saturation = 0
        testDevice.cycleColor = false
        
        return LightControlView(device: testDevice)
    }
}
