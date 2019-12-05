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

class CBORKeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol, DeferredContainer {
    var codingPath: [CodingKey] {
        boxing.codingPath
    }
    
    let keyedType: Key.Type

    let boxing: CBORBoxing
    var state: [CBOR: DeferrableCBOR]

    func assertKeyNotPresent(forKey key: Key) {
        assert(state[toCBORKey(key)] == nil, "value may only be set once per key on CBORKeyedEncodingContainer (duplicate = \"\(key)\"")
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
#if canImport(BigInt)
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
#if canImport(BigInt)
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

    func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        assertKeyNotPresent(forKey: key)
        let subBox = boxing.withSubKey(key)
        state[toCBORKey(key)] = try .cbor(subBox.box(value))
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError()
    }
    
    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        fatalError()
    }
    
    func superEncoder() -> Encoder {
        fatalError()
    }
    
    func superEncoder(forKey key: Key) -> Encoder {
        fatalError()
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
                }
            }
        )
    }
}
