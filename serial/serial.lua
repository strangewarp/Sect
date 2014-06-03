--[[
    Copyright Reid Levenick 2011
    Distributed under the Boost Software License, Version 1.0
    (See accompanying file LICENSE or copy at
    http://www.boost.org/LICENSE_1_0.txt)
--]]

function cfuncnames( areas )
    areas = areas or { "_G", "string", "table", "math", "io", "os", "coroutine", "package", "debug" }

    local cfuncs = {}

    for k, v in pairs( areas ) do
        local t = _G[ v ]
        if v == "_G" then v = "" else v = v .. "." end
        for k2, v2 in pairs( t ) do
            --Only add it if it actually is a C function- Actual Lua will serialize just fine.
            if type( v2 ) == "function" and not pcall( string.dump, v2 ) then
                cfuncs[ v2 ] = v .. k2
            end
        end
    end

    return cfuncs
end
local cfuncsaved = cfuncnames()

function deserialized( data )
    assert( type( data ) == "string" )
    assert( loadstring( data ) )()
    return deserialize_()
end
function serialize( data, cfuncs )
    assert( data, "argument #1 must be non-nil" )
    cfuncs = cfuncs or cfuncsaved
    assert( type( cfuncs ) == "table", "argument #2 must be a table" )

    local size = 2
    local buffer = { "function deserialize_() local _=" }
    local listed = {}
    local psize = 1
    local pbuffer = {}

    local keySwitch, valueSwitch

    local function makePath( a, b )
        return a .. "[" .. keySwitch[ type( b ) ]( b ) .. "]"
    end
    local function serializeListed( v, k )
        pbuffer[ psize ] = k
        pbuffer[ psize + 1 ] = "="
        pbuffer[ psize + 2 ] = v
        pbuffer[ psize + 3 ] = " "
        psize = psize + 4
    end

    local function serializeError( a ) error( "cannot serialize \"" .. type( a ) .. "\"" ) end

    local function serializeNumber( a ) return tostring( a ) end
    local function serializeBoolean( a ) return a and "true" or "false" end
    local function serializeString( a ) return string.format( "%q", a ) end
    local function serializeFunction( a ) return cfuncs[ a ] or string.format( "loadstring(%q)", string.dump( a ) ) end
    local function serializeTable( v, k )
        local mt = getmetatable( v )
        if mt then
            if mt.__serialize then
                return mt.__serialize( v )
            else
                error( "cannot serialize an object (no __serialize function in metatable)" )
            end
        else
            listed[ v ] = listed[ v ] or k
            buffer[ size ] = "{"
            size = size + 1
            local seen = {}
            for k2, v2 in ipairs( v ) do
                local path = type( v2 ) == "table" and makePath( k, k2 ) or nil
                seen[ k2 ] = true
                if not listed[ v2 ] then
                    local temp = valueSwitch[ type( v2 ) ]( v2, path )
                    buffer[ size ] = temp
                    buffer[ size + 1 ] = ","
                    size = size + 2
                else
                    buffer[ size ] = "nil,"
                    size = size + 1
                    serializeListed( listed[ v2 ], path )
                end
            end
            for k2, v2 in pairs( v ) do
                if not seen[ k2 ] then
                    local path = type( v2 ) == "table" and makePath( k, k2 ) or nil
                    if not listed[ v2 ] then
                        buffer[ size ] = "["
                        buffer[ size + 1 ] = keySwitch[ type( k2 ) ]( k2 )
                        buffer[ size + 2 ] = "]="
                        size = size + 3
                        local temp = valueSwitch[ type( v2 ) ]( v2, path )
                        buffer[ size ] = temp
                        buffer[ size + 1 ] = ","
                        size = size + 2
                    else
                        serializeListed( listed[ v2 ], path )
                    end
                end
            end
            return "}"
        end
    end

    keySwitch =
    {
        [ "nil" ]       = serializeError,
        [ "userdata" ]  = serializeError,
        [ "thread" ]    = serializeError,
        [ "number" ]    = serializeNumber,
        [ "boolean" ]   = serializeBoolean,
        [ "string" ]    = serializeString,
        [ "function" ]  = serializeError,
        [ "table" ]     = serializeError
    }
    valueSwitch =
    {
        [ "nil" ]       = serializeError,
        [ "userdata" ]  = serializeError,
        [ "thread" ]    = serializeError,
        [ "number" ]    = serializeNumber,
        [ "boolean" ]   = serializeBoolean,
        [ "string" ]    = serializeString,
        [ "function" ]  = serializeFunction,
        [ "table" ]     = serializeTable
    }

    local temp = valueSwitch[ type( data ) ]( data, "_" )
    buffer[ size ] = temp
    buffer[ size + 1 ] = " "
    buffer[ size + 2 ] = table.concat( pbuffer )
    buffer[ size + 3 ] = "return _ end"
    return table.concat( buffer )
end

--deserialize( serialize( _G ) )