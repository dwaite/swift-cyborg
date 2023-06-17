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

//swiftlint:disable identifier_name

import XCTest
import Foundation
import NIO

#if canImport(CwlPreconditionTesting)
import CwlPreconditionTesting
#endif

#if canImport(CyborgBrain)
@testable import CyborgBrain
#else
@testable import Cyborg
#endif

typealias ImmediateValue = DataItemHeader.ImmediateValue
typealias AdditionalInfo = DataItemHeader.AdditionalInfo
typealias SimpleValue    = DataItemHeader.SimpleValue
typealias MajorType      = DataItemHeader.MajorType
typealias FloatValue     = DataItemHeader.FloatValue
typealias SizedValue     = DataItemHeader.SizedValue

public class ImmediateValueTests: XCTestCase {
    func testInitialize() {
        let iv = ImmediateValue(rawValue: 0)
        XCTAssertNotNil(iv)
        XCTAssert(iv!.rawValue == 0)
    }

    func testInitializeTooLarge() {
        let iv = ImmediateValue(rawValue: 24)
        XCTAssertNil(iv)
    }

    func testInitializeWithAdditionalInfo() {
        let ai = AdditionalInfo(rawValue: 4)
        XCTAssertNotNil(ai)
        let iv = ImmediateValue.init(ai!)
        XCTAssertNotNil(iv)
        XCTAssert(iv!.rawValue == 4)
    }

    func testInitializeWithNotImmediateAdditionalInfo() {
        let ai = AdditionalInfo(rawValue: 0x18)
        XCTAssertNotNil(ai)
        let iv = ImmediateValue.init(ai!)
        XCTAssertNil(iv)
    }
}

public class AdditionalInfoTests: XCTestCase {
    func testInitializeWithRawValue() {
        var ai = AdditionalInfo(rawValue: 0)
        XCTAssertNotNil(ai)
        XCTAssert(ai!.immediateValue == 0)

        ai = AdditionalInfo(rawValue: 23)
        XCTAssertNotNil(ai)
        XCTAssert(ai!.immediateValue == 23)

        ai = AdditionalInfo(rawValue: 24)
        XCTAssertNotNil(ai)
        XCTAssertNil(ai!.immediateValue)
        XCTAssert(ai! == .uint8Following)

        ai = AdditionalInfo(rawValue: 25)
        XCTAssertNotNil(ai)
        XCTAssertNil(ai!.immediateValue)
        XCTAssert(ai! == .uint16Following)

        ai = AdditionalInfo(rawValue: 26)
        XCTAssertNotNil(ai)
        XCTAssertNil(ai!.immediateValue)
        XCTAssert(ai! == .uint32Following)

        ai = AdditionalInfo(rawValue: 27)
        XCTAssertNotNil(ai)
        XCTAssertNil(ai!.immediateValue)
        XCTAssert(ai! == .uint64Following)

        // indefinite value
        ai = AdditionalInfo(rawValue: 31)
        XCTAssertNil(ai)

        // reserved value
        ai = AdditionalInfo(rawValue: 28)
        XCTAssertNil(ai)

        // illegal value
        ai = AdditionalInfo(rawValue: 255)
        XCTAssertNil(ai)

    }

    func testInitializeWithIB() {
        let ai = AdditionalInfo(initialByte: 0xe1)
        XCTAssertNotNil(ai)
        XCTAssert(ai!.immediateValue == 1)
    }

    func testInitializeWithImmediate() {
        XCTAssert(AdditionalInfo(immediate: 23).rawValue == 23)
        #if !canImport(CwlPreconditionTesting)
        let e = catchBadInstruction {
            _ = AdditionalInfo(immediate: 24)
        }
        XCTAssertNotNil(e)
        #endif
    }

    func testInitializeWithImmediateValue() {
        let iv = ImmediateValue(rawValue: 23)
        XCTAssertNotNil(iv)
        let ai = AdditionalInfo(iv!)
        XCTAssert(ai.immediateValue == 23)
    }
}

public class SimpleValueTests: XCTestCase {
    func testInitializeWithImmediateValue() {
        let sv = SimpleValue(ImmediateValue(rawValue: 10)!)
        XCTAssert(sv.rawValue == 10)
    }
    func testInitializeWithRawValue() {
        var sv = SimpleValue(rawValue: 11)
        XCTAssert(sv != nil)
        XCTAssert(sv!.rawValue == 11)

        sv = SimpleValue(rawValue: 24)
        XCTAssertNil(sv)

        sv = SimpleValue(rawValue: 31)
        XCTAssertNil(sv)

        sv = SimpleValue(rawValue: 32)
        XCTAssertNotNil(sv)
    }

    func testWrite() {
        var buffer = ByteBufferAllocator().buffer(capacity: 1)
        let sv = SimpleValue(rawValue: 10)!
        sv.write(into: &buffer)
        XCTAssert(buffer.readInteger() == 0xea as UInt8)

        let sv2 = SimpleValue(rawValue: 64)!
        sv2.write(into: &buffer)
        XCTAssert(buffer.readInteger() == 0xf8 as UInt8)
        XCTAssert(buffer.readInteger() == 0x40 as UInt8)
    }
}

public class MajorTypeTests: XCTestCase {
    func testInitialize() {
        let major = MajorType(rawValue: 0xe0)
        XCTAssertNotNil(major)
        XCTAssert(major == MajorType.etc)
    }
    func testInitializeIllegalValue() {
        let major = MajorType(rawValue: 0xff)
        XCTAssertNil(major)
    }
    func testInitializeIB() {
        let major = MajorType(initialByte: 0x1f)
        XCTAssertNotNil(major)
        XCTAssert(major.rawValue == 0x00)
        XCTAssert(major == MajorType.unsignedInteger)
    }
    func testAllowsIndefiniteOrBreak() {
        XCTAssertFalse(MajorType.unsignedInteger.allowsIndefiniteOrBreak)
        XCTAssertTrue(MajorType.etc.allowsIndefiniteOrBreak)
    }
}

public class FloatValueTests: XCTestCase {
    func testWrite() {
        var buffer = ByteBufferAllocator().buffer(capacity: 16)
        let halfFloat = FloatValue.half(UInt16(0x1234))
        halfFloat.write(into: &buffer)

        XCTAssert(buffer.readInteger() == 0xf9 as UInt8)
        XCTAssert(buffer.readInteger() == 0x12 as UInt8)
        XCTAssert(buffer.readInteger() == 0x34 as UInt8)

        let float = FloatValue.float(0)
        float.write(into: &buffer)

        XCTAssert(buffer.readInteger() == 0xfa as UInt8)
        XCTAssert(buffer.readInteger() == 0 as UInt32)

        let double = FloatValue.double(.infinity)
        double.write(into: &buffer)
        XCTAssert(buffer.readInteger() == 0xfb as UInt8)
        XCTAssert(buffer.readInteger() == 0x7ff0_0000_0000_0000 as UInt64)
    }
}
public class SizedValueTests: XCTestCase {
    var svi, sv8, sv16, sv32, sv64: SizedValue!

    public override func setUp() {
        XCTAssertNoThrow( try {
            var buffer = ByteBufferAllocator().buffer(capacity: 10)
            self.svi = try SizedValue(info: AdditionalInfo(rawValue: 0x10)!, from: &buffer)

            buffer.writeInteger(0xff as UInt8)
            self.sv8 = try SizedValue(info: .uint8Following, from: &buffer)

            buffer.writeInteger(0x1234 as UInt16)
            self.sv16 = try SizedValue(info: .uint16Following, from: &buffer)

            buffer.writeInteger(0x12345678 as UInt32)
            self.sv32 = try SizedValue(info: .uint32Following, from: &buffer)

            buffer.writeInteger(0x12345678 as UInt64)
            self.sv64 = try SizedValue(info: .uint64Following, from: &buffer)
        }() )
    }
    func testInitializeViaLiteral() {
        let sv: SizedValue = 0
        XCTAssert(sv == .immediate(ImmediateValue(rawValue: 0)!))
    }
    func testInitializeWithBuffer() throws {
        XCTAssert(svi  == .immediate(ImmediateValue(rawValue: 0x10)!))
        XCTAssert(sv8  == .uint8(0xff))
        XCTAssert(sv16 == .uint16(0x1234))
        XCTAssert(sv32 == .uint32(0x12345678))
        XCTAssert(sv64 == .uint64(0x12345678))
    }

    func testValue() {
        XCTAssert(svi.value == 0x10)
        XCTAssert(sv8.value == 0xff)
        XCTAssert(sv16.value == 0x1234)
        XCTAssert(sv32.value == 0x12345678)
        XCTAssert(sv64.value == 0x12345678)
    }
    func testAdditionalInfo() {
        XCTAssert(svi.additionalInfo == AdditionalInfo(rawValue: 0x10))
        XCTAssert(sv8.additionalInfo == .uint8Following)
        XCTAssert(sv16.additionalInfo == .uint16Following)
        XCTAssert(sv32.additionalInfo == .uint32Following)
        XCTAssert(sv64.additionalInfo == .uint64Following)
    }

    func testNormalized() {
        XCTAssert(svi.normalized()  == .immediate(ImmediateValue(rawValue: 0x10)!))
        XCTAssert(sv8.normalized()  == .uint8(0xff))
        XCTAssert(sv16.normalized() == .uint16(0x1234))
        XCTAssert(sv32.normalized() == .uint32(0x12345678))
        XCTAssert(sv64.normalized() == .uint32(0x12345678))
        XCTAssert(SizedValue.uint64(1).normalized() == .immediate(ImmediateValue(rawValue: 0x01)!))
    }

    func testWrite() {
        var buffer = ByteBufferAllocator().buffer(capacity: 32)
        svi.write(.unsignedInteger, into: &buffer)
        XCTAssert(buffer.readInteger() == 0x10 as UInt8)

        sv8.write(.negativeInteger, into: &buffer)
        XCTAssert(buffer.readInteger() == 0x38ff as UInt16)

        sv16.write(.negativeInteger, into: &buffer)
        XCTAssert(buffer.readInteger() == 0x39 as UInt8)
        XCTAssert(buffer.readInteger() == 0x1234 as UInt16)

        sv32.write(.array, into: &buffer)
        XCTAssert(buffer.readInteger() == 0x9a as UInt8)
        XCTAssert(buffer.readInteger() == 0x12345678 as UInt32)

        sv64.write(.tag, into: &buffer)
        XCTAssert(buffer.readInteger() == 0xdb as UInt8)
        XCTAssert(buffer.readInteger() == 0x12345678 as UInt64)
    }
}
public class DataItemHeaderTest: XCTestCase {
    func testInitializeFromIntegerLiteral() {
        let min: DataItemHeader = -0x8000_0000_0000_0000
        let max: DataItemHeader = 0x7fff_ffff_ffff_ffff
        XCTAssert(max == DataItemHeader.unsignedInteger(.uint64(UInt64(Int.max))))
        XCTAssert(min == DataItemHeader.negativeInteger(data: .uint64(UInt64(Int.max))))
    }
    func testInitializeFromBuffer() throws {
        var buffer = ByteBufferAllocator().buffer(capacity: 32)

        // test document without any byte or text data to simplify parsing
        let document: [UInt8] =
            [
            0x9f, // indefinite-length array
            0x17,
            0x38, 0x01,
            0xd9, 0x12, 0x34,
            0xda, 0x00, 0x00, 0x03, 0x04,
            0xfb, 0x7f, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0xff
        ]
        buffer.writeBytes(document)
        let items = try (0..<7).map { _ in
            try DataItemHeader.init(from: &buffer)
        }
        XCTAssert(items[0] == .array(count: nil))
        XCTAssert(items[1] == .unsignedInteger(.immediate(ImmediateValue(rawValue: 0x17)!)))
        XCTAssert(items[2] == .negativeInteger(data: .uint8(0x01)))
        XCTAssert(items[3] == .tag(id: .uint16(0x1234)))
        XCTAssert(items[4] == .tag(id: .uint32(0x00000304)))
        XCTAssert(items[5] == .floatingPoint(.double(.infinity)))
        XCTAssert(items[6] == .break)

        // test round-trip
        items.forEach { item in
            item.write(into: &buffer)
        }
        let outputdocument = buffer.readBytes(length: buffer.readableBytes)!
        XCTAssert(outputdocument == document)
    }
}
