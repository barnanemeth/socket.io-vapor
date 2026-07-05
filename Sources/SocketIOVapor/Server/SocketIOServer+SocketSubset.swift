//
//  SocketIOServer+SocketSubset.swift
//
//
//  Created by Barna Nemeth on 04/01/2024.
//

import Foundation

// MARK: - InternalNamespace

extension SocketIOServer: InternalNamespace {
    var name: String { Constant.defaultNamespace }
    
    var sockets: Set<Socket> {
        get async { await defaultNamespaceMap.sockets }
    }

    var roomMap: [String : Set<String>] {
        get async { await defaultNamespaceMap.roomMap }
    }

    public func getSockets() async -> Set<Socket> {
        await defaultNamespaceMap.sockets
    }

    public func onConnection(use handler: @Sendable @escaping (Socket) async -> Void) async {
        await defaultNamespaceMap.setSocketObservation(handler)
    }

    public func onConnection(use handler: @Sendable @escaping (any Namespace, Socket) async -> Void) async {
        let handler: (@Sendable (Socket) async -> Void)  = { socket in
            await handler(self, socket)
        }
        await defaultNamespaceMap.setSocketObservation(handler)
    }

    public func use(_ middleware: NamespaceMiddleware) async {
        await defaultNamespaceMap.addMiddleware(middleware)
    }
}
