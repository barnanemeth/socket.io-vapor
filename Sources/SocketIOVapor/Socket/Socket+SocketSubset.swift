//
//  Socket+SocketSubset.swift
//
//
//  Created by Barna Nemeth on 10/01/2024.
//

import Foundation

extension Socket: SocketSubset {
    public func getSockets() -> Set<Socket> {
        server?.getNamespace(for: namespace)?.getSockets().subtracting([self]) ?? []
    }

    public func to(_ subset: String...) -> SocketSubset {
        let reducableSubset = ReducableSocketSubset(
            namespace: namespace,
            sockets: getSockets(),
            roomMap: server!.getNamespace(for: namespace)!.roomMap
        )
        reducableSubset.includedRooms.formUnion(subset)
        return reducableSubset
    }

    public func except(_ subset: String...) -> SocketSubset {
        let reducableSubset = ReducableSocketSubset(
            namespace: namespace,
            sockets: getSockets(),
            roomMap: server!.getNamespace(for: namespace)!.roomMap
        )
        reducableSubset.exludedRooms.formUnion(subset)
        return reducableSubset
    }
}
