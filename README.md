Name
====

lua-resty-wirefilter - LuaJIT FFI bindings to wirefilter,  An execution engine for Wireshark-like filters

Table of Contents
=================

* [Name](#name)
* [Status](#status)
* [Synopsis](#synopsis)
* [Methods](#methods)
    * [new](#new)
    * [exec](#exec)
* [Installation](#installation)
* [Authors](#authors)



Synopsis
========
```lua
local wirefilter = require "resty.wirefilter"

local wf, err = wirefilter:new({
    fields = {
        ["http.user_agent"] = wirefilter.types.BYTES,
        ["http.port"] = wirefilter.types.INT,
        ["http.remote_ip"] = wirefilter.types.IP,
        ["ssl"] = wirefilter.types.BOOL
    },
    filter = "http.user_agent matches \"(googlebot|facebook)\" && http.port == 80 && http.remote_ip == 192.168.0.1 && ssl"
})


local match_result, err = wf:exec({
    ["http.user_agent"] = "googlebot",
    ["http.port"] = 80,
    ["ssl"] = true,
    ["http.remote_ip"] = "192.168.0.1"
})
```

Methods
=======

[Back to TOC](#table-of-contents)

### new

`syntax: wf, err = wirefilter:new(args)`

Creates a wirefilter instance.

`args` is a table containing the following settings:

- `fields` a table containing the necessary fields.
- `filter` wirefilter-style filter

`fields` contains the names of the fields and their type. We have 4 types in wirefilter:

- Bytes: `wirefilter.types.BYTES`
- Integer: `wirefilter.types.INT`
- IP Address: `wirefilter.types.IP`
- Boolean: `wirefilter.types.BOOL`

`fields` example:
```lua
fields = {
    ["http.user_agent"] = wirefilter.types.BYTES,
    ["http.port"] = wirefilter.types.INT,
    ["http.remote_ip"] = wirefilter.types.IP,
    ["ssl"] = wirefilter.types.BOOL
}
```


### exec

`syntax: result, err = wirefilter:exec(values)`

`exec` matches the given values against the filter. If will 

`values` is a table containing the fields and their values.

`values` example:
```lua
{
    ["http.user_agent"] = "googlebot",
    ["http.port"] = 80,
    ["ssl"] = true,
    ["http.remote_ip"] = "192.168.0.1"
}
```

[Back to TOC](#table-of-contents)

Installation
============
To run this module, You need to compile the wirefilter lib and put the .so file where OpenResty can find it:

https://github.com/cloudflare/wirefilter/tree/master/ffi

## Build
Run the following in the module directory:
```
luarocks make
```

You need to configure
the [lua_package_path](https://github.com/chaoslawful/lua-nginx-module#lua_package_path) directive to
add the path of your `lua-resty-wirefilter` source tree to ngx_lua's Lua module search path, as in

```
http {
    lua_package_path "/path/to/lua-resty-wirefilter/lib/?.lua;;";
    ...
}
```


and then load the library in Lua:

```lua
local wf = require "resty.wirefilter"
```

[Back to TOC](#table-of-contents)

Authors
=======

Amir Keshavarz <amirkekh@gmail.com>.

[Back to TOC](#table-of-contents)
