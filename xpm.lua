--[[
    xpm.lua
    Ross Andrews ( ross.andrews@gmail.com )

    ----------------------------------------------------------------------

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, version 3.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

    ----------------------------------------------------------------------

    Usage:

    - To create a new XPM object (which also parses the file): img = Xpm.new('filename.xpm')
    - To read pixel data from the bitmap: img.pixels[row][column] or img:xy(xCoord, yCoord)

    The first method (array subscripts) puts the Y coordinate first and uses 1-based indices.
    The second method puts the X coordinate first and uses 0-based indices. Either is fine,
    use whichever one fits your use case (are you talking to Lua or something else?)
]]--

local lpeg = require('lpeg')

local space = lpeg.S(' \t\n')^0
local word = (lpeg.R('az') + lpeg.R('AZ') + lpeg.R('09') + lpeg.P('_'))^1
local int = lpeg.C(lpeg.R('09')^1) / tonumber

local header_comment = lpeg.P('/* XPM */') * space
local declaration_line = lpeg.P('static char * ') * lpeg.C(word) * '[] = {' * space
local quoted_string_line = lpeg.P('"') * lpeg.C((lpeg.P(1) - '"')^1) * '"' * lpeg.S(',}') * space

local color = lpeg.P('#') * lpeg.C((lpeg.R('09') + lpeg.R('AF'))^6) + lpeg.C('None')

local Xpm = {}

function Xpm.new(filename)
    local obj = {
        filename = filename,
        palette = {},
        pixels = {}
    }

    setmetatable(obj, { __index = Xpm })
    local file = io.open(filename, 'r')

    local state = 'start'
    local palette_count = 0
    local row_count = 0

    for line in file:lines() do
        if state == 'start' then
            assert(header_comment:match(line), 'Missing header comment')
            state = 'declaration'

        elseif state == 'declaration' then
            obj.name = declaration_line:match(line) or error('Missing declaration line')
            state = 'dimension'

        elseif state == 'dimension' then
            obj:parse_dimension(line)
            state = 'palette'

        elseif state == 'palette' then
            obj:parse_palette(line)
            palette_count = palette_count + 1
            if palette_count == obj.num_colors then
                state = 'pixels'
            end

        elseif state == 'pixels' then
            obj:parse_pixels(line)
            row_count = row_count + 1
        end
    end

    assert(row_count == obj.height, 'Dimensions seem inaccurate (height)')

    return obj
end

function Xpm:parse_dimension(line)
    local str = quoted_string_line:match(line)
    local dims = lpeg.Ct((int * space)^4):match(str)

    assert(dims, 'Missing or malformed dimension line')

    self.width = dims[1]
    self.height = dims[2]
    self.num_colors = dims[3]
    self.color_length = dims[4]
end

function Xpm:parse_palette(line)
    local str = quoted_string_line:match(line)
    local color_line = lpeg.C(lpeg.P(self.color_length)) * space * 'c' * space * color
    local char, col = color_line:match(str)
    if col ~= 'None' then self.palette[char] = col end
end

function Xpm:parse_pixels(line)
    local str = quoted_string_line:match(line)
    assert(#str == self.width, 'Dimensions seem inaccurate (width)')
    local row = {}
    for idx = 1, #str do
        local pixel = str:sub(idx, idx)
        table.insert(row, self.palette[pixel])
    end
    table.insert(self.pixels, row)
end

function Xpm:xy(x, y)
    return self.pixels[y+1][x+1]
end

return Xpm
