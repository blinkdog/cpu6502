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

computeMnemonicList = ->
  mnemList = []
  for result in results
    mnem = result[2]
    if not _.contains mnemList, mnem
      mnemList.push mnem
  mnemList = _.sortBy mnemList
  return mnemList

computeOpcodeInfo = ->
  opcodeInfo = new Array 256
  for result in results
    opcode = parseInt result[4], 16
    opcodeInfo[opcode] = result
  return opcodeInfo

computeCycleTable = ->
  cycleTable = new Array 256
  for i in [0...256]
    cycleTable[i] = 0
  for result in results
    opcode = parseInt result[4], 16
    cycleTable[opcode] = parseInt result[6]
  return cycleTable

hex2 = (i) ->
  hex = "00" + (i).toString(16).toUpperCase()
  hex.substr -2

exports.CYCLE_TABLE = CYCLE_TABLE = computeCycleTable()

exports.MNEM_LIST = MNEM_LIST = computeMnemonicList()

exports.OPCODE_INFO = OPCODE_INFO = computeOpcodeInfo()

exports.generateOpTable = ->
  opTable = []
  opTable.push '  _op: ['
  for i in [0..255]
    if CYCLE_TABLE[i] is 0
      opTable.push "    _opXX,"
    else
      opTable.push "    _op#{hex2 i},"
  opTable.push '  ]'
  opTable.join '\n'

doMnemonic = (mnem) ->
  return null if mnem is 'NOP'
  "_do#{mnem}"

loadAddress = (mode) ->
  switch mode
    when "Absolute" then "_loadAbsolute"
    when "Absolute,X" then "_loadAbsoluteX"
    when "Absolute,Y" then "_loadAbsoluteY"
    when "Accumulator" then null
    when "Immediate" then "_loadImmediate"
    when "Implied" then null
    when "Indirect" then "_loadIndirect"
    when "(Indirect,X)" then "_loadIndirectX"
    when "(Indirect),Y" then "_loadIndirectY"
    when "Relative" then "_loadRelative"
    when "Zero Page" then "_loadZeroPage"
    when "Zero Page,X" then "_loadZeroPageX"
    when "Zero Page,Y" then "_loadZeroPageY"
    else
      console.log mode
      false.should.equal true

readData = (mnem, mode) ->
  switch mnem
    when "ADC" then "passthrough"
    when "AND" then "passthrough"
    when "ASL" then "passthrough"
    when "BIT" then "passthrough"
    when "BCC", "BCS", "BEQ", "BMI", "BNE", "BPL", "BVC", "BVS" then return null
    when "BRK" then return null
    when "CLC", "CLD", "CLI", "CLV" then return null
    when "CMP", "CPX", "CPY" then "passthrough"
    when "DEC" then "passthrough"
    when "DEX", "DEY" then return null
    when "EOR" then "passthrough"
    when "INC" then "passthrough"
    when "INX", "INY" then return null
    when "JMP", "JSR" then return null
    when "LDA", "LDX", "LDY" then "passthrough"
    when "LSR" then "passthrough"
    when "NOP" then return null
    when "ORA" then "passthrough"
    when "PHA", "PHP", "PLA", "PLP" then return null
    when "ROL", "ROR" then "passthrough"
    when "RTI", "RTS" then return null
    when "SBC" then "passthrough"
    when "SEC", "SED", "SEI" then return null
    when "STA", "STX", "STY" then return null
    when "TAX", "TAY", "TSX", "TXA", "TXS", "TYA" then return null
    else
      console.log mnem
      false.should.equal true
  switch mode
    when "Accumulator" then "_readAC"
    when "Absolute", "Absolute,X", "Absolute,Y" then "_readMemory"
    when "(Indirect,X)", "(Indirect),Y" then "_readMemory"
    when "Zero Page", "Zero Page,X", "Zero Page,Y" then "_readMemory"
    when "Immediate" then null
    else
      console.log mode
      false.should.equal true

writeData = (mnem, mode) ->
  switch mnem
    when "ADC" then return null
    when "AND" then return null
    when "ASL" then "passthrough"
    when "BIT" then return null
    when "BCC", "BCS", "BEQ", "BMI", "BNE", "BPL", "BVC", "BVS" then return null
    when "BRK" then return null
    when "CLC", "CLD", "CLI", "CLV" then return null
    when "CMP", "CPX", "CPY" then return null
    when "DEC" then "passthrough"
    when "DEX", "DEY" then return null
    when "EOR" then return null
    when "INC" then "passthrough"
    when "INX", "INY" then return null
    when "JMP", "JSR" then return null
    when "LDA", "LDX", "LDY" then return null
    when "LSR" then "passthrough"
    when "NOP" then return null
    when "ORA" then return null
    when "PHA", "PHP", "PLA", "PLP" then return null
    when "ROL", "ROR" then "passthrough"
    when "RTI", "RTS" then return null
    when "SBC" then return null
    when "SEC", "SED", "SEI" then return null
    when "STA", "STX", "STY" then "passthrough"
    when "TAX", "TAY", "TSX", "TXA", "TXS", "TYA" then return null
    else
      console.log mnem
      false.should.equal true
  switch mode
    when "Accumulator" then "_writeAC"
    when "Absolute", "Absolute,X", "Absolute,Y" then "_writeMemory"
    when "(Indirect,X)", "(Indirect),Y" then "_writeMemory"
    when "Zero Page", "Zero Page,X", "Zero Page,Y" then "_writeMemory"
    else
      console.log mode
      false.should.equal true

exports.generateOp = (opcode) ->
  #return "" if not OPCODE_INFO[opcode]?
  info = OPCODE_INFO[opcode]
    # 1: Addressing Mode      '  Absolute,X    ',
    # 2: Mnemonic             'INC',
    # 3: ---                  ' Oper,X          ',
    # 4: hex encoding         'FE',
    # 5: byte count           '3',
    # 6: cycle count          '7',
    # 7: extra cycle          '*',
  opImpl = []
  opImpl.push ""
  opImpl.push "  _op#{hex2 opcode}: =>"
  loadAddr = loadAddress info[1].trim()
  opImpl.push "    @#{loadAddr}()" if loadAddr?
  readIt = readData info[2].trim(), info[1].trim()
  opImpl.push "    @#{readIt}()" if readIt?
  doMnem = doMnemonic info[2].trim()
  opImpl.push "    @#{doMnem}()" if doMnem?
  writeIt = writeData info[2].trim(), info[1].trim()
  opImpl.push "    @#{writeIt}()" if writeIt?
  opImpl.join '\n'

#----------------------------------------------------------------------------
# end of table.coffee
