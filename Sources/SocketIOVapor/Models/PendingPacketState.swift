//
//  PendingState.swift
//
//
//  Created by Barna Nemeth on 07/01/2024.
//

import Foundation
import Vapor

final class PendingPacketState: @unchecked Sendable {

    // MARK: Internal properties

    var eventPacket: SocketIOPacket?
    var binaryPackets = [ByteBuffer]()

    // MARK: Init

    init(eventPacket: SocketIOPacket? = nil, byteBuffer: ByteBuffer? =  nil) {
        self.eventPacket = eventPacket
        if let byteBuffer {
            self.binaryPackets = [byteBuffer]
        }
    }

    // MARK: Internal methods

    func setEventPacket(_ eventPacket: SocketIOPacket) {
        self.eventPacket = eventPacket
    }

    func appendBinaryPacket(_ byteBuffer: ByteBuffer) {
        binaryPackets.append(byteBuffer)
    }

    func getFinalPacket() -> SocketIOPacket? {
        guard var eventPacket, var array = eventPacket.payload as? [Any] else { return nil }
        let placeholderIndices = array.enumerated().compactMap { index, item -> Int? in
            guard isBinaryAttachmentPlaceholder(item) else { return nil }
            return index
        }
        guard placeholderIndices.count == binaryPackets.count else { return nil }
        zip(binaryPackets, placeholderIndices).forEach { binaryPacket, index in
            array[index] = binaryPacket
        }
        eventPacket.payload = array as Any
        return eventPacket
    }

    // MARK: Helpers

    private func isBinaryAttachmentPlaceholder(_ object: Any) -> Bool {
        guard let dictionary = object as? [String: Any] else { return false }
        return dictionary[BinaryAttachmentPlaceholderKeys.placeholder] is Bool &&
            dictionary[BinaryAttachmentPlaceholderKeys.number] is Int
    }
}
