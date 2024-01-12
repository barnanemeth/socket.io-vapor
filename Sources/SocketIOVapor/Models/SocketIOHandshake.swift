//
//  SocketIOHandshake.swift
//  
//
//  Created by Barna Nemeth on 30/12/2023.
//

import Foundation

struct SocketIOHandshake {

    // MARK: Coding keys

    private enum CodingKeys: String, CodingKey {
        case id = "sid"
    }

    // MARK: Properties

    let id: String

    var dictionary: [String: Any] {
        [CodingKeys.id.rawValue: id]
    }
}

// MARK: - Encodable

extension SocketIOHandshake: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
    }
}
