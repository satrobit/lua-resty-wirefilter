package = "lua-resty-wirefilter"
version = "v1.0.0-1"

source = {
  url = "git://github.com/satrobit/lua-resty-wirefilter.git"
}

description = {
  summary = "LuaJIT FFI bindings to wirefilter - An execution engine for Wireshark-like filters",
  homepage = "https://github.com/satrobit/lua-resty-wirefilter",
  license = "MIT",
  maintainer = "amirkekh@gmail.com"
}

dependencies = {
  "lua >= 5.1"
}

build = {
    type = "builtin",
    modules = {
        ["resty.wirefilter"] = "lib/resty/wirefilter.lua"
    }
}
