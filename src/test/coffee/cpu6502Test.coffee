# cpu6502Test.coffee
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

should = require 'should'

{
  Cpu6502,
  FLAG_RESERVED,
  FLAG_ZERO,
  RESET_HI,
  RESET_LO
} = require '../lib/cpu6502'

cpu = null
mem = null

describe 'Cpu6502', ->
  beforeEach ->
    mem =
      read: (address) -> 0x00
      write: (address, data) ->
    cpu = new Cpu6502 mem
    
  it 'should be a class', ->
    cpu.constructor.name.should.equal 'Cpu6502'

  it 'should use the memory provided at construction', ->
    cpu.mem.should.equal mem

  it 'should have a reset method', ->
    cpu.should.have.property 'reset'

  it 'should initialize all the registers properly upon reset', ->
    cpu.reset()
    cpu.ac.should.equal 0x00
    cpu.pc.should.equal 0x0000
    cpu.sp.should.equal 0xff
    cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
    cpu.xr.should.equal 0x00
    cpu.yr.should.equal 0x00

  it 'should read pc from the reset vector upon reset', ->
    cpu.mem =
      read: (address) ->
        return 0xCD if address is RESET_LO
        return 0xAB if address is RESET_HI
        return 0x00
      write: (address, data) ->
    cpu.reset()
    cpu.pc.should.equal 0xABCD

#----------------------------------------------------------------------------
# end of cpu6502Test.coffee
