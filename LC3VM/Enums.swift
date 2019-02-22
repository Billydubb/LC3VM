//
//  Enums.swift
//  LC3VM
//
//  Created by Kelvin Williams on 1/24/19.
//  Copyright © 2019 Kelvin Williams. All rights reserved.
//

import Foundation

enum REGISTER: UInt16 {
    case R_R0 = 0
    case R_R1
    case R_R2
    case R_R3
    case R_R4
    case R_R5
    case R_R6
    case R_R7
    case R_PC /* program counter */
    case R_COND
    case R_COUNT
}

enum OPCODE: UInt16 {
    
    case OP_BR = 0 /* branch */
    case OP_ADD    /* add  */
    case OP_LD     /* load */
    case OP_ST     /* store */
    case OP_JSR    /* jump register */
    case OP_AND    /* bitwise and */
    case OP_LDR    /* load register */
    case OP_STR    /* store register */
    case OP_RTI    /* unused */
    case OP_NOT    /* bitwise not */
    case OP_LDI    /* load indirect */
    case OP_STI    /* store indirect */
    case OP_JMP    /* jump */
    case OP_RES    /* reserved (unused) */
    case OP_LEA    /* load effective address */
    case OP_TRAP    /* execute trap */
}

enum TRAP: UInt16 {
    case TRAP_GETC = 0x20  /* get character from keyboard */
    case TRAP_OUT = 0x21   /* output a character */
    case TRAP_PUTS = 0x22  /* output a word string */
    case TRAP_IN = 0x23    /* input a string */
    case TRAP_PUTSP = 0x24 /* output a byte string */
    case TRAP_HALT = 0x25   /* halt the program */
};

enum FLAGS: UInt16 {
    case FL_POS = 1 /* P */
    case FL_ZRO = 2 /* Z */
    case FL_NEG = 4 /* N */
}

enum MMAPPEDREGS: UInt16 {
    case MR_KBSR = 0xFE00 /* keyboard status */
    case MR_KBDR = 0xFE02  /* keyboard data */
};
