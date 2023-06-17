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

#if MODULAR_DEVELOPMENT
import Cyborg
#endif

public enum DateConversionError: Error {
    case notStringInput
    case formatterConversionFailed
    case notFloatingPoint
    case expectedTagged
    case incorrectTag
}

/// The strategy to use for encoding `Date` values.
public enum DateDecodingStrategy {
    /// Defer to the Encodable implementation on Date
    case deferredToDate
    /// Encode the `Date` as a UNIX timestamp double.
    case secondsSince1970

    /// Encode the `Date` as a tagged UNIX timestamp double.
    case taggedSecondsSince1970

    /// Encode the `Date` as UNIX millisecond timestamp double.
    case millisecondsSince1970

    /// Encode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
    case iso8601

    /// Encode the `Date` as a tagged ISO-8601-formatted string (in RFC 3339 format).
    case taggedISO8601

    /// Encode the `Date` as a string, formatted by the given formatter.
    case formatted(DateFormatter)

    /// Encode the `Date` as a custom value encoded by the given closure.
    case custom(_ customFunction: (_: any Decoder) throws -> Date)

    func decode(_ cbor: CBOR, _ decoder: () -> ActiveCBORDecoder) throws -> Date {
        switch self {
        case .secondsSince1970:
            return try Self.decodeSecondsSince1970(cbor)
        case .millisecondsSince1970:
            return try Self.decodeMillisecondsSince1970(cbor)
        case .taggedSecondsSince1970:
            return try Self.decodeTaggedSecondsSince1970(cbor)
        case .iso8601:
            return try Self.decodeISO8609(cbor)
        case .taggedISO8601:
            return try Self.decodeTaggedISO8609(cbor)
        case .formatted(let formatter):
            guard case .string(let string) = cbor else {
                throw DateConversionError.notStringInput
            }
            guard let date = formatter.date(from: string) else {
                throw DateConversionError.formatterConversionFailed
            }
            return date
        case .deferredToDate:
            let dateDecoder = decoder()
            return try Date(from: dateDecoder)
        case .custom(let customFunction):
            let dateDecoder = decoder()
            return try customFunction(dateDecoder)
        }
    }

    static func decodeSecondsSince1970( _ cbor: CBOR) throws -> Date {
        guard case .double(let double) = cbor else {
            throw DateConversionError.notFloatingPoint
        }
        return Date(timeIntervalSince1970: double)
    }

    static func decodeMillisecondsSince1970( _ cbor: CBOR) throws -> Date {
        guard case .double(let double) = cbor else {
            throw DateConversionError.notFloatingPoint
        }
        return Date(timeIntervalSince1970: double * 1000)
    }

    static func decodeTaggedSecondsSince1970( _ cbor: CBOR) throws -> Date {
        guard case .tagged(let tag, let value) = cbor else {
            throw DateConversionError.expectedTagged
        }
        guard tag == Tag.secondsSinceEpoch else {
            throw DateConversionError.incorrectTag
        }
        return try decodeSecondsSince1970(value)
    }

    static func decodeISO8609( _ cbor: CBOR) throws -> Date {
        guard case .string(let string) = cbor else {
            throw DateConversionError.notStringInput
        }
        guard let date = ISO8601DateFormatter().date(from: string) else {
            throw DateConversionError.formatterConversionFailed
        }
        return date
    }

    static func decodeTaggedISO8609(_ cbor: CBOR) throws -> Date {
        guard case .tagged(let tag, let value) = cbor else {
            throw DateConversionError.expectedTagged
        }
        guard tag == Tag.dateTimeString else {
            throw DateConversionError.incorrectTag
        }
        return try decodeISO8609(value)
    }
}
