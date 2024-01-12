//
//  Namespace.swift
//
//
//  Created by Barna Nemeth on 30/12/2023.
//

import Foundation

public protocol SocketSubset {
    func getSockets() -> Set<Socket>
    func to(_ subset: String...) -> SocketSubset
    func except(_ subset: String...) -> SocketSubset
    func emit(event: String, data: Any...)
    func disconnectSockets()
}

extension SocketSubset {
    public func emit(event: String, data: Any...) {
        for socket in getSockets() {
            socket.emit(event: event, data: data)
        }
    }

    public func disconnectSockets() {
        for socket in getSockets() {
            socket.disconnect()
        }
    }
}

public protocol Namespace: SocketSubset {
    func onConnection(use handler: @escaping (Socket) -> Void)
    func use(_ middleware: NamespaceMiddleware)
}

protocol InternalNamespace: Namespace {
    var name: String { get }
    var sockets: Set<Socket> { get }
    var roomMap: [String: Set<String>] { get }
}

extension InternalNamespace {
    public func to(_ subset: String...) -> SocketSubset {
        let reducableSubset = ReducableSocketSubset(namespace: name, sockets: sockets, roomMap: roomMap)
        reducableSubset.includedRooms.formUnion(subset)
        return reducableSubset
    }

    public func except(_ subset: String...) -> SocketSubset {
        let reducableSubset = ReducableSocketSubset(namespace: name, sockets: sockets, roomMap: roomMap)
        reducableSubset.exludedRooms.formUnion(subset)
        return reducableSubset
    }
}
