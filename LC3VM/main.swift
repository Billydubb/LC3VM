//
//  main.swift
//  LC3VM
//
//  Created by Kelvin Williams on 1/24/19.
//  Copyright © 2019 Kelvin Williams. All rights reserved.
//
//
import Foundation
import Darwin
private let system_select = Darwin.select

var regArr = [UInt16](repeating: 0, count: 11)
var memoryArr = [UInt16](repeating: 0, count: Int(UINT16_MAX))
var running = true


let stdinFd = FileHandle.standardInput.fileDescriptor
let stdInHandle = FileHandle(fileDescriptor: stdinFd)
var originalTerm: termios = termios.init()

print(FileManager.default.currentDirectoryPath)

func main() {
    originalTerm = enableRawMode(fileHandle: stdInHandle)
    signal(SIGINT, handle_interrupt)
    
    regArr[Int(REGISTER.R_PC.rawValue)] = 0x3000
    
//    imageFileToMemory(fileAtPath: "./rogue.obj")
    imageFileToMemory(fileAtPath: "./2048.obj")
    while(running){
        // get next instruction
        let instruction = memRead(at: regArr[Int(REGISTER.R_PC.rawValue)])
        // increment PC
        regArr[Int(REGISTER.R_PC.rawValue)] += 1
        
        // decode and execute instruction
        let opCodeNumber = instruction >> 12
        guard let opCode: OPCODE = OPCODE(rawValue: opCodeNumber)
            else {
                print("OPCODE with opcode number: \(opCodeNumber) doest not exist")
                exit(1)
        }
        switch(opCode){
        case .OP_ADD:
            add(instruction: instruction)
        case .OP_AND:
            and(instruction: instruction)
        case .OP_NOT:
            not(instruction: instruction)
        case .OP_BR:
            branch(instruction: instruction)
        case .OP_JMP:
            jmp(instruction: instruction)
        case .OP_JSR:
            jsr(instruction: instruction)
        case .OP_LD:
            ld(instruction: instruction)
        case .OP_LDI:
            ldi(instruction: instruction)
        case .OP_LDR:
            ldr(instruction: instruction)
        case .OP_LEA:
            lea(instruction: instruction)
        case .OP_ST:
            st(instruction: instruction)
        case .OP_STI:
            sti(instruction: instruction)
        case .OP_STR:
            str(instruction: instruction)
        case .OP_TRAP:
            switch(instruction & 0xFF)
            {
            case TRAP.TRAP_GETC.rawValue:
                let _ = trapGetC()
            case TRAP.TRAP_OUT.rawValue:
                trapOut()
            case TRAP.TRAP_PUTS.rawValue:
                trapPuts()
            case TRAP.TRAP_IN.rawValue:
                trapIn()
            case TRAP.TRAP_PUTSP.rawValue:
                trapPutSp()
            case TRAP.TRAP_HALT.rawValue:
                print("trap halt", String(instruction, radix: 2))
                print(TRAP.TRAP_HALT.rawValue)
                trapHalt()
            default:
                print("error: trap vector \(instruction & 0xFF) not found")
                exit(1)
            }
        case .OP_RES:
            ()
        case .OP_RTI:
            ()
        }
        
        
        // back to step one
        
    }
    restoreRawMode(fileHandle: stdInHandle, originalTerm: originalTerm)
    
}
main()
