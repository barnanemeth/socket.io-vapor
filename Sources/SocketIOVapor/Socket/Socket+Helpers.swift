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
    func resetPendingPacketState() async {
        await state.resetPendingPacketState()
    }

    func getBinaryAttachments(for data: Any...) -> [ByteBuffer] {
        getBinaryAttachments(for: SocketIOPayload(values: data))
    }

    func getBinaryAttachments(for payload: SocketIOPayload) -> [ByteBuffer] {
        payload.values.compactMap { $0 as? ByteBuffer }
    }

    func getPacketsForBinaryEvent(event: String, binaryAttachments: [ByteBuffer], data: Any...) -> [any Packet] {
        getPacketsForBinaryEvent(event: event, binaryAttachments: binaryAttachments, payload: SocketIOPayload(values: data))
    }

    func getPacketsForBinaryEvent(event: String, binaryAttachments: [ByteBuffer], payload: SocketIOPayload) -> [any Packet] {
        let transformedData = payload.values.reduce(into: (binaryAttachmentCount: 0, data: [Any]()), { acc, dataItem in
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
        getPacketForSimpleEvent(event: event, payload: SocketIOPayload(values: data))
    }

    func getPacketForSimpleEvent(event: String, payload: SocketIOPayload) -> any Packet {
        SocketIOPacket(socketIOType: .event, namespace: namespace, payload: [event] + payload.values)
    }

    func emit(event: String, payload: SocketIOPayload) {
        let binaryAttachments = getBinaryAttachments(for: payload)
        if binaryAttachments.count > .zero {
            let packets = getPacketsForBinaryEvent(event: event, binaryAttachments: binaryAttachments, payload: payload)
            Task { await client.sendPackets(packets) }
        } else {
            let packet = getPacketForSimpleEvent(event: event, payload: payload)
            Task { await client.sendPacket(packet) }
        }
    }

    func resetHandlers() async {
        await state.resetHandlers()
    }
}
