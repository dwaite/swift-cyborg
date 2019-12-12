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

public struct CBORValueEncoder {
    var boxing: CBORBoxing

    public init() {
        self.boxing = CBORBoxing(codingPath: [])
    }
    public var userInfo: [CodingUserInfoKey: Any] {
        get {
            boxing.userInfo
        }
        set {
            boxing.userInfo = newValue
        }
    }

    public var dateEncodingStrategy: DateEncodingStrategy {
        get {
            boxing.dateEncodingStrategy
        }
        set {
            boxing.dateEncodingStrategy = newValue
        }
    }

    public func encode<T: Codable>(_ value: T) throws -> CBOR {
        let encoder = ActiveCBOREncoder(boxing: boxing)
        try value.encode(to: encoder)
        return encoder.finalize()
    }
}

func toCBORKey(_ key: CodingKey) -> CBOR {
    if let key = key as? CBORCodingKey {
        return key.cborValue
    }
    if let intValue = key.intValue {
        return CBOR(integerLiteral: intValue)
    } else {
        return CBOR(stringLiteral: key.stringValue)
    }
}

// because of the encoder model, vended encoding containers have no scope. So we wind up deferring encoding in some
// cases to those containers, which get stuck directly into our object model
protocol DeferredContainer {
    mutating func finalize() -> CBOR
}

enum DeferrableCBOR {
    case cbor(CBOR)
    indirect case deferred(state: DeferredContainer)
    indirect case encoder(ActiveCBOREncoder)
}

public class ActiveCBOREncoder: Encoder {
    var boxing: CBORBoxing

    var vendedContainer: DeferredContainer?

    public var codingPath: [CodingKey] {
        boxing.codingPath
    }
    public var userInfo: [CodingUserInfoKey: Any] {
        boxing.userInfo
    }

    init(boxing: CBORBoxing) {
        self.boxing = boxing
    }

    init(boxing: CBORBoxing, subKey: CodingKey) {
        self.boxing = boxing
        self.boxing.codingPath += [subKey]
    }

    private func enforceOneUse() {
        guard vendedContainer == nil else {
            fatalError("Encoders only allow a single call to request a container")
        }
    }

    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        enforceOneUse()
        let keyed = CBORKeyedEncodingContainer(boxing: boxing, keyedType: type)
        vendedContainer = keyed
        return KeyedEncodingContainer(keyed)
    }

    public func singleValueContainer() -> SingleValueEncodingContainer {
        enforceOneUse()
        let single = CBORValueSingleValueEncodingContainer(boxing: boxing)
        vendedContainer = single
        return single
    }

    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        enforceOneUse()
        let unkeyed = CBORUnkeyedEncodingContainer(boxing: boxing)
        vendedContainer = unkeyed
        return unkeyed
    }

    func finalize() -> CBOR {
        guard var container = vendedContainer else {
            fatalError("Encoder must have data")
        }
        return container.finalize()
    }
}
