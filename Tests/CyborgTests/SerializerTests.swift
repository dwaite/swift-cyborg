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
import XCTest
import NIO

@testable import Cyborg
#if canImport(CyborgCodable)
@testable import CyborgCodable
#endif

func repeating<T>(_ value: T, count: Int) -> AnyIterator<T> {
    guard count >= 0 else {
        fatalError("count must be non-negative")
    }
    var counter = count
    return AnyIterator {
        guard counter > 0 else {
            return nil
        }
        counter = counter - 1
        return value
    }
}
extension Data {
    private static let hexAlphabet = "0123456789abcdef".unicodeScalars.map { $0 }
    
    public func hexEncodedString() -> String {
        return String(self.reduce(into: "".unicodeScalars, { (result, value) in
            result.append(Data.hexAlphabet[Int(value/16)])
            result.append(Data.hexAlphabet[Int(value%16)])
        }))
    }
}

class CBORSerializerTests: XCTestCase  {
    func testUnsignedIntegerValues() throws {
        let unsigned: CBOR = [0, 1, 4, 23, 0xff, 0x7fff_ffff_ffff_ffff]
        let serializer = Serializer()
        var buffer = ByteBufferAllocator().buffer(capacity: 32)
        try serializer.serialize(unsigned, into: &buffer)
        let serialized = buffer.readData(length: buffer.readableBytes)
        XCTAssertEqual(serialized, Data([
        0x86, 0x00, 0x01, 0x04, 0x17, 0x18, 0xff, 0x1b, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
        ]))
    }
    func testNegativeIntegerValues() throws {
        let signed: CBOR = [-1, -4, -24, -0x100, -0x8000_0000_0000_0000]
        let serializer = Serializer()
        var buffer = ByteBufferAllocator().buffer(capacity: 32)
        try serializer.serialize(signed, into: &buffer)
        let serialized = buffer.readData(length: buffer.readableBytes)
        XCTAssertEqual(serialized, Data([
        0x85, 0x20, 0x23, 0x37, 0x38, 0xff, 0x3b, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
        ]))
    }
    func testSimpleValues() throws {
        let simple: CBOR = [true, false, nil, .undefined, .simple(value: 0xff)]
        let serializer = Serializer()
        var buffer = ByteBufferAllocator().buffer(capacity: 32)
        try serializer.serialize(simple, into: &buffer)
        let serialized = buffer.readData(length: buffer.readableBytes)
        XCTAssertEqual(serialized, Data([
        0x85, 0xf5, 0xf4, 0xf6, 0xf7, 0xf8, 0xff]))
    }
    
    func testFloatValues() throws {
        var buffer = ByteBufferAllocator().buffer(capacity: 32)
        let serializer = Serializer()
        try serializer.serialize(0.0, into: &buffer)
        try serializer.serialize(.double(-.infinity), into: &buffer)
        let serialized = buffer.readData(length: buffer.readableBytes)
        // both are serialized into the same buffer. We do not compress floats
        // (at least yet) so both are 1+8 bytes
        XCTAssertEqual(serialized, Data([
        0xfb, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0xfb, 0xff, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]))
    }

    func testObjectValues() throws {
        let object: CBOR = [
            0:      0,
            10:     1,
            100:    2,
            -1:     3,
            "z":    4,
            "aa":   5,
            [100]:  6,
            [-1]:   7,
            false:  8,
            0.0:    9,
            -1.0:   10,
            .double(-.infinity): 11
        ]

        var serializer = Serializer()
        serializer.deterministicObjectOrder = false
        var buffer = ByteBufferAllocator().buffer(capacity: 32)

        try serializer.serialize(object, into: &buffer)
        let nonDeterministic = buffer.readData(length: buffer.readableBytes)
        buffer.clear()
        serializer.deterministicObjectOrder = true

        try serializer.serialize(object, into: &buffer)
        let deterministic = buffer.readData(length: buffer.readableBytes)
        
        // will fail 1:4096 runs - may add more keys to increase the odds
        XCTAssert(nonDeterministic != deterministic)
        
        let expected = Data([
            0xac,                                                // 12 pairs
            0x00, 0x00,                                          // 0:     0
            0x0a, 0x01,                                          // 10:    1
            0x18, 0x64, 0x2,                                     // 100:   2
            0x20, 0x3,                                           // -1:    3
            0x61, 0x7a, 0x4,                                     // "z":   4
            0x62, 0x61, 0x61, 0x5,                               // "aa":  5
            0x81, 0x18, 0x64, 0x6,                               // [100]: 6
            0x81, 0x20, 0x7,                                     // [-1]:  7
            0xf4, 0x8,                                           // false: 8
            0xfb, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x9,   // 0.0:   9
            0xfb, 0xbf, 0xf0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0xa, // -1.0:  10
            0xfb, 0xff, 0xf0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0xb  // -inf:  11
        ])
        
        XCTAssert(deterministic == expected)
    }
}
