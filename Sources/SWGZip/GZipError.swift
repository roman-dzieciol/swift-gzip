//
//  GZipError.swift
//  SWGZip
//
//  Created by Roman Dzieciol on 3/31/19.
//

import Foundation

public enum GZipError: Error {
    case unknownCompressionMethod(GZipArchive.CompressionMethod)
    case decodedLengthMismatch(Int, UInt32)
    case dataCrcFailed(UInt,UInt32)
    case headerCrcFailed(UInt,UInt16)
    case unknownFlag(UInt8)
    case notGZip(UInt16)
    case encodeFailed
}
