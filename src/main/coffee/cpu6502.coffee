# cpu6502.coffee
# Copyright 2014 Patrick Meade.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#----------------------------------------------------------------------------

exports.FLAG_CARRY     = FLAG_CARRY     = 0x01
exports.FLAG_ZERO      = FLAG_ZERO      = 0x02
exports.FLAG_INTERRUPT = FLAG_INTERRUPT = 0x04
exports.FLAG_DECIMAL   = FLAG_DECIMAL   = 0x08
exports.FLAG_BREAK     = FLAG_BREAK     = 0x10
exports.FLAG_RESERVED  = FLAG_RESERVED  = 0x20
exports.FLAG_OVERFLOW  = FLAG_OVERFLOW  = 0x40
exports.FLAG_NEGATIVE  = FLAG_NEGATIVE  = 0x80

exports.NMI_LO   = NMI_LO   = 0xFFFA
exports.NMI_HI   = NMI_HI   = 0xFFFB
exports.RESET_LO = RESET_LO = 0xFFFC
exports.RESET_HI = RESET_HI = 0xFFFD
exports.IRQ_LO   = IRQ_LO   = 0xFFFE
exports.IRQ_HI   = IRQ_HI   = 0xFFFF

exports.STACK_PAGE = STACK_PAGE = 0x0100

exports.CYCLE_TABLE = CYCLE_TABLE = [
# 0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
  7, 6, 0, 0, 0, 3, 5, 0, 3, 2, 2, 0, 0, 4, 6, 0, # 0x
  2, 5, 0, 0, 0, 4, 6, 0, 2, 4, 0, 0, 0, 4, 7, 0, # 1x
  6, 6, 0, 0, 3, 3, 5, 0, 4, 2, 2, 0, 4, 4, 6, 0, # 2x
  2, 5, 0, 0, 0, 4, 6, 0, 2, 4, 0, 0, 0, 4, 7, 0, # 3x
  6, 6, 0, 0, 0, 3, 5, 0, 3, 2, 2, 0, 3, 4, 6, 0, # 4x
  2, 5, 0, 0, 0, 4, 6, 0, 2, 4, 0, 0, 0, 4, 7, 0, # 5x
  6, 6, 0, 0, 0, 3, 5, 0, 4, 2, 2, 0, 5, 4, 6, 0, # 6x
  2, 5, 0, 0, 0, 4, 6, 0, 2, 4, 0, 0, 0, 4, 7, 0, # 7x
  0, 6, 0, 0, 3, 3, 3, 0, 2, 0, 2, 0, 4, 4, 4, 0, # 8x
  2, 6, 0, 0, 4, 4, 4, 0, 2, 5, 2, 0, 0, 5, 0, 0, # 9x
  2, 6, 2, 0, 3, 3, 3, 0, 2, 2, 2, 0, 4, 4, 4, 0, # Ax
  2, 5, 0, 0, 4, 4, 4, 0, 2, 4, 2, 0, 4, 4, 4, 0, # Bx
  2, 6, 0, 0, 3, 3, 5, 0, 2, 2, 2, 0, 4, 4, 6, 0, # Cx
  2, 5, 0, 0, 0, 4, 6, 0, 2, 4, 0, 0, 0, 4, 7, 0, # Dx
  2, 6, 0, 0, 3, 3, 5, 0, 2, 2, 2, 0, 4, 4, 6, 0, # Ex
  2, 5, 0, 0, 0, 4, 6, 0, 2, 4, 0, 0, 0, 4, 7, 0] # Fx

exports.ABSOLUTE    = ABSOLUTE    = "ABSOLUTE"
exports.ABSOLUTE_X  = ABSOLUTE_X  = "ABSOLUTE_X"
exports.ABSOLUTE_Y  = ABSOLUTE_Y  = "ABSOLUTE_Y"
exports.ACCUMULATOR = ACCUMULATOR = "ACCUMULATOR"
exports.ADDRESS_LO  = ADDRESS_LO  = "ADDRESS_LO"
exports.ADDRESS_HI  = ADDRESS_HI  = "ADDRESS_HI"
exports.IMMEDIATE   = IMMEDIATE   = "IMMEDIATE"
exports.IMPLIED     = IMPLIED     = "IMPLIED"
exports.INDIRECT    = INDIRECT    = "INDIRECT"
exports.INDIRECT_X  = INDIRECT_X  = "INDIRECT_X"
exports.INDIRECT_Y  = INDIRECT_Y  = "INDIRECT_Y"
exports.OPCODE      = OPCODE      = "OPCODE"
exports.RELATIVE    = RELATIVE    = "RELATIVE"
exports.STACK       = STACK       = "STACK"
exports.VECTOR_LO   = VECTOR_LO   = "VECTOR_LO"
exports.VECTOR_HI   = VECTOR_HI   = "VECTOR_HI"
exports.ZERO_PAGE   = ZERO_PAGE   = "ZERO_PAGE"
exports.ZERO_PAGE_X = ZERO_PAGE_X = "ZERO_PAGE_X"
exports.ZERO_PAGE_Y = ZERO_PAGE_Y = "ZERO_PAGE_Y"

exports.RETURN_ADDRESS_LO = RETURN_ADDRESS_LO = "RETURN_ADDRESS_LO"
exports.RETURN_ADDRESS_HI = RETURN_ADDRESS_HI = "RETURN_ADDRESS_HI"
exports.STATUS_REGISTER   = STATUS_REGISTER   = "STATUS_REGISTER"

ADDR = (address) -> (address & 0xFFFF)
DATA = (data) -> (data & 0xFF)
HI = (address) -> ((address & 0xFF00) >> 8)
LO = (address) -> (address & 0x00FF)
SIGN8 = (data) -> if data < 0x80 then data else data-256

class Cpu6502
  constructor: (@mem) ->
    @_op = [ 
      @_op00, @_op01, @_opXX, @_opXX, @_opXX, @_op05, @_op06, @_opXX,
      @_op08, @_op09, @_op0A, @_opXX, @_opXX, @_op0D, @_op0E, @_opXX,
      @_op10, @_op11, @_opXX, @_opXX, @_opXX, @_op15, @_op16, @_opXX,
      @_op18, @_op19, @_opXX, @_opXX, @_opXX, @_op1D, @_op1E, @_opXX,
      @_op20, @_op21, @_opXX, @_opXX, @_op24, @_op25, @_op26, @_opXX,
      @_op28, @_op29, @_op2A, @_opXX, @_op2C, @_op2D, @_op2E, @_opXX,
      @_op30, @_op31, @_opXX, @_opXX, @_opXX, @_op35, @_op36, @_opXX,
      @_op38, @_op39, @_opXX, @_opXX, @_opXX, @_op3D, @_op3E, @_opXX,
      @_op40, @_op41, @_opXX, @_opXX, @_opXX, @_op45, @_op46, @_opXX,
      @_op48, @_op49, @_op4A, @_opXX, @_op4C, @_op4D, @_op4E, @_opXX,
      @_op50, @_op51, @_opXX, @_opXX, @_opXX, @_op55, @_op56, @_opXX,
      @_op58, @_op59, @_opXX, @_opXX, @_opXX, @_op5D, @_op5E, @_opXX,
      @_op60, @_op61, @_opXX, @_opXX, @_opXX, @_op65, @_op66, @_opXX,
      @_op68, @_op69, @_op6A, @_opXX, @_op6C, @_op6D, @_op6E, @_opXX,
      @_op70, @_op71, @_opXX, @_opXX, @_opXX, @_op75, @_op76, @_opXX,
      @_op78, @_op79, @_opXX, @_opXX, @_opXX, @_op7D, @_op7E, @_opXX,
      @_opXX, @_op81, @_opXX, @_opXX, @_op84, @_op85, @_op86, @_opXX,
      @_op88, @_opXX, @_op8A, @_opXX, @_op8C, @_op8D, @_op8E, @_opXX,
      @_op90, @_op91, @_opXX, @_opXX, @_op94, @_op95, @_op96, @_opXX,
      @_op98, @_op99, @_op9A, @_opXX, @_opXX, @_op9D, @_opXX, @_opXX,
      @_opA0, @_opA1, @_opA2, @_opXX, @_opA4, @_opA5, @_opA6, @_opXX,
      @_opA8, @_opA9, @_opAA, @_opXX, @_opAC, @_opAD, @_opAE, @_opXX,
      @_opB0, @_opB1, @_opXX, @_opXX, @_opB4, @_opB5, @_opB6, @_opXX,
      @_opB8, @_opB9, @_opBA, @_opXX, @_opBC, @_opBD, @_opBE, @_opXX,
      @_opC0, @_opC1, @_opXX, @_opXX, @_opC4, @_opC5, @_opC6, @_opXX,
      @_opC8, @_opC9, @_opCA, @_opXX, @_opCC, @_opCD, @_opCE, @_opXX,
      @_opD0, @_opD1, @_opXX, @_opXX, @_opXX, @_opD5, @_opD6, @_opXX,
      @_opD8, @_opD9, @_opXX, @_opXX, @_opXX, @_opDD, @_opDE, @_opXX,
      @_opE0, @_opE1, @_opXX, @_opXX, @_opE4, @_opE5, @_opE6, @_opXX,
      @_opE8, @_opE9, @_opEA, @_opXX, @_opEC, @_opED, @_opEE, @_opXX,
      @_opF0, @_opF1, @_opXX, @_opXX, @_opXX, @_opF5, @_opF6, @_opXX,
      @_opF8, @_opF9, @_opXX, @_opXX, @_opXX, @_opFD, @_opFE, @_opXX ]
    
  reset: ->
    @ac = 0x00
    @sp = 0xFF
    @sr = FLAG_RESERVED | FLAG_ZERO
    @xr = 0x00
    @yr = 0x00
    @pc = @mem.read(RESET_LO, VECTOR_LO) | (@mem.read(RESET_HI, VECTOR_HI) << 8)

  execute: ->
    @extraCycle = 0
    opcode = @mem.read(@pc, OPCODE)
    @pc = ADDR @pc + 0x0001
    @_op[opcode]()
    return CYCLE_TABLE[opcode] + @extraCycle

  #--------------------------------------------------------------------------

  _branch: =>
    @extraCycle = 1
    oldpc = @pc
    @pc = ADDR(@pc + SIGN8 @_i)
    if (@pc & 0xff00) isnt (oldpc & 0xff00)
      @extraCycle = 2 

  #--------------------------------------------------------------------------

  _doADC: => throw new Error 'Not Implemented'

  _doAND: =>
    @_i &= @ac
    @_updateNZ()
    @ac = @_i

  _doASL: =>
    if (@_i & 0x80) is 0x80
      @sr |= FLAG_CARRY
    else
      @sr &= ~FLAG_CARRY
    @_i = DATA @_i << 1
    @_updateNZ()

  _doBCC: =>
    @_branch() if (@sr & FLAG_CARRY) is 0

  _doBCS: =>
    @_branch() if (@sr & FLAG_CARRY) is FLAG_CARRY

  _doBEQ: =>
    @_branch() if (@sr & FLAG_ZERO) is FLAG_ZERO

  _doBIT: =>
    if (@_i & FLAG_NEGATIVE) is FLAG_NEGATIVE
      @sr |= FLAG_NEGATIVE
    else
      @sr &= ~FLAG_NEGATIVE
    if (@_i & FLAG_OVERFLOW) is FLAG_OVERFLOW
      @sr |= FLAG_OVERFLOW
    else
      @sr &= ~FLAG_OVERFLOW
    @_i = @_i & @ac
    if @_i is 0
      @sr |= FLAG_ZERO
    else
      @sr &= ~FLAG_ZERO

  _doBMI: =>
    @_branch() if (@sr & FLAG_NEGATIVE) is FLAG_NEGATIVE

  _doBNE: =>
    @_branch() if (@sr & FLAG_ZERO) is 0

  _doBPL: =>
    @_branch() if (@sr & FLAG_NEGATIVE) is 0

  _doBRK: =>
    @pc = ADDR @pc + 0x0001
    @_push HI(@pc), RETURN_ADDRESS_HI
    @_push LO(@pc), RETURN_ADDRESS_LO
    @sr |= FLAG_BREAK
    @_push @sr, STATUS_REGISTER
    @sr |= FLAG_INTERRUPT
    @pc = @mem.read(IRQ_LO, VECTOR_LO)
    @pc |= @mem.read(IRQ_HI, VECTOR_HI) << 8
  
  _doBVC: =>
    @_branch() if (@sr & FLAG_OVERFLOW) is 0

  _doBVS: =>
    @_branch() if (@sr & FLAG_OVERFLOW) is FLAG_OVERFLOW

  _doCLC: =>
    @sr &= ~FLAG_CARRY

  _doCLD: =>
    @sr &= ~FLAG_DECIMAL

  _doCLI: =>
    @sr &= ~FLAG_INTERRUPT

  _doCLV: =>
    @sr &= ~FLAG_OVERFLOW

  _doCMP: => throw new Error 'Not Implemented'

  _doCPX: => throw new Error 'Not Implemented'

  _doCPY: => throw new Error 'Not Implemented'

  _doDEC: => throw new Error 'Not Implemented'

  _doDEX: =>
    @_i = DATA @xr - 0x0001
    @xr = @_i
    @_updateNZ()

  _doDEY: => throw new Error 'Not Implemented'

  _doEOR: =>
    @_i ^= @ac
    @_updateNZ()
    @ac = @_i

  _doINC: => throw new Error 'Not Implemented'

  _doINX: => throw new Error 'Not Implemented'

  _doINY: => throw new Error 'Not Implemented'

  _doJMP: =>
    @pc = @_j

  _doJSR: =>
    @pc = ADDR @pc - 0x0001
    @_push HI(@pc), RETURN_ADDRESS_HI
    @_push LO(@pc), RETURN_ADDRESS_LO
    @pc = @_j

  _doLDA: =>
    @ac = @_i
    @_updateNZ()

  _doLDX: =>
    @xr = @_i
    @_updateNZ()

  _doLDY: =>
    @yr = @_i
    @_updateNZ()

  _doLSR: =>
    if (@_i & FLAG_CARRY) is FLAG_CARRY
      @sr |= FLAG_CARRY
    else
      @sr &= ~FLAG_CARRY
    @_i = @_i >> 1
    @_updateNZ()

  _doORA: =>
    @_i |= @ac
    @_updateNZ()
    @ac = @_i

  _doPHA: =>
    @_push @ac, ACCUMULATOR

  _doPHP: =>
    @_push @sr, STATUS_REGISTER

  _doPLA: => throw new Error 'Not Implemented'

  _doPLP: =>
    @_i = @_pop STATUS_REGISTER
    @sr = @_i | FLAG_RESERVED

  _doROL: =>
    @_i = @_i << 1
    @_i |= (@sr & FLAG_CARRY)
    if (@_i & 0x100) is 0x100
      @sr |= FLAG_CARRY
    else
      @sr &= ~FLAG_CARRY
    @_i = DATA @_i
    @_updateNZ()

  _doROR: => throw new Error 'Not Implemented'

  _doRTI: =>
    @sr = @_pop(STATUS_REGISTER) | FLAG_RESERVED
    @pc = @_pop RETURN_ADDRESS_LO
    @pc |= (@_pop(RETURN_ADDRESS_HI) << 8)

  _doRTS: =>
    @pc = @_pop RETURN_ADDRESS_LO
    @pc |= (@_pop(RETURN_ADDRESS_HI) << 8)
    @pc = ADDR @pc + 0x0001

  _doSBC: => throw new Error 'Not Implemented'

  _doSEC: =>
    @sr |= FLAG_CARRY
    
  _doSED: =>
    @sr |= FLAG_DECIMAL

  _doSEI: =>
    @sr |= FLAG_INTERRUPT

  _doSTA: =>
    @_i = @ac

  _doSTX: =>
    @_i = @xr

  _doSTY: => throw new Error 'Not Implemented'

  _doTAX: =>
    @_i = @ac
    @_updateNZ()
    @xr = @_i
  
  _doTAY: =>
    @_i = @ac
    @_updateNZ()
    @yr = @_i

  _doTSX: =>
    @_i = @sp
    @_updateNZ()
    @xr = @_i

  _doTXA: =>
    @_i = @xr
    @_updateNZ()
    @ac = @_i

  _doTXS: =>
    @sp = @xr

  _doTYA: =>
    @_i = @yr
    @_updateNZ()
    @ac = @_i

  #--------------------------------------------------------------------------
  
  _loadAbsolute: =>
    @_j = @mem.read(@pc, ABSOLUTE)
    @pc = ADDR @pc + 0x0001
    @_j |= (@mem.read(@pc, ABSOLUTE) << 8)
    @pc = ADDR @pc + 0x0001
  
  _loadAbsoluteX: =>
    @_j = @mem.read(@pc, ABSOLUTE_X)
    @pc = ADDR @pc + 0x0001
    @_j |= (@mem.read(@pc, ABSOLUTE_X) << 8)
    @pc = ADDR @pc + 0x0001
    oldj = @_j
    @_j = ADDR @_j + @xr
    if (@_j & 0xff00) isnt (oldj & 0xff00)
      @extraCycle = 1
  
  _loadAbsoluteY: =>
    @_j = @mem.read(@pc, ABSOLUTE_Y)
    @pc = ADDR @pc + 0x0001
    @_j |= (@mem.read(@pc, ABSOLUTE_Y) << 8)
    @pc = ADDR @pc + 0x0001
    oldj = @_j
    @_j = ADDR @_j + @yr
    if (@_j & 0xff00) isnt (oldj & 0xff00)
      @extraCycle = 1

  _loadImmediate: =>
    @_i = @mem.read(@pc, IMMEDIATE)
    @pc = ADDR @pc + 0x0001
  
  _loadIndirect: =>
    @_k = @mem.read(@pc, INDIRECT)
    @pc = ADDR @pc + 0x0001
    @_k |= (@mem.read(@pc, INDIRECT) << 8)
    @pc = ADDR @pc + 0x0001
    @_j = @mem.read(@_k, INDIRECT)
    @_k = ADDR @_k + 0x0001
    @_j |= (@mem.read(@_k, INDIRECT) << 8)

  _loadIndirectX: =>
    @_k = @mem.read(@pc, INDIRECT_X)
    @pc = ADDR @pc + 0x0001
    @_k = DATA @_k + @xr
    @_j = @mem.read(@_k, INDIRECT_X)
    @_k = DATA @_k + 0x01
    @_j |= @mem.read(@_k, INDIRECT_X) << 8

  _loadIndirectY: =>
    @_k = @mem.read(@pc, INDIRECT_Y)
    @pc = ADDR @pc + 0x0001
    @_j = @mem.read(@_k, INDIRECT_Y)
    @_k = DATA @_k + 0x01
    @_j |= @mem.read(@_k, INDIRECT_Y) << 8
    oldj = @_j
    @_j = ADDR @_j + @yr
    if (@_j & 0xff00) isnt (oldj & 0xff00)
      @extraCycle = 1
    
  _loadRelative: =>
    @_i = @mem.read(@pc, RELATIVE)
    @pc = ADDR @pc + 0x0001

  _loadZeroPage: =>
    @_j = @mem.read(@pc, ZERO_PAGE)
    @pc = ADDR @pc + 0x0001

  _loadZeroPageX: =>
    @_j = @mem.read(@pc, ZERO_PAGE_X)
    @pc = ADDR @pc + 0x0001
    @_j = ADDR @_j + @xr

  _loadZeroPageY: =>
    @_j = @mem.read(@pc, ZERO_PAGE_Y)
    @pc = ADDR @pc + 0x0001
    @_j = ADDR @_j + @yr

  #--------------------------------------------------------------------------

  _opXX: ->
    throw new Error 'BadOpcodeError'

  _op00: =>
    @_doBRK()

  _op01: =>
    @_loadIndirectX()
    @_readMemory INDIRECT_X
    @_doORA()

  _op05: =>
    @_loadZeroPage()
    @_readMemory ZERO_PAGE
    @_doORA()

  _op06: =>
    @_loadZeroPage()
    @_readMemory ZERO_PAGE
    @_doASL()
    @_writeMemory ZERO_PAGE

  _op08: =>
    @_doPHP()

  _op09: =>
    @_loadImmediate()
    @_doORA()

  _op0A: =>
    @_readAC ACCUMULATOR
    @_doASL()
    @_writeAC ACCUMULATOR

  _op0D: =>
    @_loadAbsolute()
    @_readMemory ABSOLUTE
    @_doORA()

  _op0E: =>
    @_loadAbsolute()
    @_readMemory ABSOLUTE
    @_doASL()
    @_writeMemory ABSOLUTE

  _op10: =>
    @_loadRelative()
    @_doBPL()

  _op11: =>
    @_loadIndirectY()
    @_readMemory INDIRECT_Y
    @_doORA()

  _op15: =>
    @_loadZeroPageX()
    @_readMemory ZERO_PAGE_X
    @_doORA()

  _op16: =>
    @_loadZeroPageX()
    @_readMemory ZERO_PAGE_X
    @_doASL()
    @_writeMemory ZERO_PAGE_X

  _op18: =>
    @_doCLC()

  _op19: =>
    @_loadAbsoluteY()
    @_readMemory ABSOLUTE_Y
    @_doORA()

  _op1D: =>
    @_loadAbsoluteX()
    @_readMemory ABSOLUTE_X
    @_doORA()

  _op1E: =>
    @_loadAbsoluteX()
    @_readMemory ABSOLUTE_X
    @_doASL()
    @_writeMemory ABSOLUTE_X

  _op20: =>
    @_loadAbsolute()
    @_doJSR()

  _op21: =>
    @_loadIndirectX()
    @_readMemory INDIRECT_X
    @_doAND()

  _op24: =>
    @_loadZeroPage()
    @_readMemory ZERO_PAGE
    @_doBIT()

  _op25: =>
    @_loadZeroPage()
    @_readMemory ZERO_PAGE
    @_doAND()

  _op26: =>
    @_loadZeroPage()
    @_readMemory ZERO_PAGE
    @_doROL()
    @_writeMemory ZERO_PAGE

  _op28: =>
    @_doPLP()

  _op29: =>
    @_loadImmediate()
    @_doAND()

  _op2A: =>
    @_readAC ACCUMULATOR
    @_doROL()
    @_writeAC ACCUMULATOR

  _op2C: =>
    @_loadAbsolute()
    @_readMemory ABSOLUTE
    @_doBIT()

  _op2D: =>
    @_loadAbsolute()
    @_readMemory ABSOLUTE
    @_doAND()

  _op2E: =>
    @_loadAbsolute()
    @_readMemory ABSOLUTE
    @_doROL()
    @_writeMemory ABSOLUTE

  _op30: =>
    @_loadRelative()
    @_doBMI()

  _op31: =>
    @_loadIndirectY()
    @_readMemory INDIRECT_Y
    @_doAND()

  _op35: =>
    @_loadZeroPageX()
    @_readMemory ZERO_PAGE_X
    @_doAND()

  _op36: =>
    @_loadZeroPageX()
    @_readMemory ZERO_PAGE_X
    @_doROL()
    @_writeMemory ZERO_PAGE_X

  _op38: =>
    @_doSEC()

  _op39: =>
    @_loadAbsoluteY()
    @_readMemory ABSOLUTE_Y
    @_doAND()

  _op3D: =>
    @_loadAbsoluteX()
    @_readMemory ABSOLUTE_X
    @_doAND()

  _op3E: =>
    @_loadAbsoluteX()
    @_readMemory ABSOLUTE_X
    @_doROL()
    @_writeMemory ABSOLUTE_X

  _op40: =>
    @_doRTI()

  _op41: =>
    @_loadIndirectX()
    @_readMemory INDIRECT_X
    @_doEOR()

  _op45: =>
    @_loadZeroPage()
    @_readMemory ZERO_PAGE
    @_doEOR()

  _op46: =>
    @_loadZeroPage()
    @_readMemory ZERO_PAGE
    @_doLSR()
    @_writeMemory ZERO_PAGE

  _op48: =>
    @_doPHA()

  _op49: =>
    @_loadImmediate()
    @_doEOR()

  _op4A: =>
    @_readAC ACCUMULATOR
    @_doLSR()
    @_writeAC ACCUMULATOR

  _op4C: =>
    @_loadAbsolute()
    @_doJMP()

  _op4D: =>
    @_loadAbsolute()
    @_readMemory ABSOLUTE
    @_doEOR()

  _op4E: =>
    @_loadAbsolute()
    @_readMemory ABSOLUTE
    @_doLSR()
    @_writeMemory ABSOLUTE

  _op50: =>
    @_loadRelative()
    @_doBVC()

  _op51: =>
    @_loadIndirectY()
    @_readMemory INDIRECT_Y
    @_doEOR()

  _op55: =>
    @_loadZeroPageX()
    @_readMemory ZERO_PAGE_X
    @_doEOR()

  _op56: =>
    @_loadZeroPageX()
    @_readMemory ZERO_PAGE_X
    @_doLSR()
    @_writeMemory ZERO_PAGE_X

  _op58: =>
    @_doCLI()

  _op59: =>
    @_loadAbsoluteY()
    @_readMemory ABSOLUTE_Y
    @_doEOR()

  _op5D: =>
    @_loadAbsoluteX()
    @_readMemory ABSOLUTE_X
    @_doEOR()

  _op5E: =>
    @_loadAbsoluteX()
    @_readMemory ABSOLUTE_X
    @_doLSR()
    @_writeMemory ABSOLUTE_X

  _op60: =>
    @_doRTS()

  _op61: =>
    @_loadIndirectX()
    @_readMemory INDIRECT_X
    @_doADC()

  _op65: =>
    @_loadZeroPage()
    @_readMemory ZERO_PAGE
    @_doADC()

  _op66: =>
    @_loadZeroPage()
    @_readMemory ZERO_PAGE
    @_doROR()
    @_writeMemory ZERO_PAGE

  _op68: =>
    @_doPLA()

  _op69: =>
    @_loadImmediate()
    @_doADC()

  _op6A: =>
    @_readAC ACCUMULATOR
    @_doROR()
    @_writeAC ACCUMULATOR

  _op6C: =>
    @_loadIndirect()
    @_doJMP()

  _op6D: =>
    @_loadAbsolute()
    @_readMemory ABSOLUTE
    @_doADC()

  _op6E: =>
    @_loadAbsolute()
    @_readMemory ABSOLUTE
    @_doROR()
    @_writeMemory ABSOLUTE

  _op70: =>
    @_loadRelative()
    @_doBVS()

  _op71: =>
    @_loadIndirectY()
    @_readMemory INDIRECT_Y
    @_doADC()

  _op75: =>
    @_loadZeroPageX()
    @_readMemory ZERO_PAGE_X
    @_doADC()

  _op76: =>
    @_loadZeroPageX()
    @_readMemory ZERO_PAGE_X
    @_doROR()
    @_writeMemory ZERO_PAGE_X

  _op78: =>
    @_doSEI()

  _op79: =>
    @_loadAbsoluteY()
    @_readMemory ABSOLUTE_Y
    @_doADC()

  _op7D: =>
    @_loadAbsoluteX()
    @_readMemory ABSOLUTE_X
    @_doADC()

  _op7E: =>
    @_loadAbsoluteX()
    @_readMemory ABSOLUTE_X
    @_doROR()
    @_writeMemory ABSOLUTE_X

  _op81: =>
    @_loadIndirectX()
    @_doSTA()
    @_writeMemory INDIRECT_X

  _op84: =>
    @_loadZeroPage()
    @_doSTY()
    @_writeMemory ZERO_PAGE

  _op85: =>
    @_loadZeroPage()
    @_doSTA()
    @_writeMemory ZERO_PAGE

  _op86: =>
    @_loadZeroPage()
    @_doSTX()
    @_writeMemory ZERO_PAGE

  _op88: =>
    @_doDEY()

  _op8A: =>
    @_doTXA()

  _op8C: =>
    @_loadAbsolute()
    @_doSTY()
    @_writeMemory ABSOLUTE

  _op8D: =>
    @_loadAbsolute()
    @_doSTA()
    @_writeMemory ABSOLUTE

  _op8E: =>
    @_loadAbsolute()
    @_doSTX()
    @_writeMemory ABSOLUTE

  _op90: =>
    @_loadRelative()
    @_doBCC()

  _op91: =>
    @_loadIndirectY()
    @_doSTA()
    @_writeMemory INDIRECT_Y

  _op94: =>
    @_loadZeroPageX()
    @_doSTY()
    @_writeMemory ZERO_PAGE_X

  _op95: =>
    @_loadZeroPageX()
    @_doSTA()
    @_writeMemory ZERO_PAGE_X

  _op96: =>
    @_loadZeroPageY()
    @_doSTX()
    @_writeMemory ZERO_PAGE_Y

  _op98: =>
    @_doTYA()

  _op99: =>
    @_loadAbsoluteY()
    @_doSTA()
    @_writeMemory ABSOLUTE_Y

  _op9A: =>
    @_doTXS()

  _op9D: =>
    @_loadAbsoluteX()
    @_doSTA()
    @_writeMemory ABSOLUTE_X

  _opA0: =>
    @_loadImmediate()
    @_doLDY()

  _opA1: =>
    @_loadIndirectX()
    @_readMemory INDIRECT_X
    @_doLDA()

  _opA2: =>
    @_loadImmediate()
    @_doLDX()

  _opA4: =>
    @_loadZeroPage()
    @_readMemory ZERO_PAGE
    @_doLDY()

  _opA5: =>
    @_loadZeroPage()
    @_readMemory ZERO_PAGE
    @_doLDA()

  _opA6: =>
    @_loadZeroPage()
    @_readMemory ZERO_PAGE
    @_doLDX()

  _opA8: =>
    @_doTAY()

  _opA9: =>
    @_loadImmediate()
    @_doLDA()

  _opAA: =>
    @_doTAX()

  _opAC: =>
    @_loadAbsolute()
    @_readMemory ABSOLUTE
    @_doLDY()

  _opAD: =>
    @_loadAbsolute()
    @_readMemory ABSOLUTE
    @_doLDA()

  _opAE: =>
    @_loadAbsolute()
    @_readMemory ABSOLUTE
    @_doLDX()

  _opB0: =>
    @_loadRelative()
    @_doBCS()

  _opB1: =>
    @_loadIndirectY()
    @_readMemory INDIRECT_Y
    @_doLDA()

  _opB4: =>
    @_loadZeroPageX()
    @_readMemory ZERO_PAGE_X
    @_doLDY()

  _opB5: =>
    @_loadZeroPageX()
    @_readMemory ZERO_PAGE_X
    @_doLDA()

  _opB6: =>
    @_loadZeroPageY()
    @_readMemory ZERO_PAGE_Y
    @_doLDX()

  _opB8: =>
    @_doCLV()

  _opB9: =>
    @_loadAbsoluteY()
    @_readMemory ABSOLUTE_Y
    @_doLDA()

  _opBA: =>
    @_doTSX()

  _opBC: =>
    @_loadAbsoluteX()
    @_readMemory ABSOLUTE_X
    @_doLDY()

  _opBD: =>
    @_loadAbsoluteX()
    @_readMemory ABSOLUTE_X
    @_doLDA()

  _opBE: =>
    @_loadAbsoluteY()
    @_readMemory ABSOLUTE_Y
    @_doLDX()

  _opC0: =>
    @_loadImmediate()
    @_doCPY()

  _opC1: =>
    @_loadIndirectX()
    @_readMemory INDIRECT_X
    @_doCMP()

  _opC4: =>
    @_loadZeroPage()
    @_readMemory ZERO_PAGE
    @_doCPY()

  _opC5: =>
    @_loadZeroPage()
    @_readMemory ZERO_PAGE
    @_doCMP()

  _opC6: =>
    @_loadZeroPage()
    @_readMemory ZERO_PAGE
    @_doDEC()
    @_writeMemory ZERO_PAGE

  _opC8: =>
    @_doINY()

  _opC9: =>
    @_loadImmediate()
    @_doCMP()

  _opCA: =>
    @_doDEX()

  _opCC: =>
    @_loadAbsolute()
    @_readMemory ABSOLUTE
    @_doCPY()

  _opCD: =>
    @_loadAbsolute()
    @_readMemory ABSOLUTE
    @_doCMP()

  _opCE: =>
    @_loadAbsolute()
    @_readMemory ABSOLUTE
    @_doDEC()
    @_writeMemory ABSOLUTE

  _opD0: =>
    @_loadRelative()
    @_doBNE()

  _opD1: =>
    @_loadIndirectY()
    @_readMemory INDIRECT_Y
    @_doCMP()

  _opD5: =>
    @_loadZeroPageX()
    @_readMemory ZERO_PAGE_X
    @_doCMP()

  _opD6: =>
    @_loadZeroPageX()
    @_readMemory ZERO_PAGE_X
    @_doDEC()
    @_writeMemory ZERO_PAGE_X

  _opD8: =>
    @_doCLD()

  _opD9: =>
    @_loadAbsoluteY()
    @_readMemory ABSOLUTE_Y
    @_doCMP()

  _opDD: =>
    @_loadAbsoluteX()
    @_readMemory ABSOLUTE_X
    @_doCMP()

  _opDE: =>
    @_loadAbsoluteX()
    @_readMemory ABSOLUTE_X
    @_doDEC()
    @_writeMemory ABSOLUTE_X

  _opE0: =>
    @_loadImmediate()
    @_doCPX()

  _opE1: =>
    @_loadIndirectX()
    @_readMemory INDIRECT_X
    @_doSBC()

  _opE4: =>
    @_loadZeroPage()
    @_readMemory ZERO_PAGE
    @_doCPX()

  _opE5: =>
    @_loadZeroPage()
    @_readMemory ZERO_PAGE
    @_doSBC()

  _opE6: =>
    @_loadZeroPage()
    @_readMemory ZERO_PAGE
    @_doINC()
    @_writeMemory ZERO_PAGE

  _opE8: =>
    @_doINX()

  _opE9: =>
    @_loadImmediate()
    @_doSBC()

  _opEA: =>

  _opEC: =>
    @_loadAbsolute()
    @_readMemory ABSOLUTE
    @_doCPX()

  _opED: =>
    @_loadAbsolute()
    @_readMemory ABSOLUTE
    @_doSBC()

  _opEE: =>
    @_loadAbsolute()
    @_readMemory ABSOLUTE
    @_doINC()
    @_writeMemory ABSOLUTE

  _opF0: =>
    @_loadRelative()
    @_doBEQ()

  _opF1: =>
    @_loadIndirectY()
    @_readMemory INDIRECT_Y
    @_doSBC()

  _opF5: =>
    @_loadZeroPageX()
    @_readMemory ZERO_PAGE_X
    @_doSBC()

  _opF6: =>
    @_loadZeroPageX()
    @_readMemory ZERO_PAGE_X
    @_doINC()
    @_writeMemory ZERO_PAGE_X

  _opF8: =>
    @_doSED()

  _opF9: =>
    @_loadAbsoluteY()
    @_readMemory ABSOLUTE_Y
    @_doSBC()

  _opFD: =>
    @_loadAbsoluteX()
    @_readMemory ABSOLUTE_X
    @_doSBC()

  _opFE: =>
    @_loadAbsoluteX()
    @_readMemory ABSOLUTE_X
    @_doINC()
    @_writeMemory ABSOLUTE_X

  #--------------------------------------------------------------------------

  _pop: (mode) =>
    @sp = DATA @sp + 0x01
    @mem.read STACK_PAGE + @sp, mode

  _push: (data, mode) =>
    @mem.write STACK_PAGE + @sp, data, mode
    @sp = DATA @sp - 0x01

  #--------------------------------------------------------------------------

  _readAC: =>
    @_i = @ac

  _readMemory: (mode) =>
    @_i = @mem.read @_j, mode

  #--------------------------------------------------------------------------

  _updateNZ: =>
    # update negative flag
    if (@_i & FLAG_NEGATIVE) is FLAG_NEGATIVE
      @sr |= FLAG_NEGATIVE
    else
      @sr &= ~FLAG_NEGATIVE
    # update zero flag
    if @_i is 0
      @sr |= FLAG_ZERO
    else
      @sr &= ~FLAG_ZERO

  #--------------------------------------------------------------------------

  _writeAC: =>
    @ac = @_i

  _writeMemory: (mode) =>
    @mem.write @_j, @_i, mode

  #--------------------------------------------------------------------------

exports.Cpu6502 = Cpu6502

#----------------------------------------------------------------------------
# end of cpu6502.coffee
