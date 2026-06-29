//
//  Socket+SocketSubset.swift
//
//
//  Created by Barna Nemeth on 10/01/2024.
//

import Foundation

extension Socket: SocketSubset {
    public func getSockets() async -> Set<Socket> {
        guard let namespaceMap = await server?.getNamespace(for: namespace) else { return [] }
        return await namespaceMap.getSockets().subtracting([self])
    }

    public func to(_ subset: String...) async -> SocketSubset {
        guard let namespaceMap = await server?.getNamespace(for: namespace) else {
            let reducableSubset = ReducableSocketSubset(namespace: namespace, sockets: [], roomMap: [:])
            await reducableSubset.includeRooms(subset)
            return reducableSubset
        }

        let snapshot = await namespaceMap.snapshot()
        let reducableSubset = ReducableSocketSubset(
            namespace: namespace,
            sockets: snapshot.sockets.subtracting([self]),
            roomMap: snapshot.roomMap
        )
        await reducableSubset.includeRooms(subset)
        return reducableSubset
    }

    public func except(_ subset: String...) async -> SocketSubset {
        guard let namespaceMap = await server?.getNamespace(for: namespace) else {
            let reducableSubset = ReducableSocketSubset(namespace: namespace, sockets: [], roomMap: [:])
            await reducableSubset.excludeRooms(subset)
            return reducableSubset
        }

        let snapshot = await namespaceMap.snapshot()
        let reducableSubset = ReducableSocketSubset(
            namespace: namespace,
            sockets: snapshot.sockets.subtracting([self]),
            roomMap: snapshot.roomMap
        )
        await reducableSubset.excludeRooms(subset)
        return reducableSubset
    }
}
