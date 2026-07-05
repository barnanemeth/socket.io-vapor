//
//  Socket.swift
//
//
//  Created by Barna Nemeth on 30/12/2023.
//

import Foundation
import EngineIO

public actor Socket: Sendable {

    // MARK: Public properties

    nonisolated public let id = UUID().uuidString
    nonisolated public let client: Client
    public lazy var broadcast = { Broadcast(socket: self) }()
    public var userInfo: [String: any Sendable] = [:]

    // MARK: Internal properties

    nonisolated let namespace: String
    var connectionHandler: (() -> Void)?
    var disconnectionHandler: (@Sendable (DisconnectReason) -> Void)?
    var errorHandler: (@Sendable (Error) -> Void)?
    var eventHandlers = [String: @Sendable ([any Sendable]) -> Void]()
    var pendingPacketState: PendingPacketState?
    weak var server: SocketIOServer?

    // MARK: Init

    init(client: Client, namespace: String, server: SocketIOServer) {
        self.client = client
        self.namespace = namespace
        self.server = server
    }
}

// MARK: - Hashable

extension Socket: Hashable, Equatable {
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Socket, rhs: Socket) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - CustomStringConvertible

extension Socket: CustomStringConvertible {
    nonisolated public var description: String { id }
}
