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
        Task { await server?.addSocket(self, to: room) }
    }

    public func leave(_ room: String) {
        Task { await server?.removeSocket(self, from: room) }
    }

    public func emit(event: String, data: Any...) {
        emit(event: event, payload: SocketIOPayload(values: data))
    }

    public func emitWithAck(event: String, data: Any...) async -> [Any] {
//        withCheckedContinuation { continuation in
//            
//        }
        // TODO
        []
    }

    public func disconnect() {
        Task {
            await resetHandlers()
            await client.disconnect()
        }
    }

    public func setUserInfoValue(_ value: Any?, forKey key: String) async {
        await state.setUserInfoValue(SocketUserInfoValue(value), forKey: key)
    }

    public func removeUserInfoValue(forKey key: String) async {
        await state.setUserInfoValue(nil, forKey: key)
    }

    public func getUserInfoValue(forKey key: String) async -> SocketUserInfoValue? {
        await state.getUserInfoValue(forKey: key)
    }

    public func getUserInfo() async -> [String: SocketUserInfoValue] {
        await state.getUserInfo()
    }

    public func onConnection(use handler: @Sendable @escaping () -> Void) {
        Task { await state.setConnectionHandler(handler) }
    }

    public func onDisconnection(use handler: @Sendable @escaping (DisconnectReason) -> Void) {
        Task { await state.setDisconnectionHandler(handler) }
    }

    public func onDisconnection(use handler: @Sendable @escaping (Socket, DisconnectReason) -> Void) {
        Task {
            await state.setDisconnectionHandler { [weak self] reason in
                guard let self else { return }
                handler(self, reason)
            }
        }
    }

    public func onError(use handler: @Sendable @escaping (Error) -> Void) {
        Task { await state.setErrorHandler(handler) }
    }

    public func on(event: String, use handler: @Sendable @escaping ([Any]) -> Void) {
        Task { await state.setEventHandler(handler, for: event) }
    }

    public func on(event: String, use handler: @Sendable @escaping (Socket, [Any]) -> Void) {
        Task {
            await state.setEventHandler({ [weak self] data in
                guard let self else { return }
                handler(self, data)
            }, for: event)
        }
    }

    public func off(event: String) {
        Task { await state.removeEventHandler(for: event) }
    }
}
