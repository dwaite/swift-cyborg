//
//  File.swift
//  
//
//  Created by David Waite on 6/17/23.
//

import NIOCore

extension DataItemHeader {
    
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

    private static func cborFromEtc(_ additionalInfo: DataItemHeader.AdditionalInfo?, from buffer: inout ByteBuffer) throws ->
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
    
    private func writeSV(_ sizedValue: DataItemHeader.SizedValue?, _ majorType: DataItemHeader.MajorType, into buffer: inout ByteBuffer) {
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

extension DataItemHeader.SimpleValue {
    func write(into buffer: inout ByteBuffer) {
        if rawValue < 24 {
            buffer.writeInteger(DataItemHeader.MajorType.etc.rawValue | rawValue)
        } else {
            buffer.writeInteger(DataItemHeader.MajorType.etc.rawValue | DataItemHeader.AdditionalInfo.uint8Following.rawValue)
            buffer.writeInteger(rawValue)
        }
    }
}

extension DataItemHeader.FloatValue {
    func write(into buffer: inout ByteBuffer) {
        switch self {
        case .half(let value):
            buffer.writeInteger(DataItemHeader.MajorType.etc.rawValue | DataItemHeader.AdditionalInfo.uint16Following.rawValue)
            buffer.writeInteger(value)
        case .float(let float):
            buffer.writeInteger(DataItemHeader.MajorType.etc.rawValue | DataItemHeader.AdditionalInfo.uint32Following.rawValue)
            buffer.writeInteger(float.bitPattern)
        case .double(let double):
            buffer.writeInteger(DataItemHeader.MajorType.etc.rawValue | DataItemHeader.AdditionalInfo.uint64Following.rawValue)
            buffer.writeInteger(double.bitPattern)
        }
    }
}

extension DataItemHeader.SizedValue {
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
            let immediate = DataItemHeader.ImmediateValue(info)!
            self = .immediate(immediate)
        }
    }
    
    func write(_ majorType: DataItemHeader.MajorType, into buffer: inout ByteBuffer) {
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
