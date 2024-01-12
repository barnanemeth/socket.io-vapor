//
//  ReducableSocketSubset.swift
//
//
//  Created by Barna Nemeth on 04/01/2024.
//

import Foundation

final class ReducableSocketSubset {

    // MARK: Internal properties

    let namespace: String
    let sockets: Set<Socket>
    let roomMap: [String: Set<String>]
    var includedRooms = Set<String>()
    var exludedRooms = Set<String>()

    // MARK: Init

    init(namespace: String, sockets: Set<Socket>, roomMap: [String: Set<String>]) {
        self.namespace = namespace
        self.sockets = sockets
        self.roomMap = roomMap
    }
}

// MARK: - SocketSubset

extension ReducableSocketSubset: SocketSubset {
    public func getSockets() -> Set<Socket> {
        var sockets = sockets
        if !includedRooms.isEmpty {
            let socketIDs = includedRooms.flatMap { roomMap[$0] ?? [] }
            sockets = sockets.filter { socket in
                socketIDs.contains(where: { $0 == socket.id })
            }
        } else if !exludedRooms.isEmpty {
            let socketIDs = exludedRooms.flatMap { roomMap[$0] ?? [] }
            sockets = sockets.filter { socket in
                !socketIDs.contains(where: { $0 == socket.id })
            }
        }
        return sockets
    }

    public func to(_ subset: String...) -> SocketSubset {
        includedRooms.formUnion(subset)
        return self
    }
    
    public func except(_ subset: String...) -> SocketSubset {
        exludedRooms.formUnion(subset)
        return self
    }
}
