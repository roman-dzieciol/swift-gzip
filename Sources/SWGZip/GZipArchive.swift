//
//  GZipArchive.swift
//  XCActivityLog
//
//  Created by Roman Dzieciol on 3/26/19.
//

import Foundation
import Compression
import zlib


/// GZip archive containing header, compressed data and footer
///
/// RFC-1952 https://tools.ietf.org/html/rfc1952
///
final public class GZipArchive {

    public static let expectedMagic: UInt16 = 0x8b1f
    public let magic: UInt16

    /// This identifies the compression method used in the file.  CM
    /// = 0-7 are reserved.  CM = 8 denotes the "deflate"
    /// compression method, which is the one customarily used by
    /// gzip and which is documented elsewhere.
    public let compressionMethod: CompressionMethod
    public let flags: Flags
    public let modificationTime: UInt32

    /// These flags are available for use by specific compression
    /// methods.  The "deflate" method (CM = 8) sets these flags as
    /// follows:
    ///
    /// XFL = 2 - compressor used maximum compression,
    /// slowest algorithm
    /// XFL = 4 - compressor used fastest algorithm
    public let compressionFlags: UInt8

    /// This identifies the type of file system on which compression
    /// took place.  This may be useful in determining end-of-line
    /// convention for text files.  The currently defined values are
    /// as follows:
    ///  0 - FAT filesystem (MS-DOS, OS/2, NT/Win32)
    ///  1 - Amiga
    ///  2 - VMS (or OpenVMS)
    ///  3 - Unix
    ///  4 - VM/CMS
    ///  5 - Atari TOS
    ///  6 - HPFS filesystem (OS/2, NT)
    ///  7 - Macintosh
    ///  8 - Z-System
    ///  9 - CP/M
    ///  10 - TOPS-20
    ///  11 - NTFS filesystem (NT)
    ///  12 - QDOS
    ///  13 - Acorn RISCOS
    ///  255 - unknown
    public let osType: UInt8

    public let crc16: UInt16?
    public let extraFieldLength: UInt16?
    public let extraField: Data?
    public let originalFileName: String?
    public let comment: String?
    public let compressedData: Data
    public let uncompressedDataCrc32: UInt32

    /// This contains the size of the original (uncompressed) input
    /// data modulo 2^32.
    public let uncompressedSize: UInt32

    public enum CompressionMethod: UInt8 {
        case reserved0 = 0
        case reserved1 = 1
        case reserved2 = 2
        case reserved3 = 3
        case reserved4 = 4
        case reserved5 = 5
        case reserved6 = 6
        case reserved7 = 7
        case deflate = 8
    }

    public struct Flags: OptionSet {

        /// If FTEXT is set, the file is probably ASCII text.  This is
        /// an optional indication, which the compressor may set by
        /// checking a small amount of the input data to see whether any
        /// non-ASCII characters are present.  In case of doubt, FTEXT
        /// is cleared, indicating binary data. For systems which have
        /// different file formats for ascii text and binary data, the
        /// decompressor can use FTEXT to choose the appropriate format.
        /// We deliberately do not specify the algorithm used to set
        /// this bit, since a compressor always has the option of
        /// leaving it cleared and a decompressor always has the option
        /// of ignoring it and letting some other program handle issues
        /// of data conversion.
        public static let ascii = Flags(rawValue: 1 << 0)

        /// If FHCRC is set, a CRC16 for the gzip header is present,
        /// immediately before the compressed data. The CRC16 consists
        /// of the two least significant bytes of the CRC32 for all
        /// bytes of the gzip header up to and not including the CRC16.
        /// [The FHCRC bit was never set by versions of gzip up to
        /// 1.2.4, even though it was documented with a different
        /// meaning in gzip 1.2.4.]
        public static let crc16 = Flags(rawValue: 1 << 1)

        /// If FEXTRA is set, optional extra fields are present, as
        /// described in a following section.
        public static let extraField = Flags(rawValue: 1 << 2)

        /// If FNAME is set, an original file name is present,
        /// terminated by a zero byte.  The name must consist of ISO
        /// 8859-1 (LATIN-1) characters; on operating systems using
        /// EBCDIC or any other character set for file names, the name
        /// must be translated to the ISO LATIN-1 character set.  This
        /// is the original name of the file being compressed, with any
        /// directory components removed, and, if the file being
        /// compressed is on a file system with case insensitive names,
        /// forced to lower case. There is no original file name if the
        /// data was compressed from a source other than a named file;
        /// for example, if the source was stdin on a Unix system, there
        /// is no file name.
        public static let originalFileName = Flags(rawValue: 1 << 3)

        /// If FCOMMENT is set, a zero-terminated file comment is
        /// present.  This comment is not interpreted; it is only
        /// intended for human consumption.  The comment must consist of
        /// ISO 8859-1 (LATIN-1) characters.  Line breaks should be
        /// denoted by a single line feed character (10 decimal).
        public static let comment = Flags(rawValue: 1 << 4)
        
        public static let reserved5 = Flags(rawValue: 1 << 5)

        public static let reserved6 = Flags(rawValue: 1 << 6)

        public static let reserved7 = Flags(rawValue: 1 << 7)

        public typealias RawValue = UInt8
        public var rawValue: UInt8 = 0
        public init(rawValue: Flags.RawValue) {
            self.rawValue = rawValue
        }
    }

    public init(from data: Data, verifyHeader: Bool = false) throws {
        let reader = GZipReader(data: data)
        magic = reader.integer()
        guard magic == GZipArchive.expectedMagic else {
            throw GZipError.notGZip(magic)
        }

        compressionMethod = CompressionMethod(rawValue: reader.integer())!
        if compressionMethod != .deflate {
            throw GZipError.unknownCompressionMethod(compressionMethod)
        }

        flags = Flags(rawValue: reader.integer())
        modificationTime = reader.integer()
        compressionFlags = reader.integer()
        osType = reader.integer()

        if flags.contains(.crc16) {
            let headerData = data[0..<reader.index]
            let calculatedCrc = GZipArchive.crc32(of: headerData)
            crc16 = reader.integer()
            if verifyHeader {
                guard crc16 == UInt16(calculatedCrc & 0xFFFF) else {
                    throw GZipError.headerCrcFailed(calculatedCrc, crc16!)
                }
            }
        } else {
            crc16 = nil
        }

        if flags.contains(.extraField) {
            extraFieldLength = reader.integer()
        } else {
            extraFieldLength = nil
        }

        if let extraFieldLength = extraFieldLength {
            extraField = reader.data(length: Data.Index(extraFieldLength))
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

        if flags.contains(.reserved5) {
            throw GZipError.unknownFlag(Flags.reserved5.rawValue)
        }

        if flags.contains(.reserved6) {
            throw GZipError.unknownFlag(Flags.reserved6.rawValue)
        }

        if flags.contains(.reserved7) {
            throw GZipError.unknownFlag(Flags.reserved7.rawValue)
        }

        compressedData = reader.data(length: data.count
            - 4 // uncompressedDataCrc32
            - 4 // uncompressedSize
            - reader.index)
        uncompressedDataCrc32 = reader.integer()
        uncompressedSize = reader.integer()
    }

    public init(with data: Data) throws {
        magic = GZipArchive.expectedMagic
        compressionMethod = .deflate
        flags = []
        modificationTime = 0
        compressionFlags = 0
        osType = 0xFF
        crc16 = nil
        extraFieldLength = nil
        extraField = nil
        originalFileName = nil
        comment = nil
        compressedData = try GZipCompression.compress(data: data)
        uncompressedDataCrc32 = UInt32(GZipArchive.crc32(of: data))
        uncompressedSize = UInt32(UInt(data.count) % UInt(UInt32.max))
    }

    public func write(to url: URL, options: Data.WritingOptions = []) throws {
        let data = try compress()
        try data.write(to: url, options: options)
    }

    public func compress() throws -> Data {
        let writer = GZipWriter()
        writer.write(integer: magic)
        writer.write(integer: compressionMethod.rawValue)
        writer.write(integer: flags.rawValue)
        writer.write(integer: modificationTime)
        writer.write(integer: compressionFlags)
        writer.write(integer: osType)

        if let crc16 = crc16 {
            writer.write(integer: crc16)
        }

        if let extraField = extraField {
            writer.write(integer: extraField.count)
            writer.write(data: extraField)
        }

        if let originalFileName = originalFileName {
            writer.write(asciiz: originalFileName)
        }

        if let comment = comment {
            writer.write(asciiz: comment)
        }

        writer.write(data: compressedData)
        writer.write(integer: uncompressedDataCrc32)
        writer.write(integer: uncompressedSize)
        return writer.data
    }

    public func decompress() throws -> Data {

        let result = try GZipCompression.decompress(
            data: compressedData,
            outputSize: uncompressedSize)

        let dataCrc = GZipArchive.crc32(of: result)
        guard dataCrc == uncompressedDataCrc32 else {
            throw GZipError.dataCrcFailed(dataCrc, uncompressedDataCrc32)
        }
        return result
    }

    private static func crc32(of data: Data) -> UInt {
        return data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> UInt in
            let ptr = pointer.bindMemory(to: UInt8.self).baseAddress
            return zlib.crc32(0, ptr, UInt32(data.count))
        }
    }
}
