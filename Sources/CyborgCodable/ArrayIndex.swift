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

internal struct ArrayIndex: CodingKey {
    var index: Int

    var stringValue: String { String(index) }

    var intValue: Int? {
        get {
            index
        }
        set {
            guard let newValue = newValue else {
                fatalError("Must set actual index value")
            }
            index = newValue
        }
    }

    init?(stringValue: String) {
        fatalError("Only supports initialization with array index")
    }

    init(intValue: Int) {
        self.index = intValue
    }
}
