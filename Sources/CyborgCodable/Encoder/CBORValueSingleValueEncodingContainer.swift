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

#if canImport(BigIntModule)
import BigIntModule
#endif

#if MODULAR_DEVELOPMENT
import Cyborg
#endif

class CBORValueSingleValueEncodingContainer: SingleValueEncodingContainer, DeferredContainer {
    var codingPath: [CodingKey] {
        boxing.codingPath
    }

    var boxing: CBORBoxing
    var state: CBOR

    init(boxing: CBORBoxing) {
        self.boxing = boxing
        state = CBOR.undefined
    }
    private func assertFirstEncode() {
        assert(state == .undefined, "SingleValueEncodingContainer may only have a single encode method called")
    }
    func encodeNil() throws {
        assertFirstEncode()
        state = .null
    }

    func encode(_ value: Bool) throws {
        assertFirstEncode()
        state = boxing.box(value)
    }

    func encode(_ value: String) throws {
        assertFirstEncode()
        state = boxing.box(value)
    }

    func encode(_ value: Double) throws {
        assertFirstEncode()
        state = boxing.box(value)
    }

    func encode(_ value: Float) throws {
        assertFirstEncode()
        state = boxing.box(value)
    }

    func encode(_ value: Int) throws {
        assertFirstEncode()
        state = boxing.box(value)
    }

    func encode(_ value: Int8) throws {
        assertFirstEncode()
        state = boxing.box(value)
    }

    func encode(_ value: Int16) throws {
        assertFirstEncode()
        state = boxing.box(value)
    }

    func encode(_ value: Int32) throws {
        assertFirstEncode()
        state = boxing.box(value)
    }

    func encode(_ value: Int64) throws {
        assertFirstEncode()
        state = boxing.box(value)
    }

    func encode(_ value: UInt) throws {
        assertFirstEncode()
#if canImport(BigIntModule)
        state = boxing.box(value)
#else
        state = try boxing.box(value)
#endif
    }

    func encode(_ value: UInt8) throws {
        assertFirstEncode()
        state = boxing.box(value)
    }

    func encode(_ value: UInt16) throws {
        assertFirstEncode()
        state = boxing.box(value)
    }

    func encode(_ value: UInt32) throws {
        assertFirstEncode()
        state = boxing.box(value)
    }

    func encode(_ value: UInt64) throws {
        assertFirstEncode()
#if canImport(BigIntModule)
        state = boxing.box(value)
#else
        state = try boxing.box(value)
#endif
    }

    func encode(_ value: CBOR) throws {
        assertFirstEncode()
        state = value
    }

    func encode<T>(_ value: T) throws where T: Encodable {
        assertFirstEncode()
        state = try boxing.box(value)
    }

    func finalize() -> CBOR {
        defer {
            state = CBOR.undefined
        }

        return state
    }
}
