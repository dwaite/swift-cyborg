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
import NIO
import NIOFoundationCompat

#if MODULAR_DEVELOPMENT
import Cyborg
#endif

public struct CBOREncoder {
    public var cborDocumentTag: Bool = false
    public var deterministicObjectOrder: Bool = true

    private var valueEncoder: CBORValueEncoder

    public init() {
        valueEncoder = CBORValueEncoder()
    }
    public var userInfo: [CodingUserInfoKey: Any] {
        get {
            valueEncoder.userInfo
        }
        set {
            valueEncoder.userInfo = newValue
        }
    }

    public var dateEncodingStrategy: DateEncodingStrategy {
        get {
            valueEncoder.dateEncodingStrategy
        }
        set {
            valueEncoder.dateEncodingStrategy = newValue
        }
    }

    public func encode<T: Encodable>(_ value: T) throws -> Data {
        var cbor = try valueEncoder.encode(value)
        if cborDocumentTag {
            cbor = .tagged(tag: .cborSelfDescription, value: cbor)
        }
        let serializer = Serializer(deterministicObjectOrder: deterministicObjectOrder)
        var buffer = ByteBufferAllocator().buffer(capacity: 64)
        try serializer.serialize(cbor, into: &buffer)
        return buffer.readData(length: buffer.readableBytes)!
    }

    public func encode<T: Encodable>(_ value: T, into buffer: inout ByteBuffer) throws {
        var cbor = try valueEncoder.encode(value)
        if cborDocumentTag {
            cbor = .tagged(tag: .cborSelfDescription, value: cbor)
        }
        let serializer = Serializer(deterministicObjectOrder: deterministicObjectOrder)
        try serializer.serialize(cbor, into: &buffer)
    }
}


#if canImport(Combine)
import Combine

extension CBOREncoder: TopLevelEncoder {
}
#endif
