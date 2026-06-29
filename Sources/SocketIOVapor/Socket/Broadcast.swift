//
//  Broadcast.swift
//
//
//  Created by Barna Nemeth on 10/01/2024.
//

import Foundation

public struct Broadcast: Sendable {

    // MARK: Private properties

    private let socket: Socket

    // MARK: Init

    init(socket: Socket) {
        self.socket = socket
    }
}

// MARK: - Public methods

extension Broadcast {
    public func emit(event: String, data: Any...) {
        let payload = SocketIOPayload(values: data)
        Task { await socket.server?.broadcastEmit(from: socket, event: event, payload: payload) }
    }
}
