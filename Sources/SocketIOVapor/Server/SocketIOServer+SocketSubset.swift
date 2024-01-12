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
    
    var sockets: Set<Socket> { defaultNamespaceMap.sockets }

    var roomMap: [String : Set<String>] { defaultNamespaceMap.roomMap }

    public func getSockets() -> Set<Socket> {
        defaultNamespaceMap.sockets
    }

    public func onConnection(use handler: @escaping (Socket) -> Void) {
        defaultNamespaceMap.socketObservation = handler
    }

    public func use(_ middleware: NamespaceMiddleware) {
        defaultNamespaceMap.middlewares.append(middleware)
    }
}
