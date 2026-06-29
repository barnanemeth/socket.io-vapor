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

    func snapshot() async -> NamespaceSnapshot {
        await defaultNamespaceMap.snapshot()
    }

    public func getSockets() async -> Set<Socket> {
        await defaultNamespaceMap.getSockets()
    }

    public func onConnection(use handler: @Sendable @escaping (Socket) -> Void) async {
        await defaultNamespaceMap.onConnection(use: handler)
    }

    public func onConnection(use handler: @Sendable @escaping (Namespace, Socket) -> Void) async {
        await defaultNamespaceMap.onConnection(use: handler)
    }

    public func use(_ middleware: NamespaceMiddleware) async {
        await defaultNamespaceMap.use(middleware)
    }
}
