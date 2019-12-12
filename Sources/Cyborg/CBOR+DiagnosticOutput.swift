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
public enum DiagnosticBinaryEncoding {
    case uppercaseHexadecimal
    case lowercaseHexadecimal
    case base32
    case base64
    case base64url

    private static let lowercaseHexadecimalAlphabet = "0123456789abcdef".unicodeScalars.map { $0 }
    private static let uppercaseHexadecimalAlphabet = "0123456789ABCDEF".unicodeScalars.map { $0 }
    private static let base32Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567".unicodeScalars.map { $0 }

    public func encode(_ value: Data) -> String {
        switch self {
        case .uppercaseHexadecimal:
            return "h'" + String(value.reduce(into: "".unicodeScalars, { (output, byte) in
                let value = Int(byte)
                output.append(DiagnosticBinaryEncoding.uppercaseHexadecimalAlphabet[value / 16])
                output.append(DiagnosticBinaryEncoding.uppercaseHexadecimalAlphabet[value % 16])
            })) + "'"
        case .lowercaseHexadecimal:
            return "h'" + String(value.reduce(into: "".unicodeScalars, { (output, byte) in
                let value = Int(byte)
                output.append(DiagnosticBinaryEncoding.lowercaseHexadecimalAlphabet[value / 16])
                output.append(DiagnosticBinaryEncoding.lowercaseHexadecimalAlphabet[value % 16])
            })) + "'"
        case .base64:
            return "b64'\(value.base64EncodedString())'"
        case .base64url:
            return "b64'\(b64ToB64Url(value.base64EncodedString()))'"
        case .base32:
            return "b32'\(base32Encode(value))'"
        }
    }
    // +========+========+========+========+========+
    // +11111222+22333334+44445555+56666677+77788888+

    //    size_t base32_encode(const uint8_t *data, size_t length, char *result, size_t bufSize) {

    private func base32Encode(_ value: Data) -> String {
        guard !value.isEmpty else {
            return ""
        }
        let length = value.count
        var result = "".unicodeScalars
        value.withUnsafeBytes { data in
            var buffer = data[0]
            var next = 1
            var bitsLeft = 8
            while bitsLeft > 0 || next < length {
                if bitsLeft < 5 {
                    if next < length {
                        buffer <<= 8
                        buffer |= data[next] & 0xFF
                        next += 1
                        bitsLeft += 8
                    } else {
                        let pad = 5 - bitsLeft
                        buffer <<= pad
                        bitsLeft += pad
                    }
                }
                let index = (buffer >> (bitsLeft - 5)) & UInt8(0x1F)
                bitsLeft -= 5
                result.append(DiagnosticBinaryEncoding.base32Alphabet[Int(index)])
            }
        }
        return String(result)
    }
    private func b64ToB64Url(_ value: String) -> String {
        return value.replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
}
extension CBOR: CustomStringConvertible {
    // Note: we skip the solidus/forward slash as it is not necessary
    private static let jsonStringEscapeDictionary = [
        0x08: "\\b",
        0x09: "\\t",
        0x0a: "\\n",
        0x0c: "\\f",
        0x0d: "\\r",
        0x5c: "\\\\",
        0x22: "\\\""
    ]

    //swiftlint:disable:next cyclomatic_complexity function_body_length
    public func diagnosticString(_ options: DiagnosticBinaryEncoding = .uppercaseHexadecimal) -> String {
        switch self {
        case .int(let value):
            return value.description
#if canImport(BigInt)
        case .bigInt(data: let value):
            return value.description
#endif
        case .true:
            return true.description
        case .false:
            return false.description
        case .null:
            return "null"
        case .undefined:
            return "undefined"
        case .double(let value):
            if value.isFinite {
                return value.description
            }
            if value == Double.infinity {
                return "Infinity"
            }
            if value == -Double.infinity {
                return "-Infinity"
            }
            return "NaN"
        case .tagged(let tag, let value):
            return "\(tag.rawValue)(\(value))"
        case .data(let value):
            return options.encode(value)
        case .simple(let value):
            return "simple\(value)"
        case .array(let value):
            return "[\(value.map({$0.description}).joined(separator: ","))]"
        case .object(let value):
            let joined = value.map { key, value in
                return "\(key):\(value)"
                }.joined(separator: ",")
            return "{\(joined)}"
        case .string(let value):
            var view = value.unicodeScalars
            view.indices.reversed().forEach { index in
                let scalar = view[index]
                if let escapedValue = CBOR.jsonStringEscapeDictionary[Int(scalar.value)] {
                    let after = view.index(after: index)
                    let range = index..<after
                    view.replaceSubrange(range, with: escapedValue.unicodeScalars)
                }
                if scalar.utf16.count > 1 {
                    let escapedValue = scalar.utf16.map { String(format: "\\u%04X", $0) }.joined()
                    let after = view.index(after: index)
                    let range = index..<after
                    view.replaceSubrange(range, with: escapedValue.unicodeScalars)
                }
            }
            return "\"\(String(view))\""
        }
    }

    public var description: String {
        return diagnosticString()
    }
}
