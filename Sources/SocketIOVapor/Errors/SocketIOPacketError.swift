//
//  SocketIOPacketError.swift
//
//
//  Created by Barna Nemeth on 30/12/2023.
//

import Foundation

enum SocketIOPacketError: Error {
    case invalidPacketFormat
    case invalidEncapsulatingPacket
}
