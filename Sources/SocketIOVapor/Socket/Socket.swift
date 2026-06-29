//
//  Socket.swift
//
//
//  Created by Barna Nemeth on 30/12/2023.
//

import Foundation
import Vapor
import EngineIO

public struct SocketUserInfoValue: @unchecked Sendable {
    public let value: Any?

    public init(_ value: Any?) {
        self.value = value
    }
}

public final class Socket: @unchecked Sendable {

    // MARK: Typealiases

    typealias ConnectionHandler = @Sendable () -> Void
    typealias DisconnectionHandler = @Sendable (DisconnectReason) -> Void
    typealias ErrorHandler = @Sendable (Error) -> Void
    typealias EventHandler = @Sendable ([Any]) -> Void

    // MARK: Public properties

    public let id = UUID().uuidString
    public let client: EngineIO.Client
    public lazy var broadcast = { Broadcast(socket: self) }()

    // MARK: Internal properties

    let namespace: String
    let engineClientID: String
    let state = SocketState()
    weak var server: SocketIOServer?

    // MARK: Init

    init(client: EngineIO.Client, namespace: String, server: SocketIOServer) {
        self.client = client
        self.namespace = namespace
        self.server = server
        self.engineClientID = client.id
    }
}

// MARK: - Hashable

extension Socket: Hashable, Equatable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Socket, rhs: Socket) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - CustomStringConvertible

extension Socket: CustomStringConvertible {
    public var description: String { id }
}

// MARK: - State

actor SocketState {
    private var connectionHandler: Socket.ConnectionHandler?
    private var disconnectionHandler: Socket.DisconnectionHandler?
    private var errorHandler: Socket.ErrorHandler?
    private var eventHandlers = [String: Socket.EventHandler]()
    private var pendingPacketState: PendingPacketState?
    private var userInfo = [String: SocketUserInfoValue]()

    func setUserInfoValue(_ value: SocketUserInfoValue?, forKey key: String) {
        userInfo[key] = value
    }

    func getUserInfoValue(forKey key: String) -> SocketUserInfoValue? {
        userInfo[key]
    }

    func getUserInfo() -> [String: SocketUserInfoValue] {
        userInfo
    }

    func setConnectionHandler(_ handler: Socket.ConnectionHandler?) {
        connectionHandler = handler
    }

    func setDisconnectionHandler(_ handler: Socket.DisconnectionHandler?) {
        disconnectionHandler = handler
    }

    func setErrorHandler(_ handler: Socket.ErrorHandler?) {
        errorHandler = handler
    }

    func setEventHandler(_ handler: Socket.EventHandler?, for event: String) {
        eventHandlers[event] = handler
    }

    func removeEventHandler(for event: String) {
        eventHandlers.removeValue(forKey: event)
    }

    func callConnectionHandler() {
        connectionHandler?()
    }

    func callDisconnectionHandler(reason: DisconnectReason) {
        disconnectionHandler?(reason)
    }

    func callErrorHandler(error: Error) {
        errorHandler?(error)
    }

    func callEventHandler(event: String, data: [Any]) {
        eventHandlers[event]?(data)
    }

    func setPendingEventPacket(_ packet: SocketIOPacket) -> SocketIOPacket? {
        if pendingPacketState == nil {
            pendingPacketState = PendingPacketState()
        }
        pendingPacketState?.setEventPacket(packet)
        return finalPendingPacketIfReady()
    }

    func appendPendingBinaryPacket(_ byteBuffer: ByteBuffer) -> SocketIOPacket? {
        if pendingPacketState == nil {
            pendingPacketState = PendingPacketState()
        }
        pendingPacketState?.appendBinaryPacket(byteBuffer)
        return finalPendingPacketIfReady()
    }

    func resetPendingPacketState() {
        pendingPacketState = nil
    }

    func resetHandlers() {
        connectionHandler = nil
        disconnectionHandler = nil
        errorHandler = nil
        eventHandlers.removeAll()
        pendingPacketState = nil
    }

    private func finalPendingPacketIfReady() -> SocketIOPacket? {
        guard let finalPacket = pendingPacketState?.getFinalPacket() else { return nil }
        pendingPacketState = nil
        return finalPacket
    }
}
