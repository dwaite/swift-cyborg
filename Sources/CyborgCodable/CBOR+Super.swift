//
//  File.swift
//  
//
//  Created by David Waite on 12/9/19.
//

import Foundation

#if MODULAR_DEVELOPMENT
import Cyborg
#endif

internal extension CBOR {
    static let `super` = Self.simple(value: 0xA7) // Latin-1 §, may change however if standardized
}

internal struct CBORSuperKey: CBORCodingKey {
    public var cborValue: CBOR {
        return .super
    }

    public init() {
    }

    public init?(cborValue: CBOR) {
        if cborValue != .super {
            return nil
        }
    }

    public init?(stringValue: String) {
        if stringValue != "§" {
            return nil
        }
    }

    public var intValue: Int? {
        return nil
    }

    public init?(intValue: Int) {
        return nil
    }

    public var stringValue: String {
        return "§"
    }
}
