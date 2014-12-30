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
  FLAG_INTERRUPT,
  FLAG_NEGATIVE,
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
