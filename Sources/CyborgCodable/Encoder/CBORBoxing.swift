// Copyright © 2019 David Waite
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

#if canImport(BigInt)
import BigInt
#endif

#if MODULAR_DEVELOPMENT
import Cyborg
#endif

//
//protocol BoxingProtocol {
//    associatedtype Boxed
//    // assume an appropriate encoding format can always support the following without throwing or requring custom encoding as a minimal useful set:
//    // - booleans
//    // - integer types up to Int32
//    // - utf8 strings
//    func box(_ value: Bool)   -> Boxed
//    func box(_ value: Int8)   -> Boxed
//    func box(_ value: Int16)  -> Boxed
//    func box(_ value: Int32)  -> Boxed
//    func box(_ value: UInt8)  -> Boxed
//    func box(_ value: UInt16) -> Boxed
//    func box(_ value: String) -> Boxed
//
//    // assume the following types may fail due to the underlying container format, but will not require
//    // ellaborate encoding
//    func box(_ value: UInt32) throws -> Boxed
//    func box(_ value: Int64)  throws -> Boxed
//    func box(_ value: UInt64) throws -> Boxed
//    func box(_ value: Int)    throws -> Boxed
//    func box(_ value: UInt)   throws -> Boxed
//    func box(_ value: Float)  throws -> Boxed
//    func box(_ value: Double) throws -> Boxed
//    func boxNil()             throws -> Boxed
//
//    // assume the following types may fail due to the underlying container format, and may also require an encoder
//    func box(_ date: Date)    throws -> Boxed
//    func box(_ data: Data)    throws -> Boxed
//
//    // assume this will always delegate and require an underlying encoder
//    func boxEncodable(_ encodable: Encodable) throws -> Boxed
//
//    // assume this method may need to dispatch to other existing boxing methods
//    func box(_ value: Encodable) throws -> Boxed
//
//    func withSubKey(_ subKey: CodingKey) -> Self
//}

struct CBORBoxing {
    var userInfo: [CodingUserInfoKey : Any] = [:]
    var dateEncodingStrategy: DateEncodingStrategy = .secondsSince1970
    
    var codingPath: [CodingKey]

#if !canImport(BigInt)
    func integerConversionError(_ value: Any) -> Error {
        return EncodingError.invalidValue(value,
              EncodingError.Context(
                codingPath: codingPath,
                debugDescription: "Unable to convert integer value to platform Int"))
    }
#endif
    
    func box(_ value: Bool) -> CBOR {
        value ? .true : .false
    }
    
    func box(_ value: String) -> CBOR {
        .string(value)
    }
    
    func box(_ value: Double) -> CBOR  {
        .double(value)
    }
    
    func box(_ value: Float) -> CBOR {
        .double(Double(value))
    }
    
    func box(_ value: Int) -> CBOR {
        .int(value)
    }
    
    func box(_ value: Int8) -> CBOR {
        .int(Int(value))
    }
    
    func box(_ value: Int16) -> CBOR {
        .int(Int(value))
    }
    
    func box(_ value: Int32) -> CBOR  {
        .int(Int(value))
    }

    func box(_ value: UInt8)  -> CBOR  {
        .int(Int(value))
    }
    
    func box(_ value: UInt16)  -> CBOR  {
        .int(Int(value))
    }

    // For Int64 and UInt32, ability to encode directly depends on the platform.
    
    // 64 bit
    #if arch(x86_64) || arch(arm64)

    func box(_ value: Int64) -> CBOR  {
        .int(Int(value))
    }

    func box(_ value: UInt32) -> CBOR  {
        .int(Int(value))
    }
    #elseif canImport(BigInt)
    func box(_ value: Int64) -> CBOR {
        if let value = Int(exactly: value) {
            return .int(value)
        }
        else {
            return .bigInt(BigInt(value))
        }
    }
    func box(_ value: UInt32) -> CBOR {
        if let value = Int(exactly: value) {
            return .int(value)
        }
        else {
            return .bigInt(BigInt(value))
        }
    }
    #else
    func box(_ value: Int64) throws -> CBOR {
        if let value = Int(exactly: value) {
            return .int(value)
        }
        throw integerConversionError(value)
    }
    func box(_ value: UInt32) throws -> CBOR {
        if let value = Int(exactly: value) {
            return .int(value)
        }
        throw integerConversionError(value)
    }
    #endif
    
    // For UInt, UInt64, encoding depends on whether BigInt is available
    #if canImport(BigInt)
    
    func box(_ value: UInt)  -> CBOR  {
        if let value = Int(exactly: value) {
            return .int(value)
        }
        return .bigInt(BigInt(value))
    }
    
    func box(_ value: UInt64)  -> CBOR  {
        if let value = Int(exactly: value) {
            return .int(value)
        }
        return .bigInt(BigInt(value))
    }

    #else
    
    func box(_ value: UInt) throws  -> CBOR  {
        if let value = Int(exactly: value) {
            return .int(value)
        }
        throw integerConversionError(value)
    }

    func box(_ value: UInt64) throws  -> CBOR  {
        if let value = Int(exactly: value) {
            return .int(value)
        }
        throw integerConversionError(value)
    }

    #endif
    
    func boxNil() -> CBOR {
        .null
    }

    func boxEncodable(_ value: Encodable) throws -> CBOR {
        let encoder = ActiveCBOREncoder(boxing: self)
        try value.encode(to: encoder)
        return encoder.finalize()
    }
    
    
    func box(_ date: Date) throws -> CBOR {
        try dateEncodingStrategy.encode(date) { ActiveCBOREncoder(boxing: self) }
    }
    
    func box(_ data: Data) -> CBOR {
        .data(data)
    }
        
    func box(_ value: Encodable) throws -> CBOR {
        switch value {
        case let value as Int8:
            return box(value)
        case let value as Int16:
            return box(value)
        case let value as Int32:
            return box(value)
        case let value as UInt8:
            return box(value)
        case let value as UInt16:
            return box(value)
        case let value as Int:
            return box(value)
#if canImport(BigInt)
        case let value as UInt64:
            return box(value)
        case let value as UInt:
            return box(value)
        case let value as Int64:
            return box(value)
        case let value as UInt32:
            return box(value)
#else
        case let value as UInt64:
            return try box(value)
        case let value as UInt:
            return try box(value)
    #if arch(x86_64) || arch(arm64)
        case let value as Int64:
            return box(value)
        case let value as UInt32:
            return box(value)
    #else
        case let value as Int64:
            return try box(value)
        case let value as UInt32:
            return try box(value)
    #endif
#endif

        case let value as Bool:
            return box(value)
        case let value as Float:
            return box(value)
        case let value as Double:
            return box(value)
        case let value as String:
            return box(value)
        case let value as Date:
            return try box(value)
        case let value as Double:
            return box(value)
        case let value as CBOR:
            return value
        default:
            return try boxEncodable(value)
        
        }
    }

    func withSubKey(_ subKey: CodingKey) -> Self {
        var innerBox = self
        innerBox.codingPath = innerBox.codingPath + [subKey]
        return innerBox
    }
}
