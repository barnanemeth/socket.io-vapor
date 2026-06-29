//
//  Namespace.swift
//
//
//  Created by Barna Nemeth on 30/12/2023.
//

import Foundation

public protocol SocketSubset: AnyObject, Sendable {
    func getSockets() async -> Set<Socket>
    func to(_ subset: String...) async -> SocketSubset
    func except(_ subset: String...) async -> SocketSubset
    func emit(event: String, data: Any...) async
    func disconnectSockets() async
}

extension SocketSubset {
    public func emit(event: String, data: Any...) async {
        let payload = SocketIOPayload(values: data)
        for socket in await getSockets() {
            socket.emit(event: event, payload: payload)
        }
    }

    public func disconnectSockets() async {
        for socket in await getSockets() {
            socket.disconnect()
        }
    }
}

public protocol Namespace: SocketSubset {
    func onConnection(use handler: @Sendable @escaping (Socket) -> Void) async
    func onConnection(use handler: @Sendable @escaping (Namespace, Socket) -> Void) async
    func use(_ middleware: NamespaceMiddleware) async
}

protocol InternalNamespace: Namespace, Actor {
    var name: String { get }
    func snapshot() async -> NamespaceSnapshot
}

struct NamespaceSnapshot: Sendable {
    let sockets: Set<Socket>
    let roomMap: [String: Set<String>]
}

extension InternalNamespace {
    public func to(_ subset: String...) async -> SocketSubset {
        let snapshot = await snapshot()
        let reducableSubset = ReducableSocketSubset(namespace: name, sockets: snapshot.sockets, roomMap: snapshot.roomMap)
        await reducableSubset.includeRooms(subset)
        return reducableSubset
    }

    public func except(_ subset: String...) async -> SocketSubset {
        let snapshot = await snapshot()
        let reducableSubset = ReducableSocketSubset(namespace: name, sockets: snapshot.sockets, roomMap: snapshot.roomMap)
        await reducableSubset.excludeRooms(subset)
        return reducableSubset
    }
}
