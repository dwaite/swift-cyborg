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
import XCTest

#if canImport(BigInt)
import BigInt
#endif

@testable import Cyborg

#if canImport(CyborgBrain)
@testable import CyborgBrain

typealias MajorType = DataItemHeader.MajorType
typealias AdditionalInfo = DataItemHeader.AdditionalInfo

#endif

public class DeserializerTests: XCTestCase {

    public func testDeserializePositiveIntegers() throws {
        var buffer = ByteBufferAllocator().buffer(capacity: 32)
        buffer.writeBytes([
            InitialByte(major: .array, info: nil).rawValue,
            0x00,               // 0x00 integer
            0x17,               // 0x17 integer
            0x18, 0xff,         // 0xff integer
            0x19, 0x12, 0x34,   // 0x1234 integer
            0x1a, 0x01, 0x02, 0x03, 0x04, // 0x01020304
            0x1b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // UInt64.max
            0xff // break
        ])

        let deserializer = Deserializer()
#if canImport(BigInt)
        let cbor = try deserializer.deserialize(from: &buffer)

        guard let array = cbor.arrayValue else {
            XCTAssert(false)
            return
        }

        XCTAssert(array.count == 6)
        XCTAssert(array[0].intValue == 0x00)
        XCTAssert(array[1].intValue == 0x17)
        XCTAssert(array[2].intValue == 0xff)
        XCTAssert(array[3].intValue == 0x1234)
        XCTAssert(array[4].intValue == 0x01020304)
        // last value has to be a bigint because > Int.max
        XCTAssertNil(array[5].intValue)
        guard case .bigInt(let bigInt) = array[5] else {
            XCTAssert(false)
            return
        }
        XCTAssert(bigInt == BigInt(UInt64.max))
#else
        XCTAssertThrowsError(try deserializer.deserialize(from: &buffer))
#endif
    }
    public func testDeserializeNegativeIntegers() throws {
        var buffer = ByteBufferAllocator().buffer(capacity: 32)
#if canImport(BigInt)
        buffer.writeBytes([
            InitialByte(major: .array, info: AdditionalInfo(immediate: 6)).rawValue,
            0x20,               // -0x01 integer
            0x37,               // -0x18 integer
            0x38, 0xff,         // -0x100 integer
            0x39, 0x12, 0x34,   // -0x1235 integer
            0x3a, 0x01, 0x02, 0x03, 0x04, // -0x01020305
            0x3b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff // -UInt64.max -1
        ])
#else
        buffer.writeBytes([
            InitialByte(major: .array, info: AdditionalInfo(immediate: 6)).rawValue,
            0x20,               // -0x01 integer
            0x37,               // -0x18 integer
            0x38, 0xff,         // -0x100 integer
            0x39, 0x12, 0x34,   // -0x1235 integer
            0x3a, 0x01, 0x02, 0x03, 0x04, // -0x01020305
            0x00 // 0, because no bigint
        ])
#endif
        let deserializer = Deserializer()
        let cbor = try deserializer.deserialize(from: &buffer)

        guard let array = cbor.arrayValue else {
            XCTAssert(false)
            return
        }

        XCTAssert(array.count == 6)
        XCTAssert(array[0].intValue == -1)
        XCTAssert(array[1].intValue == -24)
        XCTAssert(array[2].intValue == -256)
        XCTAssert(array[3].intValue == -0x1235)
        XCTAssert(array[4].intValue == -0x01020305)
#if canImport(BigInt)
        // last value has to be a bigint because < Int.min
        XCTAssertNil(array[5].intValue)
        guard case .bigInt(let bigInt) = array[5] else {
            XCTAssert(false)
            return
        }
        XCTAssert(bigInt == -1 - BigInt(UInt64.max))
#endif
    }

    public func testDeserializeEtcValues() throws {
        var buffer = ByteBufferAllocator().buffer(capacity: 32)
        buffer.writeBytes([
            InitialByte(major: .object, info: nil).rawValue, // indefinite object

            // false: true,
            InitialByte.false.rawValue, InitialByte.true.rawValue,

            // null: undefined,
            InitialByte.null.rawValue, InitialByte.undefined.rawValue,
            InitialByte(major: .etc, info: AdditionalInfo(immediate: 0)).rawValue,

            // Simple(0): Simple(0xff),
            InitialByte(major: .etc, info: .uint8Following).rawValue, 0xff,

            // Double(0x0000): Float.infinity
            InitialByte(major: .etc, info: .uint64Following).rawValue,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            InitialByte(major: .etc, info: .uint32Following).rawValue, 0x7f, 0x80, 0x00, 0x00,
            0xff //break
        ])

        let deserializer = Deserializer()
        let cbor = try deserializer.deserialize(from: &buffer)

        guard let object = cbor.objectValue else {
            XCTAssert(false)
            return
        }

        XCTAssert(object.count == 4)

        XCTAssert(object[false] == true)
        XCTAssert(object[nil] == CBOR.undefined)
        XCTAssert(object[CBOR.simple(value: 0)] == CBOR.simple(value: 0xff))
        XCTAssert(object[0.0] == .double(Double.infinity))
    }

    public func testDeserializeTaggedValues() throws {
        var buffer = ByteBufferAllocator().buffer(capacity: 32)
        buffer.writeBytes([
            InitialByte(major: .tag, info: .uint16Following).rawValue,
            0xd9, 0xf7,
            InitialByte(major: .tag, info: .init(immediate: 0x01)).rawValue,
            0x00
        ])
        let deserializer = Deserializer()
        let cbor = try deserializer.deserialize(from: &buffer)

        XCTAssert(cbor ==
            CBOR.tagged(tag: .cborSelfDescription,
                        value: .tagged(
                            tag: .secondsSinceEpoch,
                            value: 0)))
    }

    public func testRepeatedDeserialize() {
        var buffer = ByteBufferAllocator().buffer(capacity: 32)
        buffer.writeBytes([0, 1, 2 ])
        let deserializer = Deserializer()
        XCTAssert(try deserializer.deserialize(from: &buffer) == 0)
        XCTAssert(try deserializer.deserialize(from: &buffer) == 1)
        XCTAssert(try deserializer.deserialize(from: &buffer) == 2)
        XCTAssertThrowsError(
            try deserializer.deserialize(from: &buffer) // end of stream
        )
        buffer.clear()
        buffer.writeBytes([0x19, 0xff]) // half of a uint16
        XCTAssertThrowsError(
            try deserializer.deserialize(from: &buffer) // end of stream
        )
    }
}

struct InitialByte: RawRepresentable {
    let rawValue: UInt8

    init(rawValue: UInt8) {
        self.rawValue = rawValue
        if !major.allowsIndefiniteOrBreak && info == nil {
            fatalError("Invalid Initial Byte 0x\(String(rawValue, radix: 16))")
        }
    }

    init(major: MajorType, info: AdditionalInfo?) {
        let aiByte = info?.rawValue ?? 0x1f
        self.init(rawValue: major.rawValue | aiByte)
    }
    var major: MajorType {
        MajorType(initialByte: rawValue)
    }

    var info: AdditionalInfo? {
        AdditionalInfo(initialByte: rawValue)
    }

    static let `false` = Self(rawValue: 0xf4)
    static let `true` = Self(rawValue: 0xf5)
    static let null = Self(rawValue: 0xf6)
    static let undefined = Self(rawValue: 0xf7)
}
