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

import struct Foundation.Data
import NIO

#if canImport(CyborgBrain)
import CyborgBrain
#endif

#if canImport(BigInt)
import BigInt
#endif

extension DataItemHeader.SizedValue {
    internal init(_ source: Int) {
        guard let value = UInt64(exactly: source) else {
            fatalError("SizedValue initialized with negative number")
        }
        self.init(value)
    }
}

extension DataItemHeader {
#if canImport(BigInt)
    init?(_ source: BigInt) {
        if source >= 0 {
            guard let dih = UInt64(exactly: source) else {
                return nil
            }
            self = Self.unsignedInteger(SizedValue(dih))
        } else {
            guard let dih = UInt64(exactly: ~source) else {
                return nil
            }
            self = Self.negativeInteger(data: SizedValue(dih))
        }
    }
#endif
}

typealias SizedValue = DataItemHeader.SizedValue

public struct Serializer {
    /// Controls whether CBOR object keys are sorted into deterimistic (lexicographic) order. This has a
    /// performance and memory impact
    public var deterministicObjectOrder: Bool
    public init(deterministicObjectOrder: Bool = true) {
        self.deterministicObjectOrder = deterministicObjectOrder
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    public func serialize(_ cbor: CBOR, into buffer: inout ByteBuffer) throws {
        switch cbor {
        case .int(let value):
            DataItemHeader(value).write(into: &buffer)
#if canImport(BigInt)
        case .bigInt(let value):
            guard let dih = DataItemHeader(value) else {
                throw SerializationError.bigIntTooLarge
            }
            dih.write(into: &buffer)
#endif
        case .data(let data):
            DataItemHeader.byteString(length: SizedValue(data.count)).write(into: &buffer)
            buffer.writeBytes(data)
        case .string(let str):
            let data = str.data(using: .utf8)!
            DataItemHeader.utf8TextString(length: SizedValue(data.count)).write(into: &buffer)
            buffer.writeBytes(data)
        case .array(let array):
            DataItemHeader.array(count: SizedValue(array.count)).write(into: &buffer)
            for item in array {
                try serialize(item, into: &buffer)
            }
        case .object(let object):
            DataItemHeader.object(pairs: SizedValue(object.count)).write(into: &buffer)
            if !deterministicObjectOrder {
                // output keys in dictionary order, which will be inconsistent
                // across runs
                for (key, value) in object {
                    try serialize(key, into: &buffer)
                    try serialize(value, into: &buffer)
                }
            } else {
                // output keys in lexigographic order.

                // we do this by:
                // 1. writing the values while capturing the data (as views)
                // 2. sorting those views lexigogaphically
                // 3. create a new ByteBuffer the size of the written data
                // 4. write the sorted keys and values
                // 5. overwrite the values written in step 1 with the new buffer
                let writerStartIndex = buffer.writerIndex
                let kvs: [(ByteBufferView, ByteBufferView)] = try object.map { key, value in
                    let keyIndex = buffer.writerIndex
                    try serialize(key, into: &buffer)
                    let valueIndex = buffer.writerIndex
                    try serialize(value, into: &buffer)

                    return (
                        keyView: buffer.viewBytes(
                            at: keyIndex,
                            length: valueIndex - keyIndex)!,
                        valueView: buffer.viewBytes(
                            at: valueIndex,
                            length: buffer.writerIndex - valueIndex)!
                    )
                }.sorted {
                    $0.0.lexicographicallyPrecedes($1.0)
                }
                var tempBuffer = ByteBufferAllocator().buffer(capacity: buffer.writerIndex - writerStartIndex)
                for (keyView, valueView) in kvs {
                    tempBuffer.writeBytes(keyView)
                    tempBuffer.writeBytes(valueView)
                }
                buffer.moveWriterIndex(to: writerStartIndex)
                buffer.writeBuffer(&tempBuffer)
            }
        case .tagged(let tag, let value):
            DataItemHeader.tag(id: SizedValue(tag.rawValue)).write(into: &buffer)
            try serialize(value, into: &buffer)
        case .simple(let value):
            guard let simpleValue = DataItemHeader.SimpleValue(rawValue: value) else {
                throw WellFormednessError.invalidSimpleValue(value: value, offset: -1)
            }
            DataItemHeader.simple(simpleValue).write(into: &buffer)
        case .double(let double):
            DataItemHeader.floatingPoint(.double(double)).write(into: &buffer)
        }
    }
}
