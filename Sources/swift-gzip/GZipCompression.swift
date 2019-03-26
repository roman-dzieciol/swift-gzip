//
//  GZipCompression.swift
//  swift-gzip
//
//  Created by Roman Dzieciol on 3/26/19.
//

import Foundation
import Compression


@available(OSX 10.11, *)
final public class GZipCompression {
    public init() {
    }

    public static  func decompress(compressionMethod: GZipArchive.CompressionMethod,
                                   compressedData: Data,
                                   uncompressedSize: UInt32) throws -> Data {

        if compressionMethod != .deflate {
            fatalError("compressionMethod: \(compressionMethod)")
        }

        let decodedCapacity = Int(uncompressedSize)
        let decodedDestinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: decodedCapacity)
        let bytesWritten = compressedData.withUnsafeBytes { (compressedBuffer) -> Int in
            return compression_decode_buffer(decodedDestinationBuffer,
                                             decodedCapacity,
                                             compressedBuffer,
                                             compressedData.count,
                                             nil,
                                             COMPRESSION_ZLIB)
        }

        guard bytesWritten == decodedCapacity else {
            fatalError("bytesWritten: \(bytesWritten) decodedCapacity: \(decodedCapacity)")
        }

        return Data(bytes: decodedDestinationBuffer, count: decodedCapacity)
    }
}
