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

struct CBORSingleValueDecodingContainer: SingleValueDecodingContainer {
    var unboxer: CBORUnboxer
    var cbor: CBOR

    init(_ cbor: CBOR, _ unboxer: CBORUnboxer) {
        self.cbor = cbor
        self.unboxer = unboxer
    }

    var codingPath: [CodingKey] {
        unboxer.codingPath
    }

    func decodeNil() -> Bool {
        unboxer.decodeNil(cbor)
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: String.Type) throws -> String {
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: Double.Type) throws -> Double {
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: Float.Type) throws -> Float {
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: Int.Type) throws -> Int {
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try unboxer.decode(cbor, type)
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try unboxer.decode(cbor, type)
    }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        return try unboxer.decodeDecodable(cbor, type)
    }
}
