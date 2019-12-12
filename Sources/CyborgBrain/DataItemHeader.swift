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

import NIO

/// Represents a CBOR ['Data Item Head'](https://tools.ietf.org/html/draft-ietf-cbor-7049bis-09#section-2.2).
///
/// The enumeration is structured roughly in line with the major types, with specialty data types to preserve the
/// different encodings, without necessarily normalizing them. In the case of `SimpleValue` and `ImmediateValue`,
/// the types also enforce legal values to prevent inconsistencies in tooling
//swiftlint:disable:next type_body_length
public enum DataItemHeader: Hashable {
    case unsignedInteger(SizedValue)
    case negativeInteger(data: SizedValue)
    case byteString(length: SizedValue?)
    case utf8TextString(length: SizedValue?)
    case array(count: SizedValue?)
    case object(pairs: SizedValue?)
    // swiftlint:disable:next identifier_name
    case tag(id: SizedValue)
    case simple(SimpleValue)
    case floatingPoint(FloatValue)
    case `break`

    public struct ImmediateValue: RawRepresentable, Hashable {
        public let rawValue: UInt8
        public init?(rawValue: UInt8) {
            guard rawValue < 24 else {
                return nil
            }
            self.rawValue = rawValue
        }

        init?(_ info: DataItemHeader.AdditionalInfo) {
            guard let immediate = info.immediateValue else {
                return nil
            }
            self.rawValue = immediate
        }
    }

    public struct SimpleValue: RawRepresentable, Hashable {
        public let rawValue: UInt8

        public init?(rawValue: UInt8) {
            guard !(24..<32).contains(rawValue) else {
                return nil // values from 24 up to 32 are invalid
            }
            self.rawValue = rawValue
        }

        public init(_ immediate: ImmediateValue) {
            self.rawValue = immediate.rawValue
        }

        func write(into buffer: inout ByteBuffer) {
            if rawValue < 24 {
                buffer.writeInteger(MajorType.etc.rawValue | rawValue)
            } else {
                buffer.writeInteger(MajorType.etc.rawValue | AdditionalInfo.uint8Following.rawValue)
                buffer.writeInteger(rawValue)
            }
        }
    }

    public enum FloatValue: Hashable {
        case half(UInt16)
        case float(Float)
        case double(Double)

        func write(into buffer: inout ByteBuffer) {
            switch self {
            case .half(let value):
                buffer.writeInteger(MajorType.etc.rawValue | AdditionalInfo.uint16Following.rawValue)
                buffer.writeInteger(value)
            case .float(let float):
                buffer.writeInteger(MajorType.etc.rawValue | AdditionalInfo.uint32Following.rawValue)
                buffer.writeInteger(float.bitPattern)
            case .double(let double):
                buffer.writeInteger(MajorType.etc.rawValue | AdditionalInfo.uint64Following.rawValue)
                buffer.writeInteger(double.bitPattern)
            }
        }
    }

    public enum SizedValue: Hashable {
        case immediate(ImmediateValue)
        case uint8(UInt8)
        case uint16(UInt16)
        case uint32(UInt32)
        case uint64(UInt64)

        init(info: DataItemHeader.AdditionalInfo, from buffer: inout ByteBuffer) throws {
            switch info {
            case .uint8Following:
                guard let uint8: UInt8 = buffer.readInteger() else {
                    throw DeserializationError.endOfStream(offset: buffer.readerIndex)
                }
                self = .uint8(uint8)
                return
            case .uint16Following:
                guard let u16: UInt16 = buffer.readInteger() else {
                    throw DeserializationError.endOfStream(offset: buffer.readerIndex)
                }
                self = .uint16(u16)
                return
            case .uint32Following:
                guard let u32: UInt32 = buffer.readInteger() else {
                    throw DeserializationError.endOfStream(offset: buffer.readerIndex)
                }

                self = .uint32(u32)
                return
            case .uint64Following:
                guard let u64: UInt64 = buffer.readInteger() else {
                    throw DeserializationError.endOfStream(offset: buffer.readerIndex)
                }
                self = .uint64(u64)
                return
            default:
                let immediate = ImmediateValue(info)!
                self = .immediate(immediate)
            }
        }

        public var value: UInt64 {
            switch self {
            case .immediate(let value):
                return UInt64(value.rawValue)
            case .uint8(let value):
                return UInt64(value)
            case .uint16(let value):
                return UInt64(value)
            case .uint32(let value):
                return UInt64(value)
            case .uint64(let value):
                return UInt64(value)
            }
        }

        var additionalInfo: AdditionalInfo {
            switch self {
            case .immediate(let value):
                return AdditionalInfo(value)
            case .uint8:
                return .uint8Following
            case .uint16:
                return .uint16Following
            case .uint32:
                return .uint32Following
            case .uint64:
                return .uint64Following
            }
        }

        public func normalized() -> Self {
            let u64 = value
            if let value = UInt8(exactly: u64) {
                if let immediate = ImmediateValue(rawValue: value) {
                    return .immediate(immediate)
                }
                return .uint8(value)
            }
            if let value = UInt16(exactly: u64) {
                return .uint16(value)
            }
            if let value = UInt32(exactly: u64) {
                return .uint32(value)
            }
            return .uint64(u64)
        }

        func write(_ majorType: MajorType, into buffer: inout ByteBuffer) {
            let info = additionalInfo
            let initialByte = majorType.rawValue | info.rawValue
            buffer.writeInteger(initialByte)
            switch self {
            case .immediate:
                break // already done above
            case .uint8(let value):
                buffer.writeInteger(value)
            case .uint16(let value):
                buffer.writeInteger(value)
            case .uint32(let value):
                buffer.writeInteger(value)
            case .uint64(let value):
                buffer.writeInteger(value)
            }
        }
    }

    enum MajorType: UInt8, RawRepresentable, Hashable {
        case unsignedInteger = 0x00
        case negativeInteger = 0x20
        case byteString      = 0x40
        case utf8TextString  = 0x60
        case array           = 0x80
        case object          = 0xa0
        case tag             = 0xc0
        case etc             = 0xe0

        var allowsIndefiniteOrBreak: Bool {
            switch self {
            case .unsignedInteger, .negativeInteger, .tag:
                return false
            default:
                return true
            }
        }

        init(initialByte: UInt8) {
            self.init(rawValue: initialByte & 0xe0)!
        }
    }

    struct AdditionalInfo: RawRepresentable, Hashable {
        let rawValue: UInt8

        static let uint8Following    = Self(rawValue: 0x18)!
        static let uint16Following   = Self(rawValue: 0x19)!
        static let uint32Following   = Self(rawValue: 0x1a)!
        static let uint64Following   = Self(rawValue: 0x1b)!

        public var immediateValue: UInt8? {
            guard (0..<24).contains(rawValue) else {
                return nil
            }
            return rawValue
        }

        public init?(rawValue: UInt8) {
            guard rawValue & 0xe0 == 0,
            rawValue <= 0x1b else {
                return nil
            }
            self.rawValue = rawValue
        }

        public init?(initialByte: UInt8) {
            self.init(rawValue: initialByte & 0x1f)
        }

        public init(_ value: ImmediateValue) {
            self.rawValue = value.rawValue
        }

        public init(immediate value: UInt8) {
            guard value < 24 else {
                fatalError("immediate values must be in the range 0...24")
            }
            self.rawValue = value
        }
    }

    public init(from buffer: inout ByteBuffer) throws {
        guard let initialByte: UInt8 = buffer.readInteger() else {
            throw DeserializationError.endOfStream(offset: buffer.readerIndex)
        }

        let majorType = MajorType(initialByte: initialByte)
        let additionalInfo = AdditionalInfo(initialByte: initialByte)
        switch (majorType, additionalInfo) {
        case (.unsignedInteger, let info?):
            self = .unsignedInteger(try SizedValue(info: info, from: &buffer))
        case (.negativeInteger, let info?):
            self = .negativeInteger(data: try SizedValue(info: info, from: &buffer))
        case (.byteString, let info):
            self = .byteString(length: try info.map { try SizedValue(info: $0, from: &buffer) })
        case (.utf8TextString, let info):
            self = .utf8TextString(length: try info.map { try SizedValue(info: $0, from: &buffer) })
        case (.array, let info):
            self = .array(count: try info.map { try SizedValue(info: $0, from: &buffer) })
        case (.object, let info):
            self = .object(pairs: try info.map { try SizedValue(info: $0, from: &buffer) })
        case (.tag, let info?):
            self = .tag(id: try SizedValue(info: info, from: &buffer))
        case (.etc, let info):
            self = try .cborFromEtc(info, from: &buffer)
        default:
            throw WellFormednessError.unknownInitialByte(initialByte: initialByte, offset: buffer.readerIndex)
        }
    }

    private static func cborFromEtc(_ additionalInfo: AdditionalInfo?, from buffer: inout ByteBuffer) throws ->
        DataItemHeader {
        guard let additionalInfo = additionalInfo else {
            return .break
        }
        let sizedValue = try SizedValue(info: additionalInfo, from: &buffer)
        switch sizedValue {
        case .immediate(let value):
            return .simple(SimpleValue(value))
        case .uint8(let value):
            guard let simpleValue = SimpleValue(rawValue: value) else {
                throw WellFormednessError.invalidSimpleValue(value: value, offset: buffer.readerIndex)
            }
            return .simple(simpleValue)
        case .uint16(let value):
            return .floatingPoint(.half(value))
        case .uint32(let value):
            return .floatingPoint(.float(Float(bitPattern: value)))
        case .uint64(let value):
            return .floatingPoint(.double(Double(bitPattern: value)))
        }
    }

    public var isCompleteDataItem: Bool {
        switch self {
        case .negativeInteger, .unsignedInteger, .simple, .floatingPoint:
            return true
        case .array(let sizedValue?),
             .byteString(let sizedValue?),
             .object(let sizedValue?),
             .utf8TextString(let sizedValue?):
            return sizedValue.value == 0
        case .break, .tag:
            return false
        default:
            return false
        }
    }

    public static let `false`         = Self.simple(SimpleValue(rawValue: 0x14)!)
    public static let `true`          = Self.simple(SimpleValue(rawValue: 0x15)!)
    public static let null            = Self.simple(SimpleValue(rawValue: 0x16)!)
    public static let undefined       = Self.simple(SimpleValue(rawValue: 0x17)!)

    func writeSV(_ sizedValue: SizedValue?, _ majorType: MajorType, into buffer: inout ByteBuffer) {
        guard let sizedValue = sizedValue else {
            buffer.writeInteger(majorType.rawValue | 0x1f)
            return
        }
        sizedValue.write(majorType, into: &buffer)
    }

    public func write(into buffer: inout ByteBuffer) {
        switch self {
        case .unsignedInteger(let sizedValue):
            sizedValue.write(.unsignedInteger, into: &buffer)
        case .negativeInteger(let sizedValue):
            sizedValue.write(.negativeInteger, into: &buffer)
        case .byteString(let sizedValue):
            writeSV(sizedValue, .byteString, into: &buffer)
        case .utf8TextString(let sizedValue):
            writeSV(sizedValue, .utf8TextString, into: &buffer)
        case .array(let sizedValue):
            writeSV(sizedValue, .array, into: &buffer)
        case .object(let sizedValue):
            writeSV(sizedValue, .object, into: &buffer)
        case .tag(let tag):
            tag.write(.tag, into: &buffer)
        case .simple(let simple):
            simple.write(into: &buffer)
        case .floatingPoint(let floatValue):
            floatValue.write(into: &buffer)
        case .break:
            buffer.writeInteger(0xff as UInt8)
        }
    }
}

extension DataItemHeader.SizedValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: UInt64) {
        self = Self.uint64(value).normalized()
    }

    public init(_ source: UInt64) {
        self.init(integerLiteral: source)
    }
}

extension DataItemHeader: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        if value >= 0 {
            self = .unsignedInteger(SizedValue(UInt64(value)))
        } else {
            self = .negativeInteger(data: SizedValue(UInt64(~value)))
        }
    }

    public init(_ source: Int) {
        self.init(integerLiteral: source)
    }
}
