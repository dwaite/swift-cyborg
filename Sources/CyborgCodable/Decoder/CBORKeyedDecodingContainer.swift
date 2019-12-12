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

#if MODULAR_DEVELOPMENT
import Cyborg
#endif

func toCBOR<Key>(_ key: Key) -> CBOR where Key: CodingKey {
    if let int = key.intValue {
        return .int(int)
    }
    return .string(key.stringValue)
}

enum CBORKeyedDecodingContainerError: Error {
    case keyNotFound(key: CodingKey)
}

class CBORKeyedDecodingContainer<Key>: KeyedDecodingContainerProtocol where Key: CodingKey {

    let unboxer: CBORUnboxer
    var object: [CBOR: CBOR]

    init(_ object: [CBOR: CBOR], _ unboxer: CBORUnboxer) {
        self.object = object
        self.unboxer = unboxer
    }

    var codingPath: [CodingKey] {
        unboxer.codingPath
    }

    var allKeys: [Key] {
        object.keys.compactMap {
            switch $0 {
            case .string(let str):
                return Key(stringValue: str)
            case .int(let int):
                return Key(intValue: int)
            default:
                return nil
            }
        }
    }
    func contains(_ key: Key) -> Bool {
        return object[toCBOR(key)] != nil
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        guard let cbor = object[toCBOR(key)] else {
            throw CBORKeyedDecodingContainerError.keyNotFound(key: key)
        }
        return unboxer.decodeNil(cbor)
    }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        guard let cbor = object[toCBOR(key)] else {
            throw CBORKeyedDecodingContainerError.keyNotFound(key: key)
        }
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        guard let cbor = object[toCBOR(key)] else {
            throw CBORKeyedDecodingContainerError.keyNotFound(key: key)
        }
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        guard let cbor = object[toCBOR(key)] else {
            throw CBORKeyedDecodingContainerError.keyNotFound(key: key)
        }
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        guard let cbor = object[toCBOR(key)] else {
            throw CBORKeyedDecodingContainerError.keyNotFound(key: key)
        }
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        guard let cbor = object[toCBOR(key)] else {
            throw CBORKeyedDecodingContainerError.keyNotFound(key: key)
        }
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        guard let cbor = object[toCBOR(key)] else {
            throw CBORKeyedDecodingContainerError.keyNotFound(key: key)
        }
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        guard let cbor = object[toCBOR(key)] else {
            throw CBORKeyedDecodingContainerError.keyNotFound(key: key)
        }
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        guard let cbor = object[toCBOR(key)] else {
            throw CBORKeyedDecodingContainerError.keyNotFound(key: key)
        }
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        guard let cbor = object[toCBOR(key)] else {
            throw CBORKeyedDecodingContainerError.keyNotFound(key: key)
        }
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        guard let cbor = object[toCBOR(key)] else {
            throw CBORKeyedDecodingContainerError.keyNotFound(key: key)
        }
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        guard let cbor = object[toCBOR(key)] else {
            throw CBORKeyedDecodingContainerError.keyNotFound(key: key)
        }
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        guard let cbor = object[toCBOR(key)] else {
            throw CBORKeyedDecodingContainerError.keyNotFound(key: key)
        }
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        guard let cbor = object[toCBOR(key)] else {
            throw CBORKeyedDecodingContainerError.keyNotFound(key: key)
        }
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        guard let cbor = object[toCBOR(key)] else {
            throw CBORKeyedDecodingContainerError.keyNotFound(key: key)
        }
        return try unboxer.decode(cbor, type)
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        guard let cbor = object[toCBOR(key)] else {
            throw CBORKeyedDecodingContainerError.keyNotFound(key: key)
        }
        let subelement = unboxer.withSubkey(key)
        return try subelement.decodeDecodable(cbor, type)
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws ->
        KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {

        guard let cbor = object[toCBOR(key)] else {
            throw CBORKeyedDecodingContainerError.keyNotFound(key: key)
        }
        guard let nestedObject = cbor.objectValue else {
            throw CBORDecoderError.notKeyedContainer
        }
        return KeyedDecodingContainer(CBORKeyedDecodingContainer<NestedKey>(nestedObject, unboxer.withSubkey(key)))

    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        guard let cbor = object[toCBOR(key)] else {
            throw CBORKeyedDecodingContainerError.keyNotFound(key: key)
        }
        guard let nestedArray = cbor.arrayValue else {
            throw CBORDecoderError.notKeyedContainer
        }
        return CBORUnkeyedDecodingContainer(nestedArray, unboxer.withSubkey(key))
    }

    func superDecoder() throws -> Decoder {
        let key = CBORSuperKey()
        guard let cbor = object[toCBOR(key)] else {
            throw CBORKeyedDecodingContainerError.keyNotFound(key: key)
        }
        return ActiveCBORDecoder(unboxer: unboxer.withSubkey(key), cbor: cbor)
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        guard let cbor = object[toCBOR(key)] else {
            throw CBORKeyedDecodingContainerError.keyNotFound(key: key)
        }
        return ActiveCBORDecoder(unboxer: unboxer.withSubkey(key), cbor: cbor)
    }
}
