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
public extension CBOR {

    var intValue: Int? {
        return getIntegerValue()
    }

    func getIntegerValue<I>() -> I?
        where I: BinaryInteger {
        switch self {
        case .int(let value):
            if let result = I(exactly: value) {
                return result
            }
            return nil
#if canImport(BigIntModule)
        case .bigInt(let value):
            if let result = I(exactly: value) {
                return result
            }
            return nil
#endif
        case .double(let value):
            if let result = I(exactly: value) {
                return result
            }
            return nil
        default:
            return nil
        }
    }

    var dataValue: Data? {
        if case CBOR.data(let value) = self {
            return value
        }
        return nil
    }

    var stringValue: String? {
        if case CBOR.string(let value) = self {
            return value
        }
        return nil
    }

    var arrayValue: [CBOR]? {
        if case CBOR.array(let value) = self {
            return value
        }
        return nil
    }

    var objectValue: [CBOR: CBOR]? {
        if case CBOR.object(let value) = self {
            return value
        }
        return nil
    }

    var booleanValue: Bool? {
        switch self {
        case true:
            return true
        case false:
            return false
        default:
            return nil
        }
    }
    var doubleValue: Double? {
        return getFloatingPoint()
    }

    func getFloatingPoint<F>() -> F?
        where F: BinaryFloatingPoint {
        switch self {
        case .double(let value):
            return F(exactly: value)
        case .int(let value):
            return F(exactly: value)
#if canImport(BigIntModule)
        case .bigInt(let value):
            return F(exactly: value)
#endif
        default:
            return nil
        }
    }
}
