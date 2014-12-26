# memoryTest.coffee
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

#_ = require 'underscore'
#fs = require 'fs'
path = require 'path'
should = require 'should'

{
  IRQ_LO,
  IRQ_HI,
  NMI_LO,
  NMI_HI,
  RESET_LO,
  RESET_HI
} = require '../lib/cpu6502'

memory = require '../lib/memory'

describe 'memory', ->
  it 'should have a class MemoryBuilder', ->
    memory.should.have.property 'MemoryBuilder'
    {MemoryBuilder} = memory
    builder = new MemoryBuilder()
    builder.constructor.name.should.equal 'MemoryBuilder'

  describe 'MemoryBuilder', ->
    builder = null

    beforeEach ->
      {MemoryBuilder} = memory
      builder = new MemoryBuilder()
      
    it 'should return an empty array from create', ->
      mem = builder.create()
      mem.should.be.an.array
      mem.length.should.equal 0x10000
      for i in [0...mem.length]
        mem[i].should.equal 0x00

    it 'should allow us to specify the IRQ vector', ->
      mem = builder
        .irqAt(0xBEEF)
        .create()
      mem[IRQ_LO].should.equal 0xEF
      mem[IRQ_HI].should.equal 0xBE

    it 'should allow us to specify the NMI vector', ->
      mem = builder
        .nmiAt(0xDEAD)
        .create()
      mem[NMI_LO].should.equal 0xAD
      mem[NMI_HI].should.equal 0xDE

    it 'should allow us to specify the RESET vector', ->
      mem = builder
        .resetAt(0xABCD)
        .create()
      mem[RESET_LO].should.equal 0xCD
      mem[RESET_HI].should.equal 0xAB

    it 'should allow us to specify arbitrary bytes', ->
      mem = builder
        .putAt(RESET_LO, 0xCD)
        .putAt(RESET_HI, 0xAB)
        .create()
      mem[RESET_LO].should.equal 0xCD
      mem[RESET_HI].should.equal 0xAB

    it 'should override arbitrary bytes with vectors', ->
      mem = builder
        .putAt(IRQ_LO, 0x23)
        .putAt(IRQ_HI, 0x01)
        .putAt(NMI_LO, 0x67)
        .putAt(NMI_HI, 0x45)
        .putAt(RESET_LO, 0xAB)
        .putAt(RESET_HI, 0x89)
        .irqAt(0xBEEF)
        .nmiAt(0xDEAD)
        .resetAt(0xABCD)
        .create()
      mem[IRQ_LO].should.equal 0xEF
      mem[IRQ_HI].should.equal 0xBE
      mem[NMI_LO].should.equal 0xAD
      mem[NMI_HI].should.equal 0xDE
      mem[RESET_LO].should.equal 0xCD
      mem[RESET_HI].should.equal 0xAB

    it 'should allow us to specify arrays of arbitrary bytes', ->
      mem = builder
        .putAt(0xC000, [0xA9, 0x0A])
        .resetAt(0xC000)
        .create()
      mem[RESET_LO].should.equal 0x00
      mem[RESET_HI].should.equal 0xC0
      mem[0xC000].should.equal 0xA9
      mem[0xC001].should.equal 0x0A

    it 'should use a cursor to track our writing position', ->
      mem = builder
        .resetAt(0xC000)
        .put([0xA9, 0x0A])
        .create()
      mem[RESET_LO].should.equal 0x00
      mem[RESET_HI].should.equal 0xC0
      mem[0xC000].should.equal 0xA9
      mem[0xC001].should.equal 0x0A

    it 'should load data into memory at a specified address', ->
      mem = builder
        .loadAt(0xC000, path.join __dirname, '../src/test/resources/hello.dat')
        .create()
      mem[0xC000].should.equal 0x48 # 'H'
      mem[0xC001].should.equal 0x65 # 'e'
      mem[0xC002].should.equal 0x6C # 'l'
      mem[0xC003].should.equal 0x6C # 'l'
      mem[0xC004].should.equal 0x6F # 'o'

    it 'should load data into memory at the cursor', ->
      mem = builder
        .resetAt(0xC000)
        .load(path.join __dirname, '../src/test/resources/hello.dat')
        .create()
      mem[RESET_LO].should.equal 0x00
      mem[RESET_HI].should.equal 0xC0
      mem[0xC000].should.equal 0x48 # 'H'
      mem[0xC001].should.equal 0x65 # 'e'
      mem[0xC002].should.equal 0x6C # 'l'
      mem[0xC003].should.equal 0x6C # 'l'
      mem[0xC004].should.equal 0x6F # 'o'

    it 'should load a portion of data into memory', ->
      mem = builder
        .loadPartAt(0xC000, 7, 5, path.join __dirname, '../src/test/resources/hello.dat')
        .create()
      mem[0xC000].should.equal 0x36 # '6'
      mem[0xC001].should.equal 0x35 # '5'
      mem[0xC002].should.equal 0x30 # '0'
      mem[0xC003].should.equal 0x32 # '2'
      mem[0xC004].should.equal 0x21 # '!'

#----------------------------------------------------------------------------
# end of memoryTest.coffee
