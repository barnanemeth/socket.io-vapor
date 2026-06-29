//
//  NamespaceMap.swift
//
//
//  Created by Barna Nemeth on 04/01/2024.
//

import Foundation

actor NamespaceMap {

    // MARK: Internal properties

    let name: String
    private var sockets = Set<Socket>()
    private var socketObservation: (@Sendable (Socket) -> Void)?
    private var middlewares = [NamespaceMiddleware]()
    private var roomMap = [String: Set<String>]()

    // MARK: Init

    init(name: String, sockets: Set<Socket> = Set<Socket>()) {
        self.name = name
        self.sockets = sockets
        for socket in sockets {
            roomMap[socket.id] = Set(arrayLiteral: socket.id)
        }
    }
}

// MARK: - InternalNamespace

extension NamespaceMap: InternalNamespace {
    func onConnection(use handler: @Sendable @escaping (Socket) -> Void) {
        socketObservation = handler
    }

    func onConnection(use handler: @Sendable @escaping (Namespace, Socket) -> Void) {
        socketObservation = { socket in
            handler(self, socket)
        }
    }

    func getSockets() -> Set<Socket> { sockets }

    func snapshot() -> NamespaceSnapshot {
        NamespaceSnapshot(sockets: sockets, roomMap: roomMap)
    }

    func to(_ subset: String...) async -> SocketSubset {
        let reducableSubset = ReducableSocketSubset(namespace: name, sockets: sockets, roomMap: roomMap)
        await reducableSubset.includeRooms(subset)
        return reducableSubset
    }

    func except(_ subset: String...) async -> SocketSubset {
        let reducableSubset = ReducableSocketSubset(namespace: name, sockets: sockets, roomMap: roomMap)
        await reducableSubset.excludeRooms(subset)
        return reducableSubset
    }

    func use(_ middleware: NamespaceMiddleware) {
        middlewares.append(middleware)
    }
}

// MARK: - Internal methods

extension NamespaceMap {
    func addSocket(_ socket: Socket) async throws {
        for middleware in middlewares {
            try await middleware.respond(to: socket)
        }

        sockets.insert(socket)
        roomMap[socket.id] = Set(arrayLiteral: socket.id)
        socketObservation?(socket)
    }

    func removeSocket(_ socket: Socket) {
        sockets.remove(socket)
        roomMap.removeValue(forKey: socket.id)
    }

    func addSocket(_ socket: Socket, to room: String) {
        if var socketIDs = roomMap[room] {
            socketIDs.insert(socket.id)
            roomMap[room] = socketIDs
        } else {
            roomMap[room] = Set(arrayLiteral: socket.id)
        }
    }

    func removeSocket(_ socket: Socket, from room: String) {
        guard var socketIDs = roomMap[room] else { return }
        socketIDs.remove(socket.id)
        roomMap[room] = socketIDs
    }

    func containsSocket(engineClientID: String) -> Bool {
        sockets.contains(where: { $0.engineClientID == engineClientID })
    }
}

// MARK: - Hashable & Equatable

extension NamespaceMap: Hashable, Equatable {
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    nonisolated static func == (lhs: NamespaceMap, rhs: NamespaceMap) -> Bool {
        lhs.name == rhs.name
    }
}
