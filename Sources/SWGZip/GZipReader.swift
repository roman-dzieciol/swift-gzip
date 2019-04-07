//
//  GZipReader.swift
//  XCActivityLog
//
//  Created by Roman Dzieciol on 3/26/19.
//

import Foundation


final internal class GZipReader {

    internal private(set) var index: Data.Index
    private let data: Data

    internal init(index: Data.Index = 0, data: Data) {
        self.index = index
        self.data = data
    }

    internal func integer<T: FixedWidthInteger>() -> T {
        let size = MemoryLayout<T>.size
        guard index + size <= data.count else {
            fatalError()
        }

        let value: T = data[index..<index+size].withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> T in
            return ptr.baseAddress!.bindMemory(to: T.self, capacity: 1).pointee
        }
        index += size
        return value
    }

    internal func asciiz() -> String {
        guard let endIndex = data.firstIndex(of: 0x00) else {
            return ""
        }
        let bytes = data[index..<endIndex]
        index = endIndex + 1
        return String(bytes: bytes, encoding: .utf8)!
    }

    internal func data(length: Data.Index) -> Data {
        let endIndex = index + length
        defer {
            index = endIndex
        }
        return data[index..<endIndex]
    }
}
