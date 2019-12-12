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

import NIO
import NIOFoundationCompat

public struct CBORDecoder {
    public var requireCBORDocumentTag: Bool
    public var dateDecodingStrategy: DateDecodingStrategy

    var unboxer: CBORUnboxer

    var userInfo: [CodingUserInfoKey: Any] {
        get {
            unboxer.userInfo
        }
        set {
            unboxer.userInfo = newValue
        }
    }

    public init() {
        requireCBORDocumentTag = false
        dateDecodingStrategy = .secondsSince1970
        unboxer = CBORUnboxer()
    }

    public func decode<T: Decodable>(from buffer: inout ByteBuffer, type: T.Type) throws -> T {
        let deserializer = Deserializer()
        var cbor = try deserializer.deserialize(from: &buffer)
        var tagged = false
        if case .tagged(Tag.cborSelfDescription, let value) = cbor {
            tagged = true
            cbor = value
        }
        if !tagged && requireCBORDocumentTag {
            throw CBORDecoderError.expectedCBORDocumentTag
        }

        var decoder = CBORValueDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        return try decoder.decode(cbor, type: type)

    }

    public func decode<T: Decodable>(_ data: Data, type: T.Type) throws -> T {
        var buffer = ByteBufferAllocator().buffer(capacity: data.count)
        buffer.writeBytes(data)
        return try decode(from: &buffer, type: type)
    }
}
