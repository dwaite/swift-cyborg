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

/// The strategy to use for encoding `Date` values.
public enum DateEncodingStrategy {
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
    case custom(_ encodingFunction: (_:Date, _:Encoder) throws -> Void)

    func encode(_ date: Date, _ encoder: () -> ActiveCBOREncoder) throws -> CBOR {
        switch self {
        case .secondsSince1970:
            return Self.encodeSecondsSince1970(date)
        case .millisecondsSince1970:
            return Self.encodeMillisecondsSince1970(date)
        case .taggedSecondsSince1970:
            return Self.encodeTaggedSecondsSince1970(date)
        case .iso8601:
            return Self.encodeISO8609(date)
        case .taggedISO8601:
            return Self.encodeTaggedISO8609(date)
        case .formatted(let formatter):
            return CBOR.string(formatter.string(from: date))
        case .deferredToDate:
            let dateEncoder = encoder()
            try date.encode(to: dateEncoder)
            return dateEncoder.finalize()
        case .custom(let encodingFunction):
            let dateEncoder = encoder()
            try encodingFunction(date, dateEncoder)
            return dateEncoder.finalize()
        }
    }

    static func encodeSecondsSince1970( _ date: Date) -> CBOR {
        return CBOR(floatLiteral: date.timeIntervalSince1970)
    }

    static func encodeMillisecondsSince1970( _ date: Date) -> CBOR {
        return CBOR(floatLiteral: date.timeIntervalSince1970 * 1000)
    }

    static func encodeTaggedSecondsSince1970( _ date: Date) -> CBOR {
        return CBOR.tagged(tag: .secondsSinceEpoch, value: encodeSecondsSince1970(date))
    }

    static func encodeISO8609( _ date: Date) -> CBOR {
        return CBOR.string(ISO8601DateFormatter().string(from: date))
    }

    static func encodeTaggedISO8609(_ date: Date) -> CBOR {
        return CBOR.tagged(tag: .dateTimeString, value: encodeISO8609(date))
    }
}
