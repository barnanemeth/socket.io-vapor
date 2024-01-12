//
//  Error+Extensions.swift
//
//
//  Created by Barna Nemeth on 12/01/2024.
//

import Foundation

extension Error {
    func toSocketIOPacket(namespace: String) -> SocketIOPacket {
        SocketIOPacket(
            socketIOType: .connectError,
            namespace: namespace,
            payload: ["message": localizedDescription]
        )
    }
}
