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
    public func join(_ room: String) {
        server?.addSocket(self, to: room)
    }

    public func leave(_ room: String) {
        server?.removeSocket(self, from: room)
    }

    public func emit(event: String, data: Any...) {
        let binaryAttachments = getBinaryAttachments(for: data)
        if binaryAttachments.count > .zero {
            let packets = getPacketsForBinaryEvent(event: event, binaryAttachments: binaryAttachments, data: data)
            Task { await client.sendPackets(packets) }
        } else {
            Task { await client.sendPacket(getPacketForSimpleEvent(event: event, data: data)) }
        }
    }

    public func emitWithAck(event: String, data: Any...) async -> [Any] {
        // TODO
        []
    }

    public func disconnect() {
        Task { await client.disconnect() }
    }

    public func onConnection(use handler: @escaping () -> Void) {
        connectionHandler = handler
    }

    public func onDisconnection(use handler: @escaping (DisconnectReason) -> Void) {
        disconnectionHandler = handler
    }

    public func onDisconnection(use handler: @escaping (Socket, DisconnectReason) -> Void) {
        disconnectionHandler = { [weak self] reason in
            guard let self else { return }
            handler(self, reason)
        }
    }

    public func onError(use handler: @escaping (Error) -> Void) {
        errorHandler = handler
    }

    public func on(event: String, use handler: @escaping ([Any]) -> Void) {
        messageHandlers[event] = handler
    }

    public func on(event: String, use handler: @escaping (Socket, [Any]) -> Void) {
        messageHandlers[event] = { [weak self] data in
            guard let self else { return }
            handler(self, data)
        }
    }

    public func off(event: String) {
        messageHandlers.removeValue(forKey: event)
    }
}
