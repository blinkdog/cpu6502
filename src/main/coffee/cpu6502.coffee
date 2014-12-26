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

exports.VECTOR_LO = VECTOR_LO = "VECTOR_LO"
exports.VECTOR_HI = VECTOR_HI = "VECTOR_HI"

exports.ADDRESS_LO = ADDRESS_LO = "ADDRESS_LO"
exports.ADDRESS_HI = ADDRESS_HI = "ADDRESS_HI"

exports.OPCODE = OPCODE = "OPCODE"

exports.IMMEDIATE = IMMEDIATE = "IMMEDIATE"

ADDR = (address) -> (address & 0xFFFF)

class Cpu6502
  constructor: (@mem) ->
    @extraCycle = 0
    @_op = ((-> throw new Error 'BadOpcodeError') for i in [0..255])
    @_op[0xA9] = =>
      @_i = @mem.read(@pc, IMMEDIATE)
      @pc = ADDR @pc + 0x0001
      @ac = @_i
      if @ac is 0
        @sr |= FLAG_ZERO
      else
        @sr &= ~FLAG_ZERO
      if @ac >= 0x80
        @sr |= FLAG_NEGATIVE
      else
        @sr &= ~FLAG_NEGATIVE

  reset: ->
    @ac = 0x00
    @sp = 0xFF
    @sr = FLAG_RESERVED | FLAG_ZERO
    @xr = 0x00
    @yr = 0x00
    @pc = @mem.read(RESET_LO, VECTOR_LO) | (@mem.read(RESET_HI, VECTOR_HI) << 8)

  execute: ->
    opcode = @mem.read(@pc, OPCODE)
    @pc = ADDR @pc + 0x0001
    @_op[opcode]()
    return CYCLE_TABLE[opcode] + @extraCycle

exports.Cpu6502 = Cpu6502

#----------------------------------------------------------------------------
# end of cpu6502.coffee
