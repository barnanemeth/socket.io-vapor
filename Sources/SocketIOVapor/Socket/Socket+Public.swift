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

    public func emit(event: String, data: any Sendable...) async {
        let binaryAttachments = getBinaryAttachments(for: data)
        if binaryAttachments.count > .zero {
            let packets = getPacketsForBinaryEvent(event: event, binaryAttachments: binaryAttachments, data: data)
            await client.sendPackets(packets)
        } else {
            let packet = getPacketForSimpleEvent(event: event, data: data)
            await client.sendPacket(packet)
        }
    }

    public func disconnect() async {
        resetHandlers()
        await client.disconnect()
    }

    public func onConnection(use handler: @escaping () -> Void) {
        connectionHandler = handler
    }

    public func onDisconnection(use handler: @Sendable @escaping (DisconnectReason) async -> Void) {
        disconnectionHandler = handler
    }

    public func onDisconnection(use handler: @Sendable @escaping (Socket, DisconnectReason) async -> Void) {
        disconnectionHandler = { [weak self] reason in
            guard let self else { return }
            await handler(self, reason)
        }
    }

    public func onError(use handler: @Sendable @escaping (Error) async -> Void) {
        errorHandler = handler
    }

    public func on(event: String, use handler: @Sendable @escaping ([any Sendable]) async -> Void) {
        eventHandlers[event] = handler
    }

    public func on(event: String, use handler: @Sendable @escaping (Socket, [any Sendable]) async -> Void) {
        eventHandlers[event] = { [weak self] data in
            guard let self else { return }
            await handler(self, data)
        }
    }

    public func off(event: String) {
        eventHandlers.removeValue(forKey: event)
    }

    public func getUserInfo() -> [String: any Sendable] {
        userInfo
    }

    public func setUserInfo(_ userInfo: [String: any Sendable]) {
        self.userInfo = userInfo
    }
}
