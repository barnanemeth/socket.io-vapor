//
//  Socket+Helpers.swift
//
//
//  Created by Barna Nemeth on 10/01/2024.
//

import Foundation
import Vapor
import EngineIO

extension Socket {
    func resetPendingPacketState() {
        pendingPacketState = nil
    }

    func getBinaryAttachments(for data: Any...) -> [ByteBuffer] {
        data.compactMap { $0 as? ByteBuffer }
    }

    func getPacketsForBinaryEvent(event: String, binaryAttachments: [ByteBuffer], data: Any...) -> [any Packet] {
        let transformedData = data.reduce(into: (binaryAttachmentCount: 0, data: [Any]()), { acc, dataItem in
            guard dataItem is ByteBuffer else { return acc.data.append(dataItem) }
            acc.data.append([
                BinaryAttachmentPlaceholderKeys.placeholder: true,
                BinaryAttachmentPlaceholderKeys.number: acc.binaryAttachmentCount
            ])
            acc.binaryAttachmentCount += 1
        }).data
        let packet = SocketIOPacket(
            socketIOType: .binaryEvent,
            namespace: namespace,
            numberOfBinaryAttachments: binaryAttachments.count,
            payload: [event] + transformedData
        )
        return [packet] + binaryAttachments.map { BinaryPacket(byteBuffer: $0) }
    }

    func getPacketForSimpleEvent(event: String, data: Any...) -> any Packet {
        SocketIOPacket(socketIOType: .event, namespace: namespace, payload: [event] + data)
    }

    func broadcastEmit(event: String, data: Any...) {
        
    }
}
