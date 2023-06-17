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
import NIOFoundationCompat
import NIO

// We both mark the interface as `Codable` to work properly with the `Encoder`
// and `Decoder` types, and provide default implementations which delegate to
// data - so a `CBOR` object encoded via `JSONEncoder` should result in base64-
// encoded CBOR.
extension CBOR: Codable {
    public func encode(to encoder: any Encoder) throws {
        let serializer = Serializer(deterministicObjectOrder: true)
        var buffer = ByteBufferAllocator().buffer(capacity: 64)
        try serializer.serialize(self, into: &buffer)
        let data = buffer.readData(length: buffer.readableBytes)
        try data.encode(to: encoder)
    }

    public init(from decoder: any Decoder) throws {
        let data = try decoder.singleValueContainer().decode(Data.self)
        var buffer = ByteBufferAllocator().buffer(capacity: data.count)
        buffer.writeBytes(data)

        let deserializer = Deserializer()
        self = try deserializer.deserialize(from: &buffer)
    }

}
