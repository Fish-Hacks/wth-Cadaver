/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Transfer service and characteristics UUIDs
*/

import Foundation
import CoreBluetooth

struct TransferService {
	static let serviceUUID = CBUUID(string: "FF2FA15F-6AB6-4C29-82D7-3D7194CD250B")
	static let characteristicUUID = CBUUID(string: "784B8D42-3C48-4A4E-B0C6-E6186B019E85")
}

enum DataToReceive {
    case shutDownVision
    case enableVision
    case simulatePointRead(String)
    case simulateTap(String)
    case resetToNormal
    
    init?(rawValue: Int, string: String) {
        switch rawValue {
        case 0: 
            self = .shutDownVision
        case 1:
            self = .enableVision
        case 2:
            self = .simulatePointRead(string)
        case 3:
            self = .simulateTap(string)
        case 4:
            self = .resetToNormal
        default: return nil
        }
    }
}
