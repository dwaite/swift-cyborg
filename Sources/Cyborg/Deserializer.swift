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

import NIOFoundationCompat
public struct Deserializer {
    public init() {}

    public func deserialize(from buffer: inout ByteBuffer) throws -> CBOR {
        let header = try DataItemHeader(from: &buffer)
        return try deserialize(header: header, from: &buffer)
    }
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    public func deserialize(header: DataItemHeader, from buffer: inout ByteBuffer) throws -> CBOR {
        switch header {
        case .unsignedInteger(let sizedValue):
            guard let value = CBOR.init(exactly: sizedValue.value) else {
                throw DeserializationError.positiveIntegerOverflow(offset: buffer.readerIndex)
            }
            return value
        case .negativeInteger(let data):
#if canImport(BigInt)
            let bigInt = ~BigInt(data.value)
            return CBOR.init(bigInt)
#else
            if data.value > Int.max {
                throw DeserializationError.negativeIntegerOverflow(offset: buffer.readerIndex)
            }
            return CBOR.int(~Int(data.value))
#endif
        case .byteString(let length?):
            guard let data = buffer.readData(length: Int(length.value)) else {
                throw DeserializationError.endOfStream(offset: buffer.readerIndex)
            }
            return CBOR.data(data)
        case .utf8TextString(let length?):
            let startingAt = buffer.readerIndex
            guard let data = buffer.readData(length: Int(length.value)) else {
                throw DeserializationError.endOfStream(offset: buffer.readerIndex)
            }
            guard let string = String(data: data, encoding: .utf8) else {
                throw DeserializationError.invalidUTF8(startingAt: startingAt)
            }
            return CBOR.string(string)
        case .array(let count?):
            return CBOR.array(try (0..<count.value).map { _ in
                try deserialize(from: &buffer)
            })
        case .object(let pairs?):
            return CBOR.object(Dictionary(uniqueKeysWithValues: try (0..<pairs.value).map { _ in
                try (deserialize(from: &buffer), deserialize(from: &buffer))
                }))
        case .tag(let tag):
            let value = try deserialize(from: &buffer)
            return CBOR.tagged(tag: Tag(rawValue: tag.value), value: value)
        case .simple(let value):
            return CBOR.simple(value: value.rawValue)
        case .floatingPoint(let value):
            switch value {
            case .double(let double):
                return CBOR.double(double)
            case .float(let float):
                return CBOR.double(Double(float))
            case .half(let half):
                fatalError("Cannot decode half-float \(half)")
            }
        case .break:
            throw WellFormednessError.unexpectedBreak(offset: buffer.readerIndex)

        case .byteString(.none):
            var result = Data()
            while true {
                let subheader = try DataItemHeader(from: &buffer)
                if subheader == .break {
                    return .data(result)
                }
                guard case .byteString(let value) = subheader,
                    let size = value else {
                        throw WellFormednessError.invalidIndefiniteChunk(offset: buffer.readerIndex)
                }
                guard let data = buffer.readData(length: Int(size.value)) else {
                    throw DeserializationError.endOfStream(offset: buffer.readerIndex)
                }
                result.append(data)
            }
        case .utf8TextString(.none):
            var result = Data()
            var offset = buffer.readerIndex
            while true {
                let subheader = try DataItemHeader(from: &buffer)
                if subheader == .break {
                    guard let string = String(data: result, encoding: .utf8) else {
                        throw DeserializationError.invalidUTF8(startingAt: offset)
                    }
                    return .string(string)
                }
                guard case .utf8TextString(let value) = subheader,
                    let size = value else {
                        throw WellFormednessError.invalidIndefiniteChunk(offset: buffer.readerIndex)
                }
                guard let data = buffer.readData(length: Int(size.value)) else {
                    throw DeserializationError.endOfStream(offset: buffer.readerIndex)
                }
                result.append(data)
                offset = buffer.readerIndex
            }
        case .array(.none):
            var array: [CBOR] = []
            while true {
                let subheader = try DataItemHeader(from: &buffer)
                if subheader == DataItemHeader.`break` {
                    return .array(array)
                }
                array.append(try deserialize(header: subheader, from: &buffer))
            }
        case .object(.none):
            var object: [CBOR: CBOR] = [:]
            while true {
                let subheader = try DataItemHeader(from: &buffer)
                if subheader == DataItemHeader.`break` {
                    return .object(object)
                }
                let key = try deserialize(header: subheader, from: &buffer)
                let value = try deserialize(from: &buffer)
                object[key] = value
            }
        }
    }
}
