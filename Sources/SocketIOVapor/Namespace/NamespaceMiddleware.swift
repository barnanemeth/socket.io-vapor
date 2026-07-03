//
//  NamespaceMiddleware.swift
//
//
//  Created by Barna Nemeth on 04/01/2024.
//

import Foundation
import Vapor

public protocol NamespaceMiddleware {
    func respond(to socket: Socket) async throws
}
