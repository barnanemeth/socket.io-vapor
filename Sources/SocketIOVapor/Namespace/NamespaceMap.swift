//
//  NamespaceMap.swift
//
//
//  Created by Barna Nemeth on 04/01/2024.
//

import Foundation

actor NamespaceMap: Sendable {

    // MARK: Internal properties

    nonisolated let name: String
    var sockets = Set<Socket>()
    var socketObservation: ((Socket) async -> Void)?
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
    func onConnection(use handler: @escaping (Socket) async -> Void) {
        socketObservation = handler
    }

    func onConnection(use handler: @escaping (any Namespace, Socket) async -> Void) {
        socketObservation = { [weak self] socket in
            guard let self else { return }
            await handler(self, socket)
        }
    }

    func getSockets() async -> Set<Socket> { sockets }

    func to(_ subset: String...) async -> any SocketSubset {
        let reducableSubset = ReducableSocketSubset(namespace: name, sockets: sockets, roomMap: roomMap)
        await reducableSubset.addToIncludedRooms(subset)
        return reducableSubset
    }

    func except(_ subset: String...) async -> any SocketSubset {
        let reducableSubset = ReducableSocketSubset(namespace: name, sockets: sockets, roomMap: roomMap)
        await reducableSubset.addToExcludedRooms(subset)
        return reducableSubset
    }

    func use(_ middleware: NamespaceMiddleware) {
        middlewares.append(middleware)
    }
}

// MARK: - Internal methods

extension NamespaceMap {
    func setSocketObservation(_ socketObservation: ((Socket) async -> Void)?) {
        self.socketObservation = socketObservation
    }

    func addMiddleware(_ middleware: NamespaceMiddleware) {
        middlewares.append(middleware)
    }

    func addSocket(_ socket: Socket) async throws {
        for middleware in middlewares {
            try await middleware.respond(to: socket)
        }
        let oldSockets = sockets
        sockets.insert(socket)
        await calculateSetDifference(oldValue: oldSockets)
        roomMap[socket.id] = Set(arrayLiteral: socket.id)
    }

    func removeSocket(_ socket: Socket) async {
        let oldSockets = sockets
        sockets.remove(socket)
        await calculateSetDifference(oldValue: oldSockets)
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

    func isContainSocketWithClientID(_ engineID: String) async -> Bool {
        await getSockets().contains(where: { $0.client.id == engineID })
    }
}

// MARK: - Hashable & Equatable

extension NamespaceMap: Hashable, Equatable {
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    static func == (lhs: NamespaceMap, rhs: NamespaceMap) -> Bool {
        lhs.name == rhs.name
    }
}

// MARK: - Helpers

extension NamespaceMap {
    private func calculateSetDifference(oldValue: Set<Socket>) async {
        let newSockets = sockets.subtracting(oldValue)
        for socket in newSockets {
            await socketObservation?(socket)
        }
    }
}
