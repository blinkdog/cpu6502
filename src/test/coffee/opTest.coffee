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
  FLAG_BREAK,
  FLAG_CARRY,
  FLAG_DECIMAL,
  FLAG_INTERRUPT,
  FLAG_NEGATIVE,
  FLAG_OVERFLOW,
  FLAG_RESERVED,
  FLAG_ZERO
} = require '../lib/cpu6502'

{ MemoryBuilder } = require '../lib/memory'

describe 'Operations', ->
  createTestMem = (memory) ->
    return mem =
      read: (address) ->
        memory[address]
      write: (address, data) ->
        memory[address] = data

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
    it '[0x00] should BRK', ->
      memory = new MemoryBuilder()
        .irqAt 0xdead
        .resetAt 0xC000
        .put [0x00]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 7
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xdead
      cpu.sr.should.equal FLAG_RESERVED | FLAG_BREAK | FLAG_INTERRUPT | FLAG_ZERO
      cpu.sp.should.equal 0xfc
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x01] should ORA ($nn,x)', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x01, 0x3E]
        .putAt 0x0043, [0x15, 0x24]
        .putAt 0x2415, 0x55
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.ac = 0xaa # b10101010
      cpu.sr &= ~FLAG_ZERO
      cpu.xr = 0x05
      cycles = cpu.execute()
      cycles.should.equal 6
      cpu.ac.should.equal 0xff
      cpu.pc.should.equal 0xc002
      cpu.sr.should.equal FLAG_NEGATIVE | FLAG_RESERVED
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x05
      cpu.yr.should.equal 0x00

    it '[0x06] should ASL $nn', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x06, 0x3E]
        .putAt 0x003E, 0xaa
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 5
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc002
      cpu.sr.should.equal FLAG_RESERVED | FLAG_CARRY
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00
      mem.read(0x003e).should.equal 0x54

    it '[0x06] should ASL $nn but not set FLAG_CARRY', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x06, 0x3E]
        .putAt 0x003E, 0x55
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 5
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc002
      cpu.sr.should.equal FLAG_NEGATIVE | FLAG_RESERVED
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00
      mem.read(0x003e).should.equal 0xaa

    it '[0x08] should PHP', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x08]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 3
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc001
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xfe
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00
      mem.read(0x01ff).should.equal FLAG_RESERVED | FLAG_ZERO

    it '[0x10] should BPL', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x10, 0x10]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 3
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc012
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x10] should not BPL on FLAG_NEGATIVE', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x10, 0x10]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.ac = 0x85
      cpu.sr = FLAG_NEGATIVE | FLAG_RESERVED
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x85
      cpu.pc.should.equal 0xc002
      cpu.sr.should.equal FLAG_NEGATIVE | FLAG_RESERVED
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x18] should CLC', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x18]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.sr |= FLAG_CARRY
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc001
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x20] should JSR', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x20, 0x50, 0x80]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 6
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0x8050
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xfd
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00
      mem.read(0x01ff).should.equal 0xc0
      mem.read(0x01fe).should.equal 0x02

    it '[0x24] should BIT $nn', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x24, 0x50]
        .putAt 0x50, [0xcf]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.ac = 0x30
      cycles = cpu.execute()
      cycles.should.equal 3
      cpu.ac.should.equal 0x30
      cpu.pc.should.equal 0xc002
      cpu.sr.should.equal FLAG_NEGATIVE | FLAG_OVERFLOW | FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x26] should ROL $nn', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x26, 0x50]
        .putAt 0x50, [0x55]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 5
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc002
      cpu.sr.should.equal FLAG_NEGATIVE | FLAG_RESERVED
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00
      mem.read(0x0050).should.equal 0xaa

    it '[0x28] should PLP', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x28]
        .putAt 0x01ff, (~FLAG_RESERVED & 0xFF)
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.sp -= 0x01
      cycles = cpu.execute()
      cycles.should.equal 4
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc001
      cpu.sr.should.equal FLAG_NEGATIVE | FLAG_OVERFLOW | FLAG_RESERVED | FLAG_BREAK | FLAG_DECIMAL | FLAG_INTERRUPT | FLAG_ZERO | FLAG_CARRY
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x29] should AND #$nn', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x29, 0x55]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.ac = 0xaa
      cpu.sr &= ~FLAG_ZERO
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc002
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x2A] should ROL A', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x2A]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.ac = 0xaa
      cpu.sr |= FLAG_NEGATIVE
      cpu.sr &= ~FLAG_ZERO
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x54
      cpu.pc.should.equal 0xc001
      cpu.sr.should.equal FLAG_RESERVED | FLAG_CARRY
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x2C] should BIT $nnnn', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x2C, 0x50, 0x80]
        .putAt 0x8050, [0x32]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.ac = 0x02
      cpu.sr |= FLAG_NEGATIVE | FLAG_OVERFLOW | FLAG_ZERO
      cycles = cpu.execute()
      cycles.should.equal 4
      cpu.ac.should.equal 0x02
      cpu.pc.should.equal 0xc003
      cpu.sr.should.equal FLAG_RESERVED
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x30] should BMI', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x30, 0x10]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.ac = 0x85
      cpu.sr = FLAG_NEGATIVE | FLAG_RESERVED
      cycles = cpu.execute()
      cycles.should.equal 3
      cpu.ac.should.equal 0x85
      cpu.pc.should.equal 0xc012
      cpu.sr.should.equal FLAG_NEGATIVE | FLAG_RESERVED
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x30] should not BMI without FLAG_NEGATIVE', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x30, 0x10]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc002
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x31] should AND ($nn),y', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x31, 0x4c]
        .putAt 0x004c, [0x00, 0x21]
        .putAt 0x2105, 0x81
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.ac = 0xff
      cpu.sr = FLAG_NEGATIVE | FLAG_RESERVED
      cpu.yr = 0x05
      cycles = cpu.execute()
      cycles.should.equal 5
      cpu.ac.should.equal 0x81
      cpu.pc.should.equal 0xc002
      cpu.sr.should.equal FLAG_NEGATIVE | FLAG_RESERVED
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x05

    it '[0x35] should AND $nn,x', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x35, 0x70]
        .putAt 0x007f, 0x55
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.ac = 0xaa
      cpu.sr = FLAG_NEGATIVE | FLAG_RESERVED
      cpu.xr = 0x0f
      cycles = cpu.execute()
      cycles.should.equal 4
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc002
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x0f
      cpu.yr.should.equal 0x00

    it '[0x38] should SEC', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x38]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc001
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO | FLAG_CARRY
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x39] should AND $nnnn,y', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x39, 0xf0, 0x80]
        .putAt 0x8120, 0x55
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.ac = 0xaa
      cpu.sr = FLAG_NEGATIVE | FLAG_RESERVED
      cpu.yr = 0x30
      cycles = cpu.execute()
      cycles.should.equal 5
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc003
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x30

    it '[0x3D] should AND $nnnn,y', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x3D, 0xf0, 0x80]
        .putAt 0x8120, 0x55
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.ac = 0xaa
      cpu.sr = FLAG_NEGATIVE | FLAG_RESERVED
      cpu.xr = 0x30
      cycles = cpu.execute()
      cycles.should.equal 5
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc003
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x30
      cpu.yr.should.equal 0x00

    it '[0x40] should RTI', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x40]
        .putAt 0x01fd, [(FLAG_NEGATIVE | FLAG_CARRY), 0x50, 0x80]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.sp -= 0x03
      cycles = cpu.execute()
      cycles.should.equal 6
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0x8050
      cpu.sr.should.equal FLAG_NEGATIVE | FLAG_RESERVED | FLAG_CARRY
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x46] should LSR $nn', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x46, 0x80]
        .putAt 0x0080, 0x55
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 5
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc002
      cpu.sr.should.equal FLAG_RESERVED | FLAG_CARRY
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00
      mem.read(0x0080).should.equal 0x2a

    it '[0x48] should PHA', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x48]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.ac = 0x45
      cycles = cpu.execute()
      cycles.should.equal 3
      cpu.ac.should.equal 0x45
      cpu.pc.should.equal 0xc001
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xfe
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00
      mem.read(0x01ff).should.equal 0x45

    it '[0x49] should EOR #$nn', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x49, 0x5a]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.ac = 0xaa
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0xf0
      cpu.pc.should.equal 0xc002
      cpu.sr.should.equal FLAG_NEGATIVE| FLAG_RESERVED
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x4A] should LSR A', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x4a]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.ac = 0x02
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x01
      cpu.pc.should.equal 0xc001
      cpu.sr.should.equal FLAG_RESERVED
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x4C] should JMP', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x4c, 0x50, 0x80]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 3
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0x8050
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x50] should BVC', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x50, 0x10]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 3
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc012
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x50] should not BVC on FLAG_OVERFLOW', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x50, 0x10]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.sr = FLAG_OVERFLOW | FLAG_RESERVED
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc002
      cpu.sr.should.equal FLAG_OVERFLOW | FLAG_RESERVED
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x51] should EOR ($nn),y', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x51, 0x4c]
        .putAt 0x004c, [0xf0, 0x21]
        .putAt 0x2222, [0xa5]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.ac = 0xaa
      cpu.yr = 0x32
      cycles = cpu.execute()
      cycles.should.equal 6
      cpu.ac.should.equal 0x0f
      cpu.pc.should.equal 0xc002
      cpu.sr.should.equal FLAG_RESERVED
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x32

    it '[0x58] should CLI', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x58]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.sr |= FLAG_INTERRUPT
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc001
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x59] should EOR $nnnn,y', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x59, 0x50, 0x80]
        .putAt 0x8055, [0xa5]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.ac = 0xaa
      cpu.yr = 0x05
      cycles = cpu.execute()
      cycles.should.equal 4
      cpu.ac.should.equal 0x0f
      cpu.pc.should.equal 0xc003
      cpu.sr.should.equal FLAG_RESERVED
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x05

    it '[0x68] should PLA', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x68]
        .putAt 0x01ff, 0xc0
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.sp -= 0x01
      cycles = cpu.execute()
      cycles.should.equal 4
      cpu.ac.should.equal 0xc0
      cpu.pc.should.equal 0xc001
      cpu.sr.should.equal FLAG_NEGATIVE | FLAG_RESERVED
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x6A] should ROR A', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x6A]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.ac = 0xaa
      cpu.sr |= FLAG_NEGATIVE
      cpu.sr &= ~FLAG_ZERO
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x55
      cpu.pc.should.equal 0xc001
      cpu.sr.should.equal FLAG_RESERVED
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x6A] should ROR A with FLAG_CARRY', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x6A]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.ac = 0x7f
      cpu.sr = FLAG_RESERVED | FLAG_CARRY
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0xbf
      cpu.pc.should.equal 0xc001
      cpu.sr.should.equal FLAG_NEGATIVE | FLAG_RESERVED | FLAG_CARRY
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x6C] should JMP', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x6c, 0xff, 0x80]
        .putAt 0x8000, [0xa0]
        .putAt 0x80ff, [0xd0, 0x90]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 5
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0x90d0
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x70] should BVS', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x70, 0x10]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.sr = FLAG_OVERFLOW | FLAG_RESERVED
      cycles = cpu.execute()
      cycles.should.equal 3
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc012
      cpu.sr.should.equal FLAG_OVERFLOW | FLAG_RESERVED
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x70] should not BVS without FLAG_OVERFLOW', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x70, 0x10]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc002
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x78] should SEI', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x78]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc001
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO | FLAG_INTERRUPT
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x88] should DEY', ->
      memory = new MemoryBuilder()
        .resetAt 0xc000
        .put [0x88]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.yr = 0x60
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc001
      cpu.sr.should.equal FLAG_RESERVED
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x5f

    it '[0x8A] should TXA', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x8a]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.ac = 0x85
      cpu.sr = FLAG_NEGATIVE | FLAG_RESERVED
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xC001
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xFF
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x8C] should STY $nnnn', ->
      memory = new MemoryBuilder()
        .resetAt 0xc000
        .put [0x8c, 0x50, 0x80]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.yr = 0x42
      mem.read(0x8050).should.equal 0x00
      cycles = cpu.execute()
      cycles.should.equal 4
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc003
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xFF
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x42
      mem.read(0x8050).should.equal 0x42

    it '[0x90] should BCC', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x90, 0x10]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 3
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc012
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x90] should not BCC on FLAG_CARRY', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x90, 0x10]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.sr = FLAG_RESERVED | FLAG_CARRY
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc002
      cpu.sr.should.equal FLAG_RESERVED | FLAG_CARRY
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00
      
    it '[0x98] should TYA', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x98]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.ac = 0x85
      cpu.sr = FLAG_NEGATIVE | FLAG_RESERVED
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xC001
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xFF
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0x9A] should TXS', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0x9a]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.sr = FLAG_NEGATIVE | FLAG_RESERVED
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc001
      cpu.sr.should.equal FLAG_NEGATIVE | FLAG_RESERVED
      cpu.sp.should.equal 0x00
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0xA0] should LDY #Immediate', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0xA0, 0x80]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.yr = 0x08                    # to show that it changes
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xC002
      cpu.sr.should.equal FLAG_NEGATIVE | FLAG_RESERVED
      cpu.sp.should.equal 0xFF
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x80

    it '[0xA2] should LDX #Immediate', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0xA2, 0x00]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.xr = 0x88                    # to show that it changes
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xC002
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xFF
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0xA8] should TAY', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0xa8]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.ac = 0x85
      cpu.sr = FLAG_RESERVED | FLAG_ZERO
      cpu.xr = 0x00
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x85
      cpu.pc.should.equal 0xC001
      cpu.sr.should.equal FLAG_NEGATIVE | FLAG_RESERVED
      cpu.sp.should.equal 0xFF
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x85

    it '[0xA9] should LDA #Immediate', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0xA9, 0x0A]
        .create()
      mem = createTestMem memory
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

    it '[0xAA] should TAX', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0xaa]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.ac = 0x85
      cpu.sr = FLAG_RESERVED | FLAG_ZERO
      cpu.xr = 0x00
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x85
      cpu.pc.should.equal 0xC001
      cpu.sr.should.equal FLAG_NEGATIVE | FLAG_RESERVED
      cpu.sp.should.equal 0xFF
      cpu.xr.should.equal 0x85
      cpu.yr.should.equal 0x00

    it '[0xB0] should BCS', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0xb0, 0x10]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.sr = FLAG_RESERVED | FLAG_CARRY
      cycles = cpu.execute()
      cycles.should.equal 3
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc012
      cpu.sr.should.equal FLAG_RESERVED | FLAG_CARRY
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0xB0] should not BCS without FLAG_CARRY', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0xb0, 0x10]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc002
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0xB6] should LDX $nn,y', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0xb6, 0x40]
        .putAt 0x85, 0x55
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.yr = 0x45
      cycles = cpu.execute()
      cycles.should.equal 4
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xC002
      cpu.sr.should.equal FLAG_RESERVED
      cpu.sp.should.equal 0xFF
      cpu.xr.should.equal 0x55
      cpu.yr.should.equal 0x45

    it '[0xB8] should CLV', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0xb8]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.sr |= FLAG_OVERFLOW
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc001
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0xBA] should TSX', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0xba]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc001
      cpu.sr.should.equal FLAG_NEGATIVE | FLAG_RESERVED
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0xff
      cpu.yr.should.equal 0x00

    it '[0xC8] should INY', ->
      memory = new MemoryBuilder()
        .resetAt 0xc000
        .put [0xc8]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.yr = 0x7f
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc001
      cpu.sr.should.equal FLAG_NEGATIVE | FLAG_RESERVED
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x80

    it '[0xCE] should DEC', ->
      memory = new MemoryBuilder()
        .resetAt 0xc000
        .put [0xce, 0x50, 0x80]
        .putAt 0x8050, 0x60
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 6
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc003
      cpu.sr.should.equal FLAG_RESERVED
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00
      mem.read(0x8050).should.equal 0x5f

    it '[0xD8] should CLD', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0xd8]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.sr |= FLAG_DECIMAL
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc001
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0xE8] should INX', ->
      memory = new MemoryBuilder()
        .resetAt 0xc000
        .put [0xe8]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.xr = 0x7f
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc001
      cpu.sr.should.equal FLAG_NEGATIVE | FLAG_RESERVED
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x80
      cpu.yr.should.equal 0x00

    it '[0xEE] should INC', ->
      memory = new MemoryBuilder()
        .resetAt 0xc000
        .put [0xee, 0x50, 0x80]
        .putAt 0x8050, 0x7f
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 6
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc003
      cpu.sr.should.equal FLAG_NEGATIVE | FLAG_RESERVED
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00
      mem.read(0x8050).should.equal 0x80

    it '[0xF0] should BEQ with FLAG_ZERO', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0xF0, 0x60]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 3
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xC062
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      cpu.sp.should.equal 0xFF
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0xF0] should not BEQ without FLAG_ZERO', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0xF0, 0x60]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.sr &= ~FLAG_ZERO
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xC002
      cpu.sr.should.equal FLAG_RESERVED
      cpu.sp.should.equal 0xFF
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

    it '[0xF8] should SED', ->
      memory = new MemoryBuilder()
        .resetAt 0xC000
        .put [0xf8]
        .create()
      mem = createTestMem memory
      cpu = new Cpu6502 mem
      cpu.reset()
      cycles = cpu.execute()
      cycles.should.equal 2
      cpu.ac.should.equal 0x00
      cpu.pc.should.equal 0xc001
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO | FLAG_DECIMAL
      cpu.sp.should.equal 0xff
      cpu.xr.should.equal 0x00
      cpu.yr.should.equal 0x00

  describe 'Short Programs', ->
    it 'should store 0x06 at 0x0400', ->
#              .org    $c000
#              lda     #$00    ; a9 00
#              beq     label   ; f0 06
#              ldx     #$05    ; a2 05
#              stx     $0400   ; 8e 00 04
#              rts             ; 60
#      label:  ldx     #$06    ; a2 06
#              stx     $0400   ; 8e 00 04
#              rts             ; 60
      program = [
        0xa9, 0x00, 0xf0, 0x06, 0xa2, 0x05, 0x8e, 0x00,
        0x04, 0x60, 0xa2, 0x06, 0x8e, 0x00, 0x04, 0x60 ]
      memory = new MemoryBuilder()
        .resetAt 0xc000
        .put program
        .putAt 0x01fe, [0xff, 0xcf]    # the return address
        .create()
      mem = createTestMem memory
      mem.read(0x0400).should.equal 0x00
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.sp -= 0x02                   # return address is on the stack
      # ---- program start ----
      cycles = cpu.execute()           # lda #$00
      cycles.should.equal 2
      cpu.ac.should.equal 0
      cpu.pc.should.equal 0xc002
      cpu.sp.should.equal 0xfd
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      # ---- next instruction ----
      cycles = cpu.execute()           # beq label
      cycles.should.equal 3
      cpu.pc.should.equal 0xc00a
      # ---- next instruction ----
      cycles = cpu.execute()           # ldx #$06
      cycles.should.equal 2
      cpu.pc.should.equal 0xc00c
      cpu.sr.should.equal FLAG_RESERVED
      cpu.xr.should.equal 0x06
      # ---- next instruction ----
      cycles = cpu.execute()           # stx $0400
      cycles.should.equal 4
      cpu.pc.should.equal 0xc00f
      mem.read(0x0400).should.equal 0x06
      # ---- next instruction ----
      cycles = cpu.execute()           # rts
      cycles.should.equal 6
      cpu.pc.should.equal 0xd000
      cpu.sp.should.equal 0xff

    it 'should store 0x05 at 0x07c0', ->
#              .org    $c000
#              lda     #$00    ; a9 00
#              bne     label   ; d0 06
#              ldx     #$05    ; a2 05
#              stx     $07c0   ; 8e c0 07
#              rts             ; 60
#      label:  ldx     #$06    ; a2 06
#              stx     $07c0   ; 8e c0 07
#              rts             ; 60
      program = [
        0xa9, 0x00, 0xd0, 0x06, 0xa2, 0x05, 0x8e, 0xc0,
        0x07, 0x60, 0xa2, 0x06, 0x8e, 0xc0, 0x07, 0x60 ]
      memory = new MemoryBuilder()
        .resetAt 0xc000
        .put program
        .putAt 0x01fe, [0xff, 0xcf]    # the return address
        .create()
      mem = createTestMem memory
      mem.read(0x07c0).should.equal 0x00
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.sp -= 0x02                   # return address is on the stack
      # ---- program start ----
      cycles = cpu.execute()           # lda #$00
      cycles.should.equal 2
      cpu.ac.should.equal 0
      cpu.pc.should.equal 0xc002
      cpu.sp.should.equal 0xfd
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      # ---- next instruction ----
      cycles = cpu.execute()           # bne label
      cycles.should.equal 2              # not taken
      cpu.pc.should.equal 0xc004
      # ---- next instruction ----
      cycles = cpu.execute()           # ldx #$05
      cycles.should.equal 2
      cpu.pc.should.equal 0xc006
      cpu.sr.should.equal FLAG_RESERVED
      cpu.xr.should.equal 0x05
      # ---- next instruction ----
      cycles = cpu.execute()           # stx $07c0
      cycles.should.equal 4
      cpu.pc.should.equal 0xc009
      mem.read(0x07c0).should.equal 0x05
      # ---- next instruction ----
      cycles = cpu.execute()           # rts
      cycles.should.equal 6
      cpu.pc.should.equal 0xd000
      cpu.sp.should.equal 0xff

    it 'should store 0x06 at 0x07c0', ->
#              .org    $c0f8
#              lda     #$00    ; c0f8: a9 00
#              beq     label   ; c0fa: f0 06
#              ldx     #$05    ; c0fc: a2 05
#              stx     $07c0   ; c0fe: 8e c0 07
#              rts             ; c101: 60
#      label:  ldx     #$06    ; c102: a2 06
#              stx     $07c0   ; c104: 8e c0 07
#              rts             ; c107: 60
      program = [
        0xa9, 0x00, 0xf0, 0x06, 0xa2, 0x05, 0x8e, 0xc0,
        0x07, 0x60, 0xa2, 0x06, 0x8e, 0xc0, 0x07, 0x60 ]
      memory = new MemoryBuilder()
        .resetAt 0xc0f8
        .put program
        .putAt 0x01fe, [0xff, 0xcf]    # the return address
        .create()
      mem = createTestMem memory
      mem.read(0x07c0).should.equal 0x00
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.sp -= 0x02                   # return address is on the stack
      # ---- program start ----
      cycles = cpu.execute()           # lda #$00
      cycles.should.equal 2
      cpu.ac.should.equal 0
      cpu.pc.should.equal 0xc0fa
      cpu.sp.should.equal 0xfd
      cpu.sr.should.equal FLAG_RESERVED | FLAG_ZERO
      # ---- next instruction ----
      cycles = cpu.execute()           # beq label
      cycles.should.equal 4              # taken to next page
      cpu.pc.should.equal 0xc102
      # ---- next instruction ----
      cycles = cpu.execute()           # ldx #$06
      cycles.should.equal 2
      cpu.pc.should.equal 0xc104
      cpu.sr.should.equal FLAG_RESERVED
      cpu.xr.should.equal 0x06
      # ---- next instruction ----
      cycles = cpu.execute()           # stx $07c0
      cycles.should.equal 4
      cpu.pc.should.equal 0xc107
      mem.read(0x07c0).should.equal 0x06
      # ---- next instruction ----
      cycles = cpu.execute()           # rts
      cycles.should.equal 6
      cpu.pc.should.equal 0xd000
      cpu.sp.should.equal 0xff

    it 'should store 10 0x05s at 0x07c1-0x07ca', ->
#              .org    $c000
#              ldx     #$0a    ; c000: a2 0a
#              lda     #$05    ; c002: a9 05
#      label:  sta     $07c0,x ; c004: 9d c0 07
#              dex             ; c007: ca
#              bne     label   ; c008: d0 fa
#              rts             ; c00a: 60
      program = [
        0xa2, 0x0a, 0xa9, 0x05, 0x9d, 0xc0, 0x07, 0xca,
        0xd0, 0xfa, 0x60 ]
      memory = new MemoryBuilder()
        .resetAt 0xc000
        .put program
        .putAt 0x01fe, [0xff, 0xcf]    # the return address
        .create()
      mem = createTestMem memory
      for i in [0x07c1..0x07ca]
        mem.read(i).should.equal 0x00
      cpu = new Cpu6502 mem
      cpu.reset()
      cpu.sp -= 0x02                   # return address is on the stack
      # ---- program start ----
      while cpu.pc isnt 0xd000
        cycles = cpu.execute()
      # ---- program end ----
      for i in [0x07c1..0x07ca]
        mem.read(i).should.equal 0x05
      cycles.should.equal 6
      cpu.pc.should.equal 0xd000
      cpu.sp.should.equal 0xff

#----------------------------------------------------------------------------
# end of opTest.coffee
