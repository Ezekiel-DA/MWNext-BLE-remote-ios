//
//  Utils.swift
//  MWNext-BLE-remote
//
//  Created by Nicolas LEFEBVRE on 11/12/21.
//

import Foundation
import SwiftUI

extension Bundle {
    var displayName: String {
        if let name = object(forInfoDictionaryKey: "CFBundleDisplayName") {
            return name as! String
        } else {
            return "?MISSING APP NAME?"
        }
    }
}

// Allows print(\(obj)) to debug print classes the same way it natively does structs
public protocol DebugPrintable : CustomStringConvertible { }

extension DebugPrintable {
    public var description: String {
        let mirror = Mirror(reflecting: self)

        var str = "\(mirror.subjectType)("
        var first = true
        for (label, value) in mirror.children {
          if let label = label {
            if first {
              first = false
            } else {
              str += ", "
            }
            str += label
            str += ": "
            str += "\(value)"
          }
        }
        str += ")"

        return str
    }
}

extension View {
    func disabledAndGreyedOut(_ disabled: Bool) -> some View {
        return self
            .opacity(disabled ? 0.25 : 1.0)
            .disabled(disabled)
    }
}

// This is probably gross, but it lets SwiftUI components that take bindings to Doubles (looking at you Slider) take UInt8 bindings instead!
extension UInt8 {
    var double: Double {
        get { Double(self) }
        set { self = UInt8(newValue) }
    }
}
