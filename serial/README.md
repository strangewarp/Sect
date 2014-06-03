Copyright 2010-2011 Reid Levenick

Serial licensed under the Boost License

Serial is a library intended to quickly serialize very large Lua tables.
Deserialization is accomplished through the returned string, as it returns Lua.

``` lua
local serializedTable = serialize( myTable )
--An optional second argument allows the user to specify the already available functions that can be saved as, for example, print, table.concat, etc. If it is not specified, the functions in _G, string, table, math, io, os, coroutine, package, and debug are used
deserializedTable = deserialize( serializedTable )
--Additionally the function deserialize_ will return all data last returned in deserialize, or be nil. Whee!
--Its a feature, not a bug!
```

The recently added compression library is intended to compress strings of any kind (though it works FANTASTICALLY on serialized tables...).
Decompression is through the decompress function.

``` lua
local compressedSerializedTable = compress( serialize( myTable ) )
local decompressedSerializedTable = decompress( compressedSerializedTable )
local deserializedTable = deserialize( decompress( decompressedSerializedTable ) )
```