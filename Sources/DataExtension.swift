import CoreFoundation
import Foundation

internal extension Data {
    static var zero: Data {
        return Data(bytes: [0x00])
    }
    
    var byteArray: [UInt8] {
        return self.withUnsafeBytes {
            [UInt8](UnsafeBufferPointer(start: $0, count: self.count))
        }
    }
    
    static func withLittleEndianOf(_ int: UInt64) -> Data {
        var le = int.littleEndian
        let buffer = UnsafeBufferPointer(start: &le, count: 1)
        return Data(buffer: buffer)
    }
    
    static func withLittleEndianOf(_ int: UInt32) -> Data {
        var le = int.littleEndian
        let buffer = UnsafeBufferPointer(start: &le, count: 1)
        return Data(buffer: buffer)
    }
    
    func readLittleEndianUInt64(at idx: Int = 0) -> UInt64 {
        assert(self.count >= idx + 8)
        
        var read: UInt64 = 0
        self.withUnsafeBytes { (buffer: UnsafePointer<UInt8>) in
            for i in (0...7).reversed() {
                read = (read << 8) + UInt64(buffer[idx + i])
            }
        }
        
        return CFSwapInt64LittleToHost(read)
    }
    
    func readLittleEndianUInt32(at idx: Int = 0) -> UInt32 {
        assert(self.count >= (idx + 4))
        
        var read: UInt32 = 0
        self.withUnsafeBytes { (buffer: UnsafePointer<UInt8>) in
            for i in (0...3).reversed() {
                read = (read << 8) + UInt32(buffer[idx + i])
            }
        }
        
        return CFSwapInt32LittleToHost(read)
    }
}

extension Data {
    
    func subdata(at offset: Int) -> Data {
        return self.subdata(in: offset..<self.count)
    }
    
    func subdata(at offset: Int, length: Int) -> Data {
        return self.subdata(in: offset..<(offset+length))
    }
    
    
    func copyValue<ValueType>() -> ValueType {
        return self.withUnsafeBytes { $0.pointee }
    }
    
    func copyValue<ValueType>(of type: ValueType.Type) -> ValueType {
        return self.withUnsafeBytes { $0.pointee }
    }
    
    func copyValue<ValueType>(of type: ValueType.Type, atOffset offset: Int) -> ValueType {
        return self.withUnsafeBytes { (p0: UnsafePointer<UInt8>) -> ValueType in
            (p0 + offset).withMemoryRebound(to: type, capacity: 1) { $0.pointee }
        }
    }
    
    
    func copyCString(atOffset offset: Int) -> String {
        return self.withUnsafeBytes { (p0: UnsafePointer<UInt8>) -> String in
            String(cString: p0 + offset)
        }
    }
    
    
    func copyArray<ElementType>(of type: ElementType.Type) -> [ElementType] {
        let count = self.count / MemoryLayout<ElementType>.size
        return self.withUnsafeBytes { (p0: UnsafePointer<ElementType>) -> [ElementType] in
            Array( UnsafeBufferPointer<ElementType>(start: p0, count: count) )
        }
    }
    
    func copyArray<ElementType>(of type: ElementType.Type, count: Int) -> [ElementType] {
        return self.withUnsafeBytes { (p0: UnsafePointer<ElementType>) -> [ElementType] in
            Array( UnsafeBufferPointer<ElementType>(start: p0, count: count) )
        }
    }
    
    func copyArray<ElementType>(of type: ElementType.Type, count: Int, atOffset offset: Int) -> [ElementType] {
        return self.withUnsafeBytes { (p0: UnsafePointer<UInt8>) -> [ElementType] in
            (p0 + offset).withMemoryRebound(to: type, capacity: count) {
                Array( UnsafeBufferPointer<ElementType>(start: $0, count: count) )
            }
        }
    }
    
    
    func withUnsafeBuffer<ResultType, ElementType>(of type: ElementType.Type, count: Int, _ body: (UnsafeBufferPointer<ElementType>) throws -> ResultType) rethrows -> ResultType {
        return try self.withUnsafeBytes { (p0: UnsafePointer<ElementType>) -> ResultType in
            try body( UnsafeBufferPointer<ElementType>(start: p0, count: count) )
        }
    }
    
    func withUnsafeBuffer<ResultType, ElementType>(of type: ElementType.Type, count: Int, atOffset offset: Int, _ body: (UnsafeBufferPointer<ElementType>) throws -> ResultType) rethrows -> ResultType {
        return try self.withUnsafeBytes { (p0: UnsafePointer<UInt8>) -> ResultType in
            try (p0 + offset).withMemoryRebound(to: type, capacity: count) {
                let b = UnsafeBufferPointer<ElementType>(start: $0, count: count)
                return try body(b)
            }
        }
    }
    
    //func withUnsafeBytes<ResultType, ContentType>(_ body: (UnsafePointer<ContentType>) throws -> ResultType) rethrows -> ResultType
}


public func +<Pointee>(lhs: UnsafePointer<Pointee>, rhs: Int32) -> UnsafePointer<Pointee> {
    return lhs + Int(rhs)
}
public func +<Pointee>(lhs: UnsafePointer<Pointee>, rhs: UInt32) -> UnsafePointer<Pointee> {
    return lhs + Int(rhs)
}


extension UnsafeRawPointer {
    public func bindMemoryBuffer<T>(to type: T.Type, capacity count: Int) -> UnsafeBufferPointer<T> {
        let p = self.bindMemory(to: type, capacity: count)
        return UnsafeBufferPointer<T>(start: p, count: count)
    }
}


extension Array {
    public subscript(index: UInt16) -> Element { return self[Int(index)] }
}
