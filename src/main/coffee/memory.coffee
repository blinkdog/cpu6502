# memory.coffee
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

fs = require 'fs'

{
  IRQ_LO,
  IRQ_HI,
  NMI_LO,
  NMI_HI,
  RESET_LO,
  RESET_HI
} = require './cpu6502'

ADDR = (address) -> (address & 0xFFFF)
DATA = (data) -> (data & 0xFF)
HI = (address) -> ((address & 0xFF00) >> 8)
LO = (address) -> (address & 0xFF)

class MemoryBuilder
  constructor: ->
    @cache = new Uint8Array 0x10000
    @cursor = ADDR 0x0000
  
  create: ->
    result = @cache
    if @irqAddr?
      result[IRQ_LO] = LO @irqAddr
      result[IRQ_HI] = HI @irqAddr
    if @nmiAddr?
      result[NMI_LO] = LO @nmiAddr
      result[NMI_HI] = HI @nmiAddr
    if @resetAddr?
      result[RESET_LO] = LO @resetAddr
      result[RESET_HI] = HI @resetAddr
    return result

  irqAt: (address) ->
    @cursor = @irqAddr = ADDR address
    return this

  load: (path) ->
    data = fs.readFileSync path
    @put datum for datum in data
    return this

  loadAt: (address, path) ->
    @cursor = ADDR address
    @load path
    return this

  loadPartAt: (address, offset, length, path) ->
    @cursor = ADDR address
    data = fs.readFileSync path
    data = data.slice offset, offset+length
    @put datum for datum in data
    return this

  nmiAt: (address) ->
    @cursor = @nmiAddr = ADDR address
    return this

  put: (data) ->
    if Array.isArray data
      @put datum for datum in data
    else
      @cache[@cursor] = DATA data
      @cursor = ADDR @cursor + 1
    return this

  putAt: (address, data) ->
    @cursor = ADDR address
    if Array.isArray data
      @put datum for datum in data
    else
      @put data
    return this

  resetAt: (address) ->
    @cursor = @resetAddr = ADDR address
    return this

exports.MemoryBuilder = MemoryBuilder

#----------------------------------------------------------------------------
# end of memory.coffee
