//
//  Namespace.swift
//
//
//  Created by Barna Nemeth on 30/12/2023.
//

import Foundation

public protocol SocketSubset: Actor {
    func getSockets() async -> Set<Socket>
    func to(_ subset: String...) async -> any SocketSubset
    func except(_ subset: String...) async -> any SocketSubset
    func emit(event: String, data: any Sendable...) async
    func disconnectSockets() async
}

extension SocketSubset {
    public func emit(event: String, data: any Sendable...) async {
        for socket in await getSockets() {
            await socket.emit(event: event, data: data)
        }
    }

    public func disconnectSockets() async {
        for socket in await getSockets() {
            await socket.disconnect()
        }
    }
}

public protocol Namespace: SocketSubset {
    func onConnection(use handler: @Sendable @escaping (Socket) async -> Void) async
    func onConnection(use handler: @Sendable @escaping (any Namespace, Socket) async -> Void) async
    func use(_ middleware: NamespaceMiddleware) async
}

protocol InternalNamespace: Namespace {
    var name: String { get }
    var sockets: Set<Socket> { get async }
    var roomMap: [String: Set<String>] { get async }
}

extension InternalNamespace {
    public func to(_ subset: String...) async -> any SocketSubset {
        let reducableSubset = await ReducableSocketSubset(namespace: name, sockets: sockets, roomMap: roomMap)
        await reducableSubset.addToIncludedRooms(subset)
        return reducableSubset
    }

    public func except(_ subset: String...) async -> any SocketSubset {
        let reducableSubset = await ReducableSocketSubset(namespace: name, sockets: sockets, roomMap: roomMap)
        await reducableSubset.addToExcludedRooms(subset)
        return reducableSubset
    }
}
