//
//  SocketIOPacket.swift
//
//
//  Created by Barna Nemeth on 30/12/2023.
//

import Foundation
import Vapor
import EngineIO

struct SocketIOPacket: TextPacket, @unchecked Sendable {

    // MARK: Typealiases

    typealias EventDataPair = (event: String, data: [Any])

    // MARK: Constants

    private enum Constant {
        static let numberOfBinaryAttachmentsSeparator: Character = "-"
        static let namespacePrefix: Character = "/"
        static let namespaceSeparator: Character = ","
        static let payloadRegexPattern = "(\\[.+\\])|(\\{.+\\})"
        static let jsonWritingOptions: JSONSerialization.WritingOptions = [.withoutEscapingSlashes, .sortedKeys]
    }

    // MARK: Properties

    let id = UUID()
    let type: PacketType
    var socketIOType: SocketIOPacketType
    let namespace: String
    let numberOfBinaryAttachments: Int
    let ackID: Int?
    var payload: Any?

    var eventDataPair: EventDataPair? {
        guard let array = payload as? NSArray, let event = array.firstObject as? String  else { return nil }
        return (event, array.dropFirst().map { $0 as Any })
    }

    // MARK: Init

    init(from text: String) throws {
        var text = text

        // Core type
        self.type = .message

        // Payload
        let payloadRegex = try NSRegularExpression(pattern: Constant.payloadRegexPattern)
        if let match = payloadRegex.matches(in: text, range: NSRange(location: .zero, length: text.count)).first {
            let substring = NSString(string: text).substring(with: match.range)
            let jsonData = substring.data(using: .utf8)!
            self.payload = try JSONSerialization.jsonObject(with: jsonData)

            let start = String.Index(utf16Offset: match.range.location, in: text)
            let end = String.Index(utf16Offset: match.range.location + match.range.length, in: text)
            text.removeSubrange(start..<end)
        } else {
            self.payload = nil
        }

        // Socket.io type
        guard !text.isEmpty, let socketIOType = SocketIOPacketType(rawValue: text.removeFirst()) else {
            throw SocketIOPacketError.invalidPacketFormat
        }
        self.socketIOType = socketIOType

        // Number of binary attachments
        if text.first?.isNumber ?? false,
           let rangeEndIndex = text.firstIndex(where: {$0 == Constant.numberOfBinaryAttachmentsSeparator }) {
            let range = (String.Index(utf16Offset: .zero, in: text)..<rangeEndIndex)
            let numberOfBinaryAttachmentsSubrange = text[range]
            self.numberOfBinaryAttachments = Int(numberOfBinaryAttachmentsSubrange) ?? .zero
            text.removeSubrange(String.Index(utf16Offset: .zero, in: text)...rangeEndIndex)
        } else {
            self.numberOfBinaryAttachments = .zero
        }

        // Namespace
        if text.first == Constant.namespacePrefix {
            if let rangeEndIndex = text.firstIndex(of: Constant.namespaceSeparator) {
                let range = (String.Index(utf16Offset: .zero, in: text)..<rangeEndIndex)
                self.namespace = String(text[range])
                text.removeSubrange(String.Index(utf16Offset: .zero, in: text)..<rangeEndIndex)
            } else {
                self.namespace = text
            }
        } else {
            self.namespace = "/"
        }

        // Acknowledgment ID
        self.ackID = Int(text)
    }

    init(from textPacket: any TextPacket) throws {
        guard textPacket.type == .message, let payload = textPacket.payload as? String else {
            throw SocketIOPacketError.invalidEncapsulatingPacket
        }
        try self.init(from: payload)
    }

    init(socketIOType: SocketIOPacketType,
         namespace: String,
         numberOfBinaryAttachments: Int = 0,
         payload: Any? = nil,
         ackID: Int? = nil
    ) {
        self.type = .message
        self.socketIOType = socketIOType
        self.namespace = namespace
        self.numberOfBinaryAttachments = numberOfBinaryAttachments
        self.payload = payload
        self.ackID = ackID
    }
}

// MARK: - Public methods

extension SocketIOPacket {
    func rawData() -> String {
        var text = "\(type.rawValue)\(socketIOType.rawValue)"
        if numberOfBinaryAttachments > .zero {
            text += "\(numberOfBinaryAttachments)\(Constant.numberOfBinaryAttachmentsSeparator)"
        }
        if namespace != "/" {
            text += namespace
            if payload != nil {
                text += "\(Constant.namespaceSeparator)"
            }
        }
        if let ackID {
            text += "\(ackID)"
        }
        if let payload,
           let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: Constant.jsonWritingOptions),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            text += jsonString
        }
        return text
    }
}
