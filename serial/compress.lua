--[[
    Copyright Reid Levenick 2011
    Distributed under the Boost Software License, Version 1.0
    (See accompanying file LICENSE or copy at
    http://www.boost.org/LICENSE_1_0.txt)
--]]

--POSSIBLE OPTIMIZATION:
--  Make numToBytes and bytesToNum not need a prepended length byte in the case of 1 length
--  1 length is very common on shorter strings, and would greatly improve compression.

local math_ceil, math_floor, math_log, string_byte, string_char, string_sub, table_concat =
      math.ceil, math.floor, math.log, string.byte, string.char, string.sub, table.concat

local log256_ = math_log( 256 )
local function numToBytes( n )
    local len = math_ceil( math_log( n + 1 ) / log256_ )
    local b = { string_char( len ) }
    for i = 2, len + 1 do
        b[ i ] = string_char( n % 256 )
        n = math_floor( n / 256 )
    end
    return table_concat( b )
end
function compress( data )
    local dictionarySize = 256
    local dictionary = {}
    for i = 0, 255 do
        dictionary[ string_char( i ) ] = i
    end
    local out = {}
    local outSize = 1

    local a = ""
    for i = 1, #data do
        local b = string_sub( data, i, i )
        local ab = a .. b
        if dictionary[ ab ] then
            a = ab
        else
            dictionary[ ab ] = dictionarySize
            dictionarySize = dictionarySize + 1
            out[ outSize ] = numToBytes( dictionary[ a ] )
            outSize = outSize + 1
            a = b
        end
    end
    out[ outSize ] = numToBytes( dictionary[ a ] )

    return table_concat( out )
end

local function bytesToNum( b )
    local n = 0
    local pow = 1
    for i = 1, #b do
        n = n + string_byte( b, i, i ) * pow
        pow = pow * 256
    end
    return n
end
function decompress( data )
    local dictionarySize = 256
    local dictionary = {}
    for i = 0, 255 do
        dictionary[ i ] = string_char( i )
    end
    local a = dictionary[ bytesToNum( string_sub( data, 2, 2 ) ) ]
    local out = { a }
    local outSize = 2

    local i = 3
    while i < #data do
        local n = string_byte( data:sub( i, i ) )
        local v = dictionary[ bytesToNum( string_sub( data, i + 1, i + n ) ) ] or ( a .. string_sub( a, 1, 1 ) )
        out[ outSize ] = v
        outSize = outSize + 1
        dictionary[ dictionarySize ] = a .. string_sub( v, 1, 1 )
        dictionarySize = dictionarySize + 1
        a = v
        i = i + n + 1
    end

    return table_concat( out )
end