# parse.coffee
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

exports.OPCODE_DOC = /^\s+\|(.+)\|\s+([A-Z]{3})(.+)\|\s+([0-9A-F]{2})\s+\|\s+(\d)\s+\|\s+(\d)(\*?)\s+\|$/

exports.byLine = (text, regexp) ->
  results = []
  text = text.split '\n'
  for line in text
    result = regexp.exec line
    if result isnt null
      results.push result
  return results

#----------------------------------------------------------------------------
# end of parse.coffee
