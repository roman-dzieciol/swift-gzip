//
//  GZipCompression.swift
//  swift-gzip
//
//  Created by Roman Dzieciol on 3/26/19.
//

import Foundation
import Compression

final public class GZipCompression {

    /// Minimum compression buffer size
    public static let minCompressBuffer = 1024
    
    public init() {
    }

    public static  func decompress(data inputData: Data, outputSize: UInt32, algorithm: compression_algorithm = COMPRESSION_ZLIB) throws -> Data {

        let outputBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(outputSize))
        let bytesWritten: Int = inputData.withUnsafeBytes { inputBytes in
            guard let inputPtr = inputBytes.bindMemory(to: UInt8.self).baseAddress else {
                return 0
            }
            return compression_decode_buffer(outputBytes,
                                             Int(outputSize),
                                             inputPtr,
                                             inputData.count,
                                             nil,
                                             algorithm)
        }

        guard (bytesWritten % Int(UInt32.max)) == outputSize else {
            throw GZipError.decodedLengthMismatch(bytesWritten, outputSize)
        }

        return Data(bytes: outputBytes, count: Int(outputSize))
    }

    public static func compress(data inputData: Data, algorithm: compression_algorithm = COMPRESSION_ZLIB) throws -> Data {
        let outputCapacity = max(GZipCompression.minCompressBuffer, inputData.count)
        let outputBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: outputCapacity)
        let bytesWritten: Int = inputData.withUnsafeBytes { (inputBytes: UnsafeRawBufferPointer) -> Int in
            guard let inputPtr = inputBytes.bindMemory(to: UInt8.self).baseAddress else {
                return 0
            }
            return compression_encode_buffer(outputBytes,
                                             outputCapacity,
                                             inputPtr,
                                             inputData.count,
                                             nil,
                                             algorithm)
        }
        guard bytesWritten != 0 else {
            throw GZipError.encodeFailed
        }
        return Data(bytes: outputBytes, count: bytesWritten)
    }
}
