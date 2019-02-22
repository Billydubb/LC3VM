//
//  Instructions.swift
//  LC3VM
//
//  Created by Kelvin Williams on 2/4/19.
//  Copyright © 2019 Kelvin Williams. All rights reserved.
//

import Foundation

func add(instruction: UInt16){
    let dest = (instruction >> 9) & 0x7
    let src = (instruction >> 6) & 0x7
    let immFlag = (instruction >> 5) & 0x1
    
    if(immFlag == 1){
        let immediateNumber = signExtend(number: instruction & 0x1F, ofBits: 5)
        regArr[Int(dest)] = regArr[Int(src)] &+ immediateNumber
    }
    
    if(immFlag != 1){
        let src2 = instruction & 0x7
        regArr[Int(dest)] = regArr[Int(src)] &+ regArr[Int(src2)]
    }
    
    updateFlags(forRegister: REGISTER(rawValue: dest)!)
    
}

func and(instruction: UInt16){
    let dest = (instruction >> 9) & 0x7
    let src = (instruction >> 6) & 0x7
    let immFlag = (instruction >> 5) & 0x1
    
    if(immFlag == 1){
        let immediateNumber = signExtend(number: instruction & 0x1F, ofBits: 5)
        regArr[Int(dest)] = regArr[Int(src)] & immediateNumber
    }
    
    if(immFlag != 1){
        let src2 = instruction & 0x7
        regArr[Int(dest)] = regArr[Int(src)] & regArr[Int(src2)]
    }
    
    updateFlags(forRegister: REGISTER(rawValue: dest)!)
    
}

func ldi(instruction: UInt16){
    let dest = (instruction >> 9) & 0x7
    let pcOffset = signExtend(number: instruction & 0x1FF, ofBits: 9)
    
    regArr[Int(dest)] = memRead(at: memRead(at: regArr[Int(REGISTER.R_PC.rawValue)] &+ pcOffset))
    updateFlags(forRegister: REGISTER(rawValue: dest)!)
}

func branch(instruction: UInt16){
    let pcOffset = signExtend(number: instruction & 0x1FF, ofBits: 9)
    let conditionFlags = (instruction >> 9) & 0x7
    
    if (conditionFlags & regArr[Int(REGISTER.R_COND.rawValue)]) != 0 {
        regArr[Int(REGISTER.R_PC.rawValue)] = regArr[Int(REGISTER.R_PC.rawValue)] &+ pcOffset
    }
}

func ld(instruction: UInt16){
    let dest = (instruction >> 9) & 0x7
    let pcOffset = signExtend(number: instruction & 0x1FF, ofBits: 9)
    
    regArr[Int(dest)] = memRead(at: regArr[Int(REGISTER.R_PC.rawValue)] &+ pcOffset)
    
    updateFlags(forRegister: REGISTER(rawValue: dest)!)
}

func ldr(instruction: UInt16){
    let dest = (instruction >> 9) & 0x7
    let baseReg = (instruction >> 6) & 0x7
    let offset = signExtend(number: instruction & 0x3F, ofBits: 6)
    
    regArr[Int(dest)] = memRead(at: regArr[Int(baseReg)] &+ offset)
    
    updateFlags(forRegister: REGISTER(rawValue: dest)!)
}

func lea(instruction: UInt16){
    let dest = (instruction >> 9) & 0x7
    let pcOffset = signExtend(number: instruction & 0x1FF, ofBits: 9)
    regArr[Int(dest)] = regArr[Int(REGISTER.R_PC.rawValue)] + pcOffset
    
    updateFlags(forRegister: REGISTER(rawValue: dest)!)
}

func not(instruction: UInt16){
    let dest = (instruction >> 9) & 0x7
    let src = (instruction >> 6) & 0x7
    
    regArr[Int(dest)] = ~regArr[Int(src)]
    
    updateFlags(forRegister: REGISTER(rawValue: dest)!)
}

func st(instruction: UInt16){
    let src = (instruction >> 9) & 0x7
    let pcOffset = signExtend(number: instruction & 0x1FF, ofBits: 9)
    
    memWrite(at: regArr[Int(REGISTER.R_PC.rawValue)] &+ pcOffset, value: regArr[Int(src)])
}

func sti(instruction: UInt16){
    let src = (instruction >> 6) & 0x7
    let pcOffset = signExtend(number: instruction & 0x1FF, ofBits: 9)
    
    memWrite(at: memRead(at: regArr[Int(REGISTER.R_PC.rawValue)] &+ pcOffset), value: regArr[Int(src)])
    
}

func str(instruction: UInt16){
    let base = (instruction >> 6) & 0x7
    let src = (instruction >> 9) & 0x7
    let offset = signExtend(number: instruction & 0x3F, ofBits: 6)
    
    memWrite(at: regArr[Int(base)] &+ offset, value: regArr[Int(src)])
    
}

func jmp(instruction: UInt16){
    let base = (instruction >> 6) & 0x7
    regArr[Int(REGISTER.R_PC.rawValue)] = regArr[Int(base)]
}

func jsr(instruction: UInt16){
    regArr[Int(REGISTER.R_R7.rawValue)] = regArr[Int(REGISTER.R_PC.rawValue)]
    
    let is12Set = ((instruction >> 11) & 1) == 1
    let base = (instruction >> 6) & 0x7
    let pcOffset = signExtend(number: instruction & 0x7FF, ofBits: 11)
    
    regArr[Int(REGISTER.R_PC.rawValue)] = is12Set ? regArr[Int(REGISTER.R_PC.rawValue)] &+ pcOffset : regArr[Int(base)]
}

func trapPuts(){
    var addr = regArr[Int(REGISTER.R_R0.rawValue)]
    
    var bytes: [UInt8] = []
    
    while(UInt8(memRead(at: addr) & 0xff) != 0){
        let charCode = UInt8(memRead(at: addr) & 0xff)
        bytes.append(charCode)
        addr = UInt16(Int(addr) + 1)
    }
    let stri = String(bytes: bytes, encoding: .ascii)
    print(stri!, terminator: "")
    
}

func trapPutSp(){
    var addr = regArr[Int(REGISTER.R_R0.rawValue)]
    
    var bytes: [UInt8] = []
    
    while(UInt8(memRead(at: addr) & 0xffff) != 0){
        let charCodeLower = UInt8(memRead(at: addr) & 0xff)
        let charCodeHigher = UInt8(memRead(at: addr) >> 8 & 0xff)
        bytes.append(charCodeLower)
        charCodeHigher != 0 ? bytes.append(charCodeHigher) : ()
        addr = UInt16(Int(addr) + 1)
    }
    
    let stri = String(bytes: bytes, encoding: .ascii)
    print(stri!, terminator: "")
}

func trapOut(){
    let charCode = UInt8(regArr[Int(REGISTER.R_R0.rawValue)])
    
    let bytes = [charCode]
    let stri = String(bytes: bytes, encoding: .ascii)
    print(stri!, terminator: "")
}

func trapGetC() -> UInt16{
    let charInput = UInt16(GetKeyPress())
    
    regArr[Int(REGISTER.R_R0.rawValue)] = charInput
    return charInput
}

func trapIn(){
    print("Enter a character: ")
    let charInput = trapGetC()
    
    let bytes = [UInt8(charInput)]
    let stri = String(bytes: bytes, encoding: .ascii)
    print(stri!)
    
}


// x25 HALT Halt execution and print a message on the console.
func trapHalt(){
    print("HALT")
    running = false
}
