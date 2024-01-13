//
//  DisconnectReason.swift
//
//
//  Created by Barna Nemeth on 04/01/2024.
//

import Foundation
import EngineIO

public enum DisconnectReason {
    case forcefully
    case pingTimeout
    case transportClose
}

extension EngineIO.DisconnectReason {
    var disconnectReason: DisconnectReason {
        switch self {
        case .forcefully: return .forcefully
        case .invalidPacket, .invalidSession, .invalidState: return .transportClose
        case .pingTimeout: return .pingTimeout
        }
    }
}
