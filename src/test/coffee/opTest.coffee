# opTest.coffee
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
  CYCLE_TABLE,
  FLAG_NEGATIVE,
  FLAG_RESERVED,
  FLAG_ZERO
} = require '../lib/cpu6502'

{ MemoryBuilder } = require '../lib/memory'

describe 'Operations', ->
  describe 'Bad Opcodes', ->
    createBadOpMem = (opcode) ->
      read: (address) -> opcode
      write: (address, data) ->
  
    it 'should throw a BadOpcodeError for undefined operations', ->
      for i in [0..255]
        if CYCLE_TABLE[i] is 0
          mem = createBadOpMem i
          cpu = new Cpu6502 mem
          cpu.reset()
          try
            cpu.execute()
            true.should.equal false
          catch err
            err.message.should.equal 'BadOpcodeError'

  describe 'Good Opcodes', ->
    createTestMem = (memory) ->
      return mem =
        read: (address) ->
          memory[address]
        write: (address, data) ->
          memory[address] = data
  
    it '[0xA9] should LDA #Immediate (10)', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0xA9, 0x0A]
        .create()
      mem = createTestMem memory
      mem.should.have.properties [ 'read', 'write' ]
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x0A
      cpu.pc.should.equal 0xC002
      cpu.sr.should.equal FLAG_RESERVED
      cpu.sp.should.equal 0xFF
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0xA9] should LDA #Immediate (0)', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0xA9, 0x00]
        .create()
      mem = createTestMem memory
      mem.should.have.properties [ 'read', 'write' ]
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xC002
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xFF
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0xA9] should LDA #Immediate (-128)', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0xA9, 0x80]
        .create()
      mem = createTestMem memory
      mem.should.have.properties [ 'read', 'write' ]
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x80
      cpu.pc.should.equal 0xC002
      cpu.sr.should.equal FLAG_NEGATIVE | FLAG_RESERVED
      cpu.sp.should.equal 0xFF
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

#----------------------------------------------------------------------------
# end of opTest.coffee
