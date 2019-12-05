Cyborg for Swift
=====

Cyborg is meant to be a comprehensive library for [CBOR](https://tools.ietf.org/html/rfc7049), providing multiple levels for working with this binary format:

- [CyborgBrain](./Sources/CyborgBrain), the lowest-level tools for working with binary data directly.
- [Cyborg](./Sources/Cyborg), an object model designed to be more directly usable by developers, plus tools to convert to and from binary data. Use this if you are leveraging CBOR data directly.
- [CyborgCodable](./Sources/CyborgCodable), support for encoding and decoding Swift objects into CBOR - either the object model or down to binary data.

There are two third-party runtime dependencies:

* [SwiftNIO](https://github.com/apple/swift-nio), used solely for its `ByteBuffer` type to more easily allow for parsing and writing CBOR data
* [BigInt](https://github.com/attaswift/BigInt), used to support the range of integer values that CBOR supports outside the range of `Swift.Int`. The library can be built without `BigInt`, in which case these larger values will return an `Error` while deserializing/decoding. The hope is to eventually depend upon [Swift Numerics](https://github.com/apple/swift-numerics) once [Arbitrary-precision Integers](https://github.com/apple/swift-numerics/issues/5) are added.