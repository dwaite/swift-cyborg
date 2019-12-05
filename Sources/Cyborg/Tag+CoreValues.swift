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

public extension Tag {
    static let dateTimeString        = Tag(rawValue: 0)
    static let secondsSinceEpoch     = Tag(rawValue: 1)
    static let positiveBignum        = Tag(rawValue: 2)
    static let negativeBignum        = Tag(rawValue: 3)
    static let decimalFraction       = Tag(rawValue: 4)
    static let bigFloat              = Tag(rawValue: 5)

    static let expectedBase64Url     = Tag(rawValue: 21)
    static let expectedBase64        = Tag(rawValue: 22)
    static let expectedBase16        = Tag(rawValue: 23)
    static let encodedCBOR           = Tag(rawValue: 24)
    static let uri                   = Tag(rawValue: 32)
    static let base64UrlFormat       = Tag(rawValue: 33)
    static let base64Format          = Tag(rawValue: 34)
    static let regularExpression     = Tag(rawValue: 35)
    static let mimeMessage           = Tag(rawValue: 36)
    static let cborSelfDescription   = Tag(rawValue: 55799)
}
