# table.coffee
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

parse = require './parse'

cpuDoc = "" + fs.readFileSync path.join __dirname, '../doc/6502.txt'
results = parse.byLine cpuDoc, parse.OPCODE_DOC

computeCycleTable = ->
  cycleTable = new Array 256
  for i in [0...256]
    cycleTable[i] = 0
  for result in results
    opcode = parseInt result[4], 16
    cycleTable[opcode] = parseInt result[6]
  return cycleTable

exports.CYCLE_TABLE = computeCycleTable()

#----------------------------------------------------------------------------
# end of table.coffee
