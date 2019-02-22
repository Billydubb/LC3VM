//
//  Util.swift
//  LC3VM
//
//  Created by Kelvin Williams on 2/4/19.
//  Copyright © 2019 Kelvin Williams. All rights reserved.
//

import Foundation


func GetKeyPress () -> Int {
    var key: Int = 0
    let c: cc_t = 0
    let cct = (c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c) // Set of 20 Special Characters
    var oldt: termios = termios(c_iflag: 0, c_oflag: 0, c_cflag: 0, c_lflag: 0, c_cc: cct, c_ispeed: 0, c_ospeed: 0)
    
    tcgetattr(STDIN_FILENO, &oldt) // 1473
    var newt = oldt
    newt.c_lflag = 1217  // Reset ICANON and Echo off
    tcsetattr( STDIN_FILENO, TCSANOW, &newt)
    key = Int(getchar())  // works like "getch()"
    tcsetattr( STDIN_FILENO, TCSANOW, &oldt)
    return key
}

func imageFileToMemory(fileAtPath: String){
    let istream = InputStream(fileAtPath: fileAtPath)
    istream!.open()
    
    var originBuffer = [UInt8](repeating: 0, count: 2)
    istream!.read(&originBuffer, maxLength: originBuffer.count)
    let originBufferSwapped = swapEndian(arr: originBuffer)
    
    var inputBuffer = [UInt8](repeating: 0, count: Int(UINT16_MAX) - Int(originBufferSwapped.first!))
    
    while istream!.hasBytesAvailable {
        istream!.read(&inputBuffer, maxLength: inputBuffer.count)
    }
    istream!.close()
    
    let endianReversedInput = swapEndian(arr: inputBuffer)
    copyInsertArray(intoArray: &memoryArr, withContents: endianReversedInput, at: Int(originBufferSwapped.first!))
}

func swapEndian(arr: [UInt8]) -> [UInt16]{
    let count = arr.count
    var bigEndian: [UInt16] = []
    for index in 0..<count where index % 2 == 0{
        let lowByte = arr[index]
        var highByte: UInt8 = 0
        if index < count && index != count - 1 {
            highByte = arr[index + 1]
        } else {
            highByte = arr[index]
        }
        
        let swapped = (UInt16(lowByte) << 8) + UInt16(highByte)
        bigEndian.append(swapped)
    }
    return bigEndian
}

func memRead(at address: UInt16) -> UInt16 {
    if address == MMAPPEDREGS.MR_KBSR.rawValue{
        if checkKeyBoard() {
            memoryArr[Int(MMAPPEDREGS.MR_KBSR.rawValue)] = 1 << 15
            memoryArr[Int(MMAPPEDREGS.MR_KBDR.rawValue)] = UInt16(GetKeyPress())
        } else {
            memoryArr[Int(MMAPPEDREGS.MR_KBSR.rawValue)] = 0
        }
        
    }
    return memoryArr[Int(address)]
}

func memWrite(at address: UInt16, value: UInt16) {
    memoryArr[Int(address)] = value
}

func signExtend(number: UInt16, ofBits bits: Int) -> UInt16 {
    var signExtendedNumber: UInt16 = number
    if((number >> (bits - 1)) & UInt16(integerLiteral: 1) == 1){
        signExtendedNumber = number | 0xFFFF << bits
    }
    return signExtendedNumber
}

func updateFlags(forRegister register: REGISTER){
    let registerValue = regArr[Int(register.rawValue)]
    if registerValue == 0x0000 {
        regArr[Int(REGISTER.R_COND.rawValue)] = FLAGS.FL_ZRO.rawValue
        return
    }
    
    if(registerValue >> 15) == 0x0001{
        regArr[Int(REGISTER.R_COND.rawValue)] = FLAGS.FL_NEG.rawValue
        return
    }
    
    regArr[Int(REGISTER.R_COND.rawValue)] = FLAGS.FL_POS.rawValue
}

func checkKeyBoard() -> Bool {
    var readfds = fd_set()
    readfds.fdZero()
    readfds.fdSet(fd: STDIN_FILENO)
    
    var timeout = timeval(tv_sec: 0, tv_usec: 0)
    return select(1, &readfds, nil, nil, &timeout) != 0
}

// Ports the FD_ZERO and FD_SET C macros in Darwin to Swift.
// https://github.com/apple/darwin-xnu/blob/master/bsd/sys/_types/_fd_def.h
// This is not portable to Linux.
extension fd_set {
    // FD_ZERO(self)
    mutating func fdZero() {
        bzero(&fds_bits, MemoryLayout.size(ofValue: fds_bits))
    }
    
    // FD_SET(fd, self)
    mutating func fdSet(fd: Int32) {
        let __DARWIN_NFDBITS = Int32(MemoryLayout<Int32>.size) * __DARWIN_NBBY
        let bits = UnsafeMutableBufferPointer(start: &fds_bits.0, count: 32)
        bits[Int(CUnsignedLong(fd) / CUnsignedLong(__DARWIN_NFDBITS))] |= __int32_t(
            CUnsignedLong(1) << CUnsignedLong(fd % __DARWIN_NFDBITS)
        )
    }
}

func copyInsertArray<T>(intoArray: inout Array<T>, withContents contents: Array<T>, at position: Int){
    if position > intoArray.count - 1 {
        return
    }
    
    var _position = position
    for element in contents{
        intoArray[_position] = element
        _position += 1
    }
}


func initStruct<S>() -> S {
    let struct_pointer = UnsafeMutablePointer<S>.allocate(capacity: 1)
    let struct_memory = struct_pointer.pointee
    struct_pointer.deallocate()
    return struct_memory
}

func enableRawMode(fileHandle: FileHandle) -> termios {
    var raw: termios = initStruct()
    tcgetattr(fileHandle.fileDescriptor, &raw)
    
    let original = raw
    
    raw.c_lflag &= ~(UInt(ECHO | ICANON))
    tcsetattr(fileHandle.fileDescriptor, TCSAFLUSH, &raw);
    
    return original
}

func restoreRawMode(fileHandle: FileHandle, originalTerm: termios) {
    var term = originalTerm
    tcsetattr(fileHandle.fileDescriptor, TCSAFLUSH, &term);
}

func handle_interrupt(_ signal: Int32) {
    restoreRawMode(fileHandle: stdInHandle, originalTerm: originalTerm)
    exit(-2)
}

