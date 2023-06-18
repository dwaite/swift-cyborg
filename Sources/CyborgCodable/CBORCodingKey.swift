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

public protocol CBORCodingKey: CodingKey {

    /// The value to use in an CBOR-indexed collection (e.g. a CBOR object).
    var cborValue: CBOR { get }

    /// Creates a new instance from the given CBOR
    ///
    /// If the CBOR passed as `cborValue` does not correspond to any instance
    /// of this type, the result is `nil`.
    ///
    /// - parameter cborValue: The CBOR value of the desired key.
    init?(cborValue: CBOR)
}

extension CBORCodingKey {
    var stringValue: String {
        switch cborValue {
        case .int(let value):
            return "\(value)"
        case .bigInt(let value):
            return "\(value)"
        case .string(let value):
            return value
        case .double(let value):
            return "\(value)"
        default:
            return cborValue.description
        }
    }
}
