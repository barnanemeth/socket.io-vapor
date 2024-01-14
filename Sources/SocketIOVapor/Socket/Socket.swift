//
//  Socket.swift
//
//
//  Created by Barna Nemeth on 30/12/2023.
//

import Foundation
import EngineIO

public final class Socket {

    // MARK: Public properties

    public let id = UUID().uuidString
    public let client: Client
    public lazy var broadcast = { Broadcast(socket: self) }()
    public var userInfo: [String: Any] = [:]

    // MARK: Internal properties

    let namespace: String
    var connectionHandler: (() -> Void)?
    var disconnectionHandler: ((DisconnectReason) -> Void)?
    var errorHandler: ((Error) -> Void)?
    var eventHandlers = [String: ([Any]) -> Void]()
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
