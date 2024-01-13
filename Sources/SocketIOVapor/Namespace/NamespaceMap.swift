//
//  NamespaceMap.swift
//
//
//  Created by Barna Nemeth on 04/01/2024.
//

import Foundation

final class NamespaceMap {

    // MARK: Internal properties

    let name: String
    var sockets = Set<Socket>() {
        didSet { calculateSetDifference(oldValue: oldValue) }
    }
    var socketObservation: ((Socket) -> Void)?
    var middlewares = [NamespaceMiddleware]()
    var roomMap = [String: Set<String>]()

    // MARK: Init

    init(name: String, sockets: Set<Socket> = Set<Socket>()) {
        self.name = name
        self.sockets = sockets
    }
}

// MARK: - InternalNamespace

extension NamespaceMap: InternalNamespace {
    func onConnection(use handler: @escaping (Socket) -> Void) {
        socketObservation = handler
    }

    func onConnection(use handler: @escaping (Namespace, Socket) -> Void) {
        socketObservation = { [weak self] socket in
            guard let self else { return }
            handler(self, socket)
        }
    }

    func getSockets() -> Set<Socket> { sockets }

    func to(_ subset: String...) -> SocketSubset {
        let reducableSubset = ReducableSocketSubset(namespace: name, sockets: sockets, roomMap: roomMap)
        reducableSubset.includedRooms.formUnion(subset)
        return reducableSubset
    }

    func except(_ subset: String...) -> SocketSubset {
        let reducableSubset = ReducableSocketSubset(namespace: name, sockets: sockets, roomMap: roomMap)
        reducableSubset.exludedRooms.formUnion(subset)
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
}

// MARK: - Hashable & Equatable

extension NamespaceMap: Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    static func == (lhs: NamespaceMap, rhs: NamespaceMap) -> Bool {
        lhs.name == rhs.name
    }
}

// MARK: - Helpers

extension NamespaceMap {
    private func calculateSetDifference(oldValue: Set<Socket>) {
        let newSockets = sockets.subtracting(oldValue)
        newSockets.forEach { socketObservation?($0) }
    }
}
