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

#----------------------------------------------------------------------------
# end of tableTest.coffee
