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

enum CBORUnkeyedDecodingContainerError: Error {
    case noMoreElements
}
struct CBORUnkeyedDecodingContainer: UnkeyedDecodingContainer {

    var array: [CBOR] = []
    var unboxer: CBORUnboxer
    var currentIndex = 0

    init(_ array: [CBOR], _ unboxer: CBORUnboxer) {
        self.array = array
        self.unboxer = unboxer
    }

    var codingPath: [CodingKey] {
        unboxer.codingPath
    }

    var count: Int? {
        return array.count
    }

    var isAtEnd: Bool {
        currentIndex == count
    }

    mutating func pop() throws -> CBOR {
        guard currentIndex < array.count else {
            throw CBORUnkeyedDecodingContainerError.noMoreElements
        }
        let result = array[currentIndex]
        currentIndex += 1
        return result
    }
    mutating func decodeNil() throws -> Bool {
        return unboxer.decodeNil(try pop())
    }

    mutating func decode(_ type: Bool.Type) throws -> Bool {
        return try unboxer.decode(pop(), type)
    }

    mutating func decode(_ type: String.Type) throws -> String {
        return try unboxer.decode(pop(), type)
    }

    mutating func decode(_ type: Double.Type) throws -> Double {
        return try unboxer.decode(pop(), type)
    }

    mutating func decode(_ type: Float.Type) throws -> Float {
        return try unboxer.decode(pop(), type)
    }

    mutating func decode(_ type: Int.Type) throws -> Int {
        return try unboxer.decode(pop(), type)
    }

    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        return try unboxer.decode(pop(), type)
    }

    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        return try unboxer.decode(pop(), type)
    }

    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        return try unboxer.decode(pop(), type)
    }

    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        return try unboxer.decode(pop(), type)
    }

    mutating func decode(_ type: UInt.Type) throws -> UInt {
        return try unboxer.decode(pop(), type)
    }

    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try unboxer.decode(pop(), type)
    }

    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try unboxer.decode(pop(), type)
    }

    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try unboxer.decode(pop(), type)
    }

    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try unboxer.decode(pop(), type)
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        let subElement = unboxer.withSubkey(ArrayIndex(intValue: currentIndex))
        return try subElement.decodeDecodable(pop(), type)
    }

    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws ->
        KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {

        let cbor = try pop()

        guard let nestedObject = cbor.objectValue else {
            throw CBORDecoderError.notKeyedContainer
        }
        let container = CBORKeyedDecodingContainer<NestedKey>(
            nestedObject,
            unboxer.withSubkey(ArrayIndex(intValue: currentIndex)))
        return KeyedDecodingContainer(container)

    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        let cbor = try pop()

        guard let nestedArray = cbor.arrayValue else {
            throw CBORDecoderError.notKeyedContainer
        }
        return CBORUnkeyedDecodingContainer(nestedArray, unboxer.withSubkey(ArrayIndex(intValue: currentIndex)))
    }

    mutating func superDecoder() throws -> Decoder {
        let cbor = try pop()
        return ActiveCBORDecoder(unboxer: unboxer.withSubkey(ArrayIndex(intValue: currentIndex)), cbor: cbor)
    }
}
