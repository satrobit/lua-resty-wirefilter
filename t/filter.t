use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: filter
--- config
location = /t {
    content_by_lua_block {
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

        ngx.say(match_result)
    }
}
--- request
GET /t
--- response_body
true
