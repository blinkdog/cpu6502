# parseTest.coffee
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

_ = require 'underscore'
fs = require 'fs'
path = require 'path'
should = require 'should'

parse = require '../lib/parse'

describe 'parse', ->

  describe 'OPCODE_DOC', ->
    {OPCODE_DOC} = parse
    
    it 'should be a RegExp', ->
      OPCODE_DOC.constructor.name.should.equal 'RegExp'
      should(OPCODE_DOC instanceof RegExp).equal true

    it 'should not match table graphics', ->
      OPCODE_DOC.test('  +----------------+-----------------------+---------+---------+----------+').should.equal false

    it 'should not match table headings', ->
      OPCODE_DOC.test('  | Addressing Mode| Assembly Language Form| OP CODE |No. Bytes|No. Cycles|').should.equal false

    it 'should match opcode lines', ->
      OPCODE_DOC.test('  |  Immediate     |   AND #Oper           |    29   |    2    |    2     |').should.equal true
      OPCODE_DOC.test('  |  Zero Page     |   AND Oper            |    25   |    2    |    3     |').should.equal true
      OPCODE_DOC.test('  |  Zero Page,X   |   AND Oper,X          |    35   |    2    |    4     |').should.equal true
      OPCODE_DOC.test('  |  Absolute      |   AND Oper            |    2D   |    3    |    4     |').should.equal true
      OPCODE_DOC.test('  |  (Indirect,X)  |   AND (Oper,X)        |    21   |    2    |    6     |').should.equal true
      OPCODE_DOC.test('  |  (Indirect),Y  |   AND (Oper),Y        |    31   |    2    |    5     |').should.equal true

    it 'should match opcode lines with additional cycles', ->
      OPCODE_DOC.test('  |  Absolute,X    |   AND Oper,X          |    3D   |    3    |    4*    |').should.equal true
      OPCODE_DOC.test('  |  Absolute,Y    |   AND Oper,Y          |    39   |    3    |    4*    |').should.equal true

  describe '6502.txt', ->
    cpuDoc = "" + fs.readFileSync path.join __dirname, '../doc/6502.txt'
    
    describe 'parsing instructions', ->
      {OPCODE_DOC} = parse
      results = parse.byLine cpuDoc, OPCODE_DOC
      
      it 'should parse 151 instructions', ->
        results.length.should.equal 151

      it 'should have 8 fields per instruction', ->
        for result in results
          result.length.should.equal 8

      it 'should have 13 different addressing modes', ->
        addrModes = []
        for result in results
          addrMode = result[1].trim()
          if not _.contains addrModes, addrMode
            addrModes.push addrMode
        addrModes.length.should.equal 13

      it 'should have 56 different operations', ->
        operations = []
        for result in results
          operation = result[2]
          if not _.contains operations, operation
            operations.push operation
        operations.length.should.equal 56

      it 'should have a unique identifier for each instruction', ->
        op = {}
        for result in results
          hexCode = result[4]
          should(op[hexCode]).equal undefined
          op[hexCode] = result

      it 'should have instructions between 1 and 3 bytes long', ->
        for result in results
          length = parseInt result[5]
          length.should.be.greaterThan 0
          length.should.be.lessThan 4

      it 'should have instructions between 2 and 7 cycles long', ->
        for result in results
          length = parseInt result[6]
          length.should.be.greaterThan 1
          length.should.be.lessThan 8

      it 'should have 28 instructions that might take an extra cycle', ->
        extraCount = 0
        for result in results
          if result[7] is '*'
            extraCount++
        extraCount.should.equal 28

#----------------------------------------------------------------------------
# end of parseTest.coffee
