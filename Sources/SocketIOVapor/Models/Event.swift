//
//  Event.swift
//
//
//  Created by Barna Nemeth on 30/12/2023.
//

import Foundation

public struct Event: Equatable, RawRepresentable, ExpressibleByStringLiteral {

    public static let connection: Event = "connection"
    public static let newNamespace: Event = "new_namespace"

    public var rawValue: String

    public init?(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral: String) {
        rawValue = stringLiteral
    }
}
