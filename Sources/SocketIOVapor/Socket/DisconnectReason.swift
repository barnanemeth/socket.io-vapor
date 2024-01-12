//
//  DisconnectReason.swift
//
//
//  Created by Barna Nemeth on 04/01/2024.
//

import Foundation

public enum DisconnectReason {
    case forcefully
    case pingTimeout
    case transportClose
    case transportError(Error)
}
