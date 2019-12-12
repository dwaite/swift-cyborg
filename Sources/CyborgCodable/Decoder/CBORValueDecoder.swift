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

enum CBORDecoderError: LocalizedError {
    case notUnkeyedContainer
    case notKeyedContainer
    case expectedCBORDocumentTag
}
struct CBORValueDecoder {
    var unboxer: CBORUnboxer

    init() {
        self.unboxer = CBORUnboxer()
    }
    var dateDecodingStrategy: DateDecodingStrategy {
        get {
            unboxer.dateDecodingStrategy
        }

        set {
            unboxer.dateDecodingStrategy = newValue
        }
    }
    func decode<T: Decodable>(_ cbor: CBOR, type: T.Type) throws -> T {
        let decoder = ActiveCBORDecoder(cbor)
        return try T.init(from: decoder)
    }
}

struct ActiveCBORDecoder: Decoder {
    var unboxer: CBORUnboxer
    var cbor: CBOR

    init(_ cbor: CBOR) {
        self.unboxer = CBORUnboxer()
        self.cbor = cbor
    }

    init(unboxer: CBORUnboxer, cbor: CBOR) {
        self.unboxer = unboxer
        self.cbor = cbor
    }
    var codingPath: [CodingKey] { unboxer.codingPath }
    var userInfo: [CodingUserInfoKey: Any] { unboxer.userInfo }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        guard case .object(let object) = cbor else {
            throw CBORDecoderError.notKeyedContainer
        }

        return KeyedDecodingContainer(CBORKeyedDecodingContainer<Key>(object, unboxer))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard case .array(let array) = cbor else {
            throw CBORDecoderError.notUnkeyedContainer
        }
        return CBORUnkeyedDecodingContainer(array, unboxer)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        CBORSingleValueDecodingContainer(cbor, unboxer)
    }

}
