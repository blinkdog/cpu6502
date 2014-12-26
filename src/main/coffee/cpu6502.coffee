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
exports.IRQ_LO   = IRQ_LO   = 0xFFFA
exports.IRQ_HI   = IRQ_HI   = 0xFFFB

class Cpu6502
  constructor: (@mem) ->

  reset: ->
    @ac = 0x00
    @sp = 0xFF
    @sr = FLAG_RESERVED | FLAG_ZERO
    @xr = 0x00
    @yr = 0x00
    @pc = @mem.read(RESET_LO) | (@mem.read(RESET_HI) << 8)
 
exports.Cpu6502 = Cpu6502

#----------------------------------------------------------------------------
# end of cpu6502.coffee
