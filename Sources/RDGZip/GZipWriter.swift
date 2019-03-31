//
//  GZipWriter.swift
//  RDGZip
//
//  Created by Roman Dzieciol on 3/31/19.
//

import Foundation

final internal class GZipWriter {

    public private(set) var data: Data

    internal init() {
        self.data = Data()
    }

    internal func write<T: FixedWidthInteger>(integer value: T) {
        withUnsafeBytes(of: value) { (ptr) -> Void in
            data.append(ptr.bindMemory(to: T.self))
        }
    }

    @discardableResult
    internal func write(asciiz value: String) -> Int {
        if let stringData = value.data(using: .utf8) {
            data.append(stringData)
            data.append(UInt8(0x00))
            return stringData.count + 1
        }
        return 0
    }

    internal func write(data value: Data) {
        data.append(value)
    }
}
