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

#if canImport(BigIntModule)
import BigIntModule
#endif

#if MODULAR_DEVELOPMENT
import Cyborg
#endif

class CBORKeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol, DeferredContainer {
    var codingPath: [CodingKey] {
        boxing.codingPath
    }

    let keyedType: Key.Type

    let boxing: CBORBoxing
    var state: [CBOR: DeferrableCBOR]

    func assertKeyNotPresent(forKey key: CodingKey) {
        assert(state[toCBORKey(key)] == nil,
               "value may only be set once per key on CBORKeyedEncodingContainer (duplicate = \"\(key)\"")
    }
    init(boxing: CBORBoxing, state: [CBOR: DeferrableCBOR] = [:], keyedType: Key.Type) {
        self.boxing = boxing
        self.state = state
        self.keyedType = keyedType
    }
    func encodeNil(forKey key: Key) throws {
        assertKeyNotPresent(forKey: key)
        state[toCBORKey(key)] = .cbor(boxing.boxNil())
    }

    func encode(_ value: Bool, forKey key: Key) throws {
        assertKeyNotPresent(forKey: key)
        state[toCBORKey(key)] = .cbor(boxing.box(value))
    }

    func encode(_ value: String, forKey key: Key) throws {
        assertKeyNotPresent(forKey: key)
        state[toCBORKey(key)] = .cbor(boxing.box(value))
    }

    func encode(_ value: Double, forKey key: Key) throws {
        assertKeyNotPresent(forKey: key)
        state[toCBORKey(key)] = .cbor(boxing.box(value))
    }

    func encode(_ value: Float, forKey key: Key) throws {
        assertKeyNotPresent(forKey: key)
        state[toCBORKey(key)] = .cbor(boxing.box(value))
    }

    func encode(_ value: Int, forKey key: Key) throws {
        assertKeyNotPresent(forKey: key)
        state[toCBORKey(key)] = .cbor(boxing.box(value))
    }

    func encode(_ value: Int64, forKey key: Key) throws {
        assertKeyNotPresent(forKey: key)
        state[toCBORKey(key)] = .cbor(boxing.box(value))
    }

    func encode(_ value: UInt64, forKey key: Key) throws {
        assertKeyNotPresent(forKey: key)
#if canImport(BigIntModule)
        state[toCBORKey(key)] = .cbor(boxing.box(value))
#else
        state[toCBORKey(key)] = try .cbor(boxing.box(value))
#endif
    }

    func encode(_ value: Int8, forKey key: Key) throws {
        assertKeyNotPresent(forKey: key)
        state[toCBORKey(key)] = .cbor(boxing.box(value))
    }

    func encode(_ value: Int16, forKey key: Key) throws {
        assertKeyNotPresent(forKey: key)
        state[toCBORKey(key)] = .cbor(boxing.box(value))
    }

    func encode(_ value: Int32, forKey key: Key) throws {
        assertKeyNotPresent(forKey: key)
        state[toCBORKey(key)] = .cbor(boxing.box(value))
    }

    func encode(_ value: UInt, forKey key: Key) throws {
        assertKeyNotPresent(forKey: key)
#if canImport(BigIntModule)
        state[toCBORKey(key)] = .cbor(boxing.box(value))
#else
        state[toCBORKey(key)] = try .cbor(boxing.box(value))
#endif
    }

    func encode(_ value: UInt8, forKey key: Key) throws {
        assertKeyNotPresent(forKey: key)
        state[toCBORKey(key)] = .cbor(boxing.box(value))
    }

    func encode(_ value: UInt16, forKey key: Key) throws {
        assertKeyNotPresent(forKey: key)
        state[toCBORKey(key)] = .cbor(boxing.box(value))
    }

    func encode(_ value: UInt32, forKey key: Key) throws {
        assertKeyNotPresent(forKey: key)
        state[toCBORKey(key)] = .cbor(boxing.box(value))
    }

    // specialized
    func encode(_ value: CBOR, forKey key: Key) throws {
        assertKeyNotPresent(forKey: key)
        state[toCBORKey(key)] = .cbor(value)
    }

    func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        assertKeyNotPresent(forKey: key)
        let subBox = boxing.withSubKey(key)
        state[toCBORKey(key)] = try .cbor(subBox.box(value))
    }

    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) ->
        KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            assertKeyNotPresent(forKey: key)
            let container = CBORKeyedEncodingContainer<NestedKey>(boxing: boxing.withSubKey(key), keyedType: keyType)
            state[toCBORKey(key)] = .deferred(state: container)
            return KeyedEncodingContainer(container)
    }

    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        assertKeyNotPresent(forKey: key)
        let container = CBORUnkeyedEncodingContainer(boxing: boxing.withSubKey(key))
        state[toCBORKey(key)] = .deferred(state: container)
        return container
    }

    func superEncoder() -> Encoder {
        let key = CBORSuperKey()
        assertKeyNotPresent(forKey: key)
        let encoder = ActiveCBOREncoder(boxing: boxing, subKey: key)
        state[toCBORKey(key)] = .encoder(encoder)
        return encoder
    }

    func superEncoder(forKey key: Key) -> Encoder {
        assertKeyNotPresent(forKey: key)
        let encoder = ActiveCBOREncoder(boxing: boxing, subKey: key)
        state[toCBORKey(key)] = .encoder(encoder)
        return encoder
    }

    func finalize() -> CBOR {
        defer {
            state = [:]
        }
        return CBOR.object(
            state.mapValues {
                switch $0 {
                case .cbor(let cbor):
                    return cbor
                case .deferred(var container):
                    return container.finalize()
                case .encoder(let encoder):
                    return encoder.finalize()
                }
            }
        )
    }
}
