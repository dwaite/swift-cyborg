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

enum CBORUnboxingError: Error {
    case incorrectType(type: Any.Type )
    case incorrectlyFormattedURL
}
struct CBORUnboxer {
    var codingPath: [any CodingKey]
    var userInfo: [CodingUserInfoKey: Any]
    var dateDecodingStrategy: DateDecodingStrategy = .secondsSince1970

    init() {
        codingPath = []
        userInfo = [:]
    }

    func withSubkey(_ subkey: any CodingKey) -> Self {
        var state = self
        state.codingPath += [subkey]
        return state
    }

    func decodeNil(_ cbor: CBOR) -> Bool {
        cbor == .null
    }

    func decode(_ cbor: CBOR, _ type: Bool.Type) throws -> Bool {
        guard let result = cbor.booleanValue else {
            throw CBORUnboxingError.incorrectType(type: type)
        }
        return result
    }

    func decode(_ cbor: CBOR, _ type: String.Type) throws -> String {
        guard let result = cbor.stringValue else {
            throw CBORUnboxingError.incorrectType(type: type)
        }
        return result
    }

    func decode(_ cbor: CBOR, _ type: Double.Type) throws -> Double {
        guard let result = cbor.doubleValue else {
            throw CBORUnboxingError.incorrectType(type: type)
        }
        return result
    }

    func decode(_ cbor: CBOR, _ type: Float.Type) throws -> Float {
        guard let result: Float = cbor.getFloatingPoint() else {
            throw CBORUnboxingError.incorrectType(type: type)
        }
        return result
    }

    func decode(_ cbor: CBOR, _ type: Int.Type) throws -> Int {
        guard let result = cbor.intValue else {
            throw CBORUnboxingError.incorrectType(type: type)
        }
        return result
    }

    func decode(_ cbor: CBOR, _ type: Int8.Type) throws -> Int8 {
        guard let result: Int8 = cbor.getIntegerValue() else {
            throw CBORUnboxingError.incorrectType(type: type)
        }
        return result
    }

    func decode(_ cbor: CBOR, _ type: Int16.Type) throws -> Int16 {
        guard let result: Int16 = cbor.getIntegerValue() else {
            throw CBORUnboxingError.incorrectType(type: type)
        }
        return result
    }

    func decode(_ cbor: CBOR, _ type: Int32.Type) throws -> Int32 {
        guard let result: Int32 = cbor.getIntegerValue() else {
            throw CBORUnboxingError.incorrectType(type: type)
        }
        return result
    }

    func decode(_ cbor: CBOR, _ type: Int64.Type) throws -> Int64 {
        guard let result: Int64 = cbor.getIntegerValue() else {
            throw CBORUnboxingError.incorrectType(type: type)
        }
        return result
    }

    func decode(_ cbor: CBOR, _ type: UInt.Type) throws -> UInt {
        guard let result: UInt = cbor.getIntegerValue() else {
            throw CBORUnboxingError.incorrectType(type: type)
        }
        return result
    }

    func decode(_ cbor: CBOR, _ type: UInt8.Type) throws -> UInt8 {
        guard let result: UInt8 = cbor.getIntegerValue() else {
            throw CBORUnboxingError.incorrectType(type: type)
        }
        return result
    }

    func decode(_ cbor: CBOR, _ type: UInt16.Type) throws -> UInt16 {
        guard let result: UInt16 = cbor.getIntegerValue() else {
            throw CBORUnboxingError.incorrectType(type: type)
        }
        return result
    }

    func decode(_ cbor: CBOR, _ type: UInt32.Type) throws -> UInt32 {
        guard let result: UInt32 = cbor.getIntegerValue() else {
            throw CBORUnboxingError.incorrectType(type: type)
        }
        return result
    }

    func decode(_ cbor: CBOR, _ type: UInt64.Type) throws -> UInt64 {
        guard let result: UInt64 = cbor.getIntegerValue() else {
            throw CBORUnboxingError.incorrectType(type: type)
        }
        return result
    }

    // swiftlint:disable force_cast
    func decodeDecodable<T>(_ cbor: CBOR, _ type: T.Type) throws -> T where T: Decodable {
        switch type {
        case is Date.Type:
            return try dateDecodingStrategy.decode(cbor) { ActiveCBORDecoder(unboxer: self, cbor: cbor) } as! T
        case is CBOR.Type:
            return cbor as! T
        case is Data.Type:
            guard let data = cbor.dataValue else {
                throw CBORUnboxingError.incorrectType(type: Data.self)
            }
            return data as! T
        case is [UInt8].Type:
            guard let data = cbor.dataValue else {
                throw CBORUnboxingError.incorrectType(type: Data.self)
            }
            return [UInt8](data) as! T
        case is URL.Type:
            guard let text = cbor.stringValue else {
                throw CBORUnboxingError.incorrectType(type: URL.self)
            }
            guard let url = URL(string: text) else {
                throw CBORUnboxingError.incorrectlyFormattedURL
            }
            return url as! T
        default:
            let decoder = ActiveCBORDecoder(unboxer: self, cbor: cbor)
            return try type.init(from: decoder)
        }
    }
}
