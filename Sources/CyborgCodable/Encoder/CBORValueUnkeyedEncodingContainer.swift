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

#if canImport(BigIntModule)
import BigIntModule
#endif

class CBORUnkeyedEncodingContainer: UnkeyedEncodingContainer, DeferredContainer {

    var state: [DeferrableCBOR]
    var boxing: CBORBoxing
    var codingPath: [any CodingKey] {
        boxing.codingPath
    }

    init(boxing: CBORBoxing) {
        self.boxing = boxing
        self.state = []
    }

    var count: Int {
        state.count
    }

    func encode(_ value: String) throws {
        state.append(.cbor(boxing.box(value)))
    }

    func encode(_ value: Double) throws {
        state.append(.cbor(boxing.box(value)))
    }

    func encode(_ value: Float) throws {
        state.append(.cbor(boxing.box(value)))
    }

    func encode(_ value: Int) throws {
        state.append(.cbor(boxing.box(value)))
    }

    func encode(_ value: Int8) throws {
        state.append(.cbor(boxing.box(value)))
    }

    func encode(_ value: Int16) throws {
        state.append(.cbor(boxing.box(value)))
    }

    func encode(_ value: Int32) throws {
        state.append(.cbor(boxing.box(value)))
    }

    func encode(_ value: Int64) throws {
        state.append(.cbor(boxing.box(value)))
    }

    func encode(_ value: UInt) throws {
#if canImport(BigIntModule)
        state.append(.cbor(boxing.box(value)))
#else
        try state.append(.cbor(boxing.box(value)))
#endif
    }

    func encode(_ value: UInt8) throws {
        state.append(.cbor(boxing.box(value)))
    }

    func encode(_ value: UInt16) throws {
        state.append(.cbor(boxing.box(value)))
    }

    func encode(_ value: UInt32) throws {
        state.append(.cbor(boxing.box(value)))
    }

    func encode(_ value: UInt64) throws {
#if canImport(BigIntModule)
        state.append(.cbor(boxing.box(value)))
#else
        try state.append(.cbor(boxing.box(value)))
#endif
    }

    func encode(_ value: Bool) throws {
        state.append(.cbor(boxing.box(value)))
    }

    func encodeNil() throws {
        state.append(.cbor(boxing.boxNil()))
    }

    func encode<T>(_ value: T) throws where T: Encodable {
        state.append(.cbor(try boxing.box(value)))
    }

    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) ->
        KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            let container = CBORKeyedEncodingContainer<NestedKey>(
                boxing: boxing.withSubKey(ArrayIndex(intValue: state.count)),
                keyedType: keyType)
            state.append(.deferred(state: container))
            return KeyedEncodingContainer(container)
    }

    func nestedUnkeyedContainer() -> any UnkeyedEncodingContainer {
        let container = CBORUnkeyedEncodingContainer(boxing: boxing.withSubKey(ArrayIndex(intValue: state.count)))
        state.append(.deferred(state: container))
        return container
    }

    func superEncoder() -> any Encoder {
        let encoder = ActiveCBOREncoder(boxing: boxing, subKey: ArrayIndex(intValue: state.count))
        state.append(.encoder(encoder))
        return encoder
    }

    func finalize() -> CBOR {
        defer {
            state = []
        }
        return CBOR.array(
            state.map { value in
                switch value {
                case .cbor(let data):
                    return data
                case .deferred(var container):
                    return container.finalize()
                case .encoder(let encoder):
                    return encoder.finalize()
                }
            }
        )
    }
}
