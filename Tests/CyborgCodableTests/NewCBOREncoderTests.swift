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

@testable import Cyborg

#if canImport(CyborgCodable)
@testable import CyborgCodable
#endif

struct Car: Codable, Hashable {
    var make: String
    var model: String
    var year: Int
    var edition: String?
}

struct Dealership: Codable, Hashable {
    var name: String
    var cars: [Car]
}

class NewCBOREncoderTests: XCTestCase {
    var dealership: Dealership!

    override func setUp() {
       let car = Car(make: "Jeep", model: "Wrangler", year: 2001)
       let car2 = Car(make: "Jeep", model: "Cherokee", year: 2012)
       dealership = Dealership(name: "Paul's Jeep-o-rama", cars: [car, car2])
    }

    override func tearDown() {
    }

    func testValueRoundTrip() throws {
        let encoder = CBORValueEncoder()
        let encoded = try encoder.encode(dealership)
        let decoder = CBORValueDecoder()
        let decoded = try decoder.decode(encoded, type: Dealership.self)
        XCTAssert(dealership == decoded)
    }

    func testDataRoundTrip() throws {
         let encoder = CBOREncoder()
         let encoded = try encoder.encode(dealership)
         let decoder = CBORDecoder()
         let decoded = try decoder.decode(encoded, type: Dealership.self)
         XCTAssert(dealership == decoded)
     }

}
