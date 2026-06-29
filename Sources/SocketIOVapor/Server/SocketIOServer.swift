//
//  SocketIOServer.swift
//
//
//  Created by Barna Nemeth on 30/12/2023.
//

import Foundation
import Vapor
import EngineIO

public actor SocketIOServer {

    // MARK: Inner types

    public struct Configuration: Sendable {
        public static let `default` = Configuration()

        public var path: PathComponent
        public var pingInterval: Int
        public var pingTimeout: Int
        public var maxPayload: Int
        public var addTrailingSlash: Bool
        public var allowEIO3: Bool
        public var allowUpgrades = true
        public var allowRequest: (@Sendable (Request) throws -> Void)?
        public var cookie: CookieOptions?
        public var logLevel: Logger.Level

        public init(path: PathComponent = "socket.io",
                    pingInterval: Int = 3000,
                    pingTimeout: Int = 2000,
                    maxPayload: Int = 1000000,
                    addTrailingSlash: Bool = false,
                    allowEIO3: Bool = false,
                    allowUpgrades: Bool = true,
                    allowRequest: (@Sendable (Request) throws -> Void)? = nil,
                    cookie: CookieOptions? = nil,
                    logLevel: Logger.Level = .error) {
            self.path = path
            self.pingInterval = pingInterval
            self.pingTimeout = pingTimeout
            self.maxPayload = maxPayload
            self.addTrailingSlash = addTrailingSlash
            self.allowEIO3 = allowEIO3
            self.allowUpgrades = allowUpgrades
            self.allowRequest = allowRequest
            self.cookie = cookie
            self.logLevel = logLevel
        }
    }

    // MARK: Constants

    enum Constant {
        static let defaultPath: PathComponent = "socket.io"
        static let defaultNamespace = "/"
    }

    // MARK: Public properties

    public nonisolated let engine: Engine

    // MARK: Internal properties

    private var namespaceMaps: Set<NamespaceMap>
    let defaultNamespaceMap = NamespaceMap(name: Constant.defaultNamespace)

    // MARK: Init

    public init(engine: Engine? = nil, configuration: Configuration = .default) {
        let config = DefaultEngine.Configuration(
            pingInterval: configuration.pingInterval,
            pingTimeout: configuration.pingTimeout,
            maxPayload: configuration.maxPayload,
            addTrailingSlash: configuration.addTrailingSlash,
            allowEIO3: configuration.allowEIO3,
            allowUpgrades: configuration.allowUpgrades,
            allowRequest: configuration.allowRequest,
            cookie: configuration.cookie,
            logLevel: configuration.logLevel
        )
        self.engine = engine ?? DefaultEngine(path: configuration.path, configuration: config)
        self.namespaceMaps = [defaultNamespaceMap]

        setHandlers()
    }
}

// MARK: - Handlers

extension SocketIOServer {
    @Sendable private func connectionHandler(client: EngineIO.Client) async {
    }

    @Sendable private func disonnectionHandler(client: EngineIO.Client, reason: EngineIO.DisconnectReason) async {
        let sockets = await getSockets(for: client)
        for socket in sockets {
            guard let namespaceMap = await getNamespace(containingEngineClientID: client.id) else {
                return
            }
            await namespaceMap.removeSocket(socket)
            await socket.state.callDisconnectionHandler(reason: reason.disconnectReason)
        }
    }

    @Sendable private func packetsHandler(client: EngineIO.Client, packets: [any Packet]) async {
        do {
            for packet in packets {
                switch packet {
                case let basicTestPacket as BasicTextPacket:
                    let socketIOPacket = try SocketIOPacket(from: basicTestPacket)
                    await processPacket(for: client, packet: socketIOPacket)
                case let binaryPacket as BinaryPacket:
                    await handleBinaryPacket(for: client, packet: binaryPacket)
                default:
                    break
                }
            }
        } catch {
            await client.disconnect()
        }
    }
}

// MARK: - Public methods

extension SocketIOServer {
    public func of(_ namespace: String) async -> any Namespace {
        if let namespace = getNamespace(for: namespace) {
            return namespace
        }
        let namespace = NamespaceMap(name: namespace)
        namespaceMaps.insert(namespace)
        return namespace
    }
}

// MARK: - RouteCollection

extension SocketIOServer: RouteCollection {
    public nonisolated func boot(routes: Vapor.RoutesBuilder) throws {
        try engine.boot(routes: routes)
    }
}

// MARK: - Helpers

extension SocketIOServer {
    private nonisolated func setHandlers() {
        Task {
            await self.engine.onConnection(use: connectionHandler)
            await self.engine.onDisconnection(use: disonnectionHandler)
            await self.engine.onPackets(use: packetsHandler)
        }
    }

    func processPacket(for client: EngineIO.Client, packet: SocketIOPacket) async {
        if packet.socketIOType == .connect {
            await handleConnect(for: client, packet: packet)
        } else {
            guard let socket = await getSocket(for: client, and: packet.namespace) else { return await client.disconnect() }
            switch packet.socketIOType {
            case .disconnect: await handleDisconnect(for: socket, packet: packet)
            case .event: await handleEvent(for: socket, packet: packet)
            case .binaryEvent: await handleBinaryEvent(for: socket, packet: packet)
            default: return
            }
        }
    }

    private func handleConnect(for client: EngineIO.Client, packet: SocketIOPacket) async {
        do {
            let socket = Socket(client: client, namespace: packet.namespace, server: self)
            let handshakePacket = SocketIOPacket(
                socketIOType: .connect,
                namespace: packet.namespace,
                payload: SocketIOHandshake(id: socket.client.id).dictionary
            )

            try await connect(socket: socket, to: packet.namespace)
            await socket.client.sendPacket(handshakePacket)
        } catch {
            await client.sendPacket(error.toSocketIOPacket(namespace: packet.namespace))
            await client.disconnect()
        }
    }

    private func handleEvent(for socket: Socket, packet: SocketIOPacket) async {
        guard let eventDataPair = packet.eventDataPair else { return }
        await socket.state.callEventHandler(event: eventDataPair.event, data: eventDataPair.data)
    }

    private func handleBinaryEvent(for socket: Socket, packet: SocketIOPacket) async {
        guard let finalPacket = await socket.state.setPendingEventPacket(packet) else { return }
        await handleEvent(for: socket, packet: finalPacket)
        await flushPendingPacketStates(for: socket.client)
    }

    private func handleBinaryPacket(for client: EngineIO.Client, packet: BinaryPacket) async {
        let possibleSockets = await getSockets(for: client)
        for socket in possibleSockets {
            guard let finalPacket = await socket.state.appendPendingBinaryPacket(packet.rawData()) else { continue }
            await handleEvent(for: socket, packet: finalPacket)
            await flushPendingPacketStates(for: socket.client)
        }
    }

    private func handleDisconnect(for socket: Socket, packet: SocketIOPacket) async {
        await disconnect(socket: socket, from: packet.namespace)
    }

    private func getSocket(for client: EngineIO.Client, and namespace: String) async -> Socket? {
        let sockets = await allSockets()
        return sockets.first(where: { $0.engineClientID == client.id && $0.namespace == namespace })
    }

    private func getSockets(for client: EngineIO.Client) async -> Set<Socket> {
        let sockets = await allSockets()
        return sockets.filter { $0.engineClientID == client.id }
    }

    private func allSockets() async -> Set<Socket> {
        var sockets = Set<Socket>()
        for namespaceMap in namespaceMaps {
            sockets.formUnion(await namespaceMap.getSockets())
        }
        return sockets
    }

    private func connect(socket: Socket, to namespace: String) async throws {
        guard let namespaceMap = getNamespace(for: namespace) else { throw SocketIOError.invalidNamespace }
        try await namespaceMap.addSocket(socket)
    }

    private func disconnect(socket: Socket, from namespace: String) async {
        await getNamespace(for: namespace)?.removeSocket(socket)
        await socket.state.callDisconnectionHandler(reason: .forcefully)
    }

    func getNamespace(for name: String) -> NamespaceMap? {
        namespaceMaps.first(where: { $0.name == name })
    }

    private func getNamespace(containingEngineClientID engineClientID: String) async -> NamespaceMap? {
        for namespaceMap in namespaceMaps {
            if await namespaceMap.containsSocket(engineClientID: engineClientID) {
                return namespaceMap
            }
        }
        return nil
    }

    func addSocket(_ socket: Socket, to room: String) async {
        await getNamespace(for: socket.namespace)?.addSocket(socket, to: room)
    }

    func removeSocket(_ socket: Socket, from room: String) async {
        await getNamespace(for: socket.namespace)?.removeSocket(socket, from: room)
    }

    private func flushPendingPacketStates(for client: EngineIO.Client) async {
        for socket in await getSockets(for: client) {
            await socket.resetPendingPacketState()
        }
    }

    func broadcastEmit(from socket: Socket, event: String, payload: SocketIOPayload) async {
        guard let namespaceMap = getNamespace(for: socket.namespace) else { return }
        var sockets = await namespaceMap.getSockets()
        sockets.remove(socket)
        for socket in sockets {
            socket.emit(event: event, payload: payload)
        }
    }
}
