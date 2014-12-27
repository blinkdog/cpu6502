# tableTest.coffee
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
#path = require 'path'
should = require 'should'

table = require '../lib/table'

describe 'table', ->
  it 'should export a CYCLE_TABLE', ->
    table.should.have.property 'CYCLE_TABLE'
    {CYCLE_TABLE} = table
    CYCLE_TABLE.should.be.an.array
    CYCLE_TABLE.length.should.equal 0x100
    for entry in CYCLE_TABLE
      if entry isnt 0
        entry.should.be.lessThan 8
        entry.should.be.greaterThan 1

  it 'should be able to generate an _op table', ->
    opTable = table.generateOpTable()
    opTable.should.be.ok

  it 'should be able to generate an _op', ->
    op = table.generateOp 0xA9
    op.should.be.ok

  it 'should be able to list the operations by mnemonic', ->
    for mnem in table.MNEM_LIST
      mnem.should.be.ok
      #console.log "  _do#{mnem}: =>\n"

  it 'should be able to generate lots of _opNN', ->
    {CYCLE_TABLE} = table
    for i in [0..255]
      if CYCLE_TABLE[i] isnt 0
        opText = table.generateOp i
        opText.should.be.ok
        #console.log opText

#----------------------------------------------------------------------------
# end of tableTest.coffee
