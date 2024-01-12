//
//  SocketIOError.swift
//  
//
//  Created by Barna Nemeth on 30/12/2023.
//

import Foundation

enum SocketIOError: Error, LocalizedError {
    case invalidNamespace

    var errorDescription: String? {
        switch self {
        case .invalidNamespace: "Invalid namespace"
        }
    }
}
