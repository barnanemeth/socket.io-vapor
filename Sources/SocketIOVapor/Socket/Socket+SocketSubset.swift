//
//  Socket+SocketSubset.swift
//
//
//  Created by Barna Nemeth on 10/01/2024.
//

import Foundation

extension Socket: SocketSubset {    
    public func getSockets()  async -> Set<Socket> {
        await server?.getNamespace(for: namespace)?.getSockets().subtracting([self]) ?? []
    }

    public func to(_ subset: String...) async -> any SocketSubset {
        let reducableSubset = await ReducableSocketSubset(
            namespace: namespace,
            sockets: getSockets(),
            roomMap: server!.getNamespace(for: namespace)!.roomMap
        )
        await reducableSubset.addToIncludedRooms(subset)
        return reducableSubset
    }

    public func except(_ subset: String...) async -> any SocketSubset {
        let reducableSubset = await ReducableSocketSubset(
            namespace: namespace,
            sockets: getSockets(),
            roomMap: server!.getNamespace(for: namespace)!.roomMap
        )
        await reducableSubset.addToExcludedRooms(subset)
        return reducableSubset
    }
}
