//
//  GZipArchive.swift
//  XCActivityLog
//
//  Created by Roman Dzieciol on 3/26/19.
//

import Foundation
import Compression

@available(OSX 10.11, *)
final public class GZipArchive {

    public let magic: UInt16
    public let compressionMethod: CompressionMethod
    public let flags: Flags
    public let modificationTime: UInt32
    public let compressionFlags: UInt8
    public let osType: UInt8

    public let partNumber: UInt16?
    public let extraFieldLength: UInt16?
    public let extraField: Data?
    public let originalFileName: String?
    public let comment: String?
    public let encryptionHeader: Data?
    public static let encryptionHeaderLength = 12

    public let compressedData: Data
    public let crc32: UInt32
    public let uncompressedSize: UInt32

    public enum CompressionMethod: UInt8 {
        case store = 0
        case compress = 1
        case pack = 2
        case lzh = 3
        case reserved4 = 4
        case reserved5 = 5
        case reserved6 = 6
        case reserved7 = 7
        case deflate = 8
    }

    public struct Flags: OptionSet {
        public static let ascii = Flags(rawValue: 1 << 0)
        public static let partNumber = Flags(rawValue: 1 << 1)
        public static let extraField = Flags(rawValue: 1 << 2)
        public static let originalFileName = Flags(rawValue: 1 << 3)
        public static let comment = Flags(rawValue: 1 << 4)
        public static let encryptionHeader = Flags(rawValue: 1 << 5)

        public typealias RawValue = UInt8
        public var rawValue: UInt8 = 0
        public init(rawValue: Flags.RawValue) {
            self.rawValue = rawValue
        }
    }

    public init(from data: Data) {
        let reader = GZipReader(data: data)
        magic = reader.integer()
        compressionMethod = CompressionMethod(rawValue: reader.integer())!
        flags = Flags(rawValue: reader.integer())
        modificationTime = reader.integer()
        compressionFlags = reader.integer()
        osType = reader.integer()

        if flags.contains(.partNumber) {
            partNumber = reader.integer()
        } else {
            partNumber = nil
        }

        if flags.contains(.extraField) {
            extraFieldLength = reader.integer()
        } else {
            extraFieldLength = nil
        }

        if let extraFieldLength = extraFieldLength {
            extraField = reader.data(offset: Data.Index(extraFieldLength))
        } else {
            extraField = nil
        }

        if flags.contains(.originalFileName) {
            originalFileName = reader.asciiz()
        } else {
            originalFileName = nil
        }

        if flags.contains(.comment) {
            comment = reader.asciiz()
        } else {
            comment = nil
        }

        if flags.contains(.encryptionHeader) {
            encryptionHeader = reader.data(offset: GZipArchive.encryptionHeaderLength)
        } else {
            encryptionHeader = nil
        }

        compressedData = reader.data(offset: data.count - 4 - 4 - reader.index)
        crc32 = reader.integer()
        uncompressedSize = reader.integer()
    }

    public func decompress() throws -> Data {
        return try GZipCompression.decompress(compressionMethod: compressionMethod,
                                              compressedData: compressedData,
                                              uncompressedSize: uncompressedSize)
    }
}


extension compression_stream {
    fileprivate init() {
        self = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1).pointee
    }
}
