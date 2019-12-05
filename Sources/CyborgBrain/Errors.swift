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

public enum DeserializationError: Error {
    case endOfStream(offset: Int)
    case invalidUTF8(startingAt: Int)
    case negativeIntegerOverflow(offset: Int)
    case positiveIntegerOverflow(offset: Int)
}

public enum WellFormednessError: Error {
    case unknownInitialByte(ib: UInt8, offset: Int)
    case invalidSimpleValue(value: UInt8, offset: Int)
    case unexpectedBreak(offset: Int)
    case invalidIndefiniteChunk(offset: Int)
}

public enum SerializationError: Error {
    case bigIntTooLarge
}
