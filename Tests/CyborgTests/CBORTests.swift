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

#if canImport(BigInt)
import BigInt
#endif

@testable import Cyborg

class CBORTests: XCTestCase {
    //ExpressibleByNilLiteral,
    //ExpressibleByArrayLiteral,
    //ExpressibleByStringLiteral,
    //ExpressibleByBooleanLiteral,
    //ExpressibleByFloatLiteral,
    //ExpressibleByIntegerLiteral,
    //ExpressibleByDictionaryLiteral
    func testLiteralInitialization() {
        let c:CBOR = [
            nil,
            1,
            false,
            "test",
            1.5,
            [
                "foo": "bar",
                1: "baz"
            ]
        ]
        
        guard let array = c.arrayValue else {
            XCTAssert(false)
            return
        }
        
        XCTAssert(array.count == 6)
        XCTAssert(array[0] == nil)
        XCTAssert(array[0] == CBOR.null)

        XCTAssert(array[1] == 1)
        XCTAssert(array[1] == .int(1))

        XCTAssert(array[2] == false)
        XCTAssert(array[2] == .false)

        XCTAssert(array[3] == "test")
        XCTAssert(array[3] == .string("test"))

        XCTAssert(array[4] == 1.5)
        XCTAssert(array[4] == .double(1.5))

        guard let object = array[5].objectValue else {
            XCTAssert(false)
            return
        }
        XCTAssert(object["foo"] == "bar")
        XCTAssert(object[1] == "baz")
    }
    
    func testOtherInitializers() {
#if canImport(BigInt)
        let c: CBOR = [
            CBOR(Data()),
            CBOR(BigInt(UInt64.max)),
        ]
#else
        let c: CBOR = [
            CBOR(Data()),
        ]
#endif

        guard let array = c.arrayValue else {
            XCTAssert(false)
            return
        }
        
        XCTAssert(array[0].dataValue == Data())
#if canImport(BigInt)
        XCTAssert(array[1] == CBOR.bigInt(BigInt(UInt64.max)))
#endif
    }
}
