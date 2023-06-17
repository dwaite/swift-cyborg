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

extension CBOR: ExpressibleByNilLiteral,
    ExpressibleByArrayLiteral,
    ExpressibleByStringLiteral,
    ExpressibleByBooleanLiteral,
    ExpressibleByFloatLiteral,
    ExpressibleByIntegerLiteral,
    ExpressibleByDictionaryLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
    public init(arrayLiteral elements: CBOR...) {
        self = .array(elements)
    }
    public init(stringLiteral value: String) {
        self = .string(value)
    }
    public init(booleanLiteral value: Bool) {
        switch value {
        case false:
            self = .false
        case true:
            self = .true
        }
    }
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
    public init(dictionaryLiteral elements: (CBOR, CBOR)...) {
        self = .object(Dictionary(uniqueKeysWithValues: elements))
    }
}

extension CBOR {
    public init(_ dataItem: Data) {
        self = .data(dataItem)
    }
}

extension CBOR {
#if canImport(BigIntModule)
    public init<BI>(_ source: BI) where BI: BinaryInteger {
        if let int = Int(exactly: source) {
            self = .int(int)
        } else {
            self = .bigInt(BigInt(source))
        }
    }

    public init?<BI>(exactly source: BI) where BI: BinaryInteger {
        self.init(source)
    }

    public init<BI>(clamping source: BI) where BI: BinaryInteger {
        self.init(source)
    }

#else
    public init<BI>(_ source: BI) where BI: BinaryInteger {
        self = .int(Int(source))
    }

    public init?<BI>(exactly source: BI) where BI: BinaryInteger {
        if let int = Int(exactly: source) {
            self = .int(int)
        } else {
            return nil
        }
    }

    public init<BI>(clamping source: BI) where BI: BinaryInteger {
        self = .int(Int(clamping: source))
    }

#endif

    public init<BFP>(_ source: BFP) where BFP: BinaryFloatingPoint {
        self = .double(Double(source))
    }
}
