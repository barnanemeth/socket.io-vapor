//
//  SocketIOPacketType.swift
//  
//
//  Created by Barna Nemeth on 30/12/2023.
//

import Foundation

enum SocketIOPacketType: Character, Sendable {
    case connect = "0"
    case disconnect = "1"
    case event = "2"
    case ack = "3"
    case connectError = "4"
    case binaryEvent = "5"
    case binaryAck = "6"
}
