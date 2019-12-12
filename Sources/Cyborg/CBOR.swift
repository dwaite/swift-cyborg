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

/// General-purpose data structure to represent CBOR data.
public enum CBOR: Hashable, Equatable {
    case int(Int)
#if canImport(BigInt)
    case bigInt(BigInt)
#endif
    case data(Data)
    case string(String)
    case array([CBOR])
    case object([CBOR: CBOR])
    indirect case tagged(tag: Tag, value: CBOR)
    case simple(value: UInt8)
    case double(Double)

    public static let `false`   = CBOR.simple(value: 20)
    public static let `true`    = CBOR.simple(value: 21)
    public static let `null`    = CBOR.simple(value: 22)
    public static let undefined = CBOR.simple(value: 23)

    public static let zero      = CBOR.int(0)
    public static let one       = CBOR.int(1)
}
