//
//  Socket+Extensions.swift
//
//
//  Created by Barna Nemeth on 02/01/2024.
//

import Foundation
import Vapor
import EngineIO

// MARK: - Public methods

extension Socket {
    public func join(_ room: String) async {
        await server?.addSocket(self, to: room)
    }

    public func leave(_ room: String) async {
        await server?.removeSocket(self, from: room)
    }

    public func emit(event: String, data: any Sendable...) {
        let binaryAttachments = getBinaryAttachments(for: data)
        if binaryAttachments.count > .zero {
            let packets = getPacketsForBinaryEvent(event: event, binaryAttachments: binaryAttachments, data: data)
            Task { [client] in await client.sendPackets(packets) }
        } else {
            let packet = getPacketForSimpleEvent(event: event, data: data)
            Task { [client] in await client.sendPacket(packet) }
        }
    }

//    public func emitWithAck(event: String, data: Any...) async -> [Any] {
//        []
//    }

    public func disconnect() {
        resetHandlers()
        Task { [client] in await client.disconnect() }
    }

    public func onConnection(use handler: @escaping () -> Void) {
        connectionHandler = handler
    }

    public func onDisconnection(use handler: @Sendable @escaping (DisconnectReason) -> Void) {
        disconnectionHandler = handler
    }

    public func onDisconnection(use handler: @Sendable @escaping (Socket, DisconnectReason) -> Void) {
        disconnectionHandler = { [weak self] reason in
            guard let self else { return }
            handler(self, reason)
        }
    }

    public func onError(use handler: @Sendable @escaping (Error) -> Void) {
        errorHandler = handler
    }

    public func on(event: String, use handler: @Sendable @escaping ([Any]) -> Void) {
        eventHandlers[event] = handler
    }

    public func on(event: String, use handler: @Sendable @escaping (Socket, [Any]) -> Void) {
        eventHandlers[event] = { [weak self] data in
            guard let self else { return }
            handler(self, data)
        }
    }

    public func off(event: String) {
        eventHandlers.removeValue(forKey: event)
    }
}
