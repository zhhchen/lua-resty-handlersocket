Name
====

lua-resty-handlersocket - Lua handlersocket client driver for the ngx_lua based on the cosocket API 

Status
======

This library is considered experimental and still under active development.

Description
===========

This Lua library is a handlersocket client driver for the ngx_lua nginx module:

http://wiki.nginx.org/HttpLuaModule

This Lua library takes advantage of ngx_lua's cosocket API, which ensures
100% nonblocking behavior.

Note that at least [ngx_lua 0.5.14](https://github.com/chaoslawful/lua-nginx-module/tags) or [ngx_openresty 1.2.1.14](http://openresty.org/#Download) is required.

Synopsis
========

    lua_package_path "/path/to/lua-resty-handlersocket/lib/?.lua;;";

    server {
        location /test {
            content_by_lua '
				local handlersocket = require "resty.handlersocket"
				local hs = handlersocket:new()
				local cjson = require "cjson"

				hs:set_timeout(1000) -- 1 sec

				local ok, err = hs:connect("127.0.0.1", 9999)
				if not ok then
				    ngx.say("failed to connect: ", err)
				    return
				end

				ok, err = hs:open_index({'1','test','t','PRIMARY','id,a,b'})  
				-- now support open_index,find,find_modify,insert,auth https://github.com/DeNA/HandlerSocket-Plugin-for-MySQL/blob/master/docs-en/protocol.en.txt
				if not ok then
				    ngx.say("failed to open index: ", err)
				    return
				else
				    ngx.say(ok)
				end

				ok, err = hs:insert({'1','+','3','','xxx','yyy'})  

				if not ok then
				    ngx.say("failed to find: ", err)
				    return
				else
				    ngx.say(ok)
				end

				ok, err = hs:find({'1','>','1','1','100','0'})  

				if not ok then
				    ngx.say("failed to find: ", err)
				    return
				else
				    ngx.say(cjson.encode(ok))
				end
            ';
        }
    }


Methods
===========


Limitations
===========

* This library cannot be used in code contexts like set_by_lua*, log_by_lua*, and
header_filter_by_lua* where the ngx_lua cosocket API is not available.
* The `resty.handlersocket` object instance cannot be stored in a Lua variable at the Lua module level,
because it will then be shared by all the concurrent requests handled by the same nginx
 worker process (see
http://wiki.nginx.org/HttpLuaModule#Data_Sharing_within_an_Nginx_Worker ) and
result in bad race conditions when concurrent requests are trying to use the same `resty.handlersocket` instance.
You should always initiate `resty.handlersocket` objects in function local
variables or in the `ngx.ctx` table. These places all have their own data copies for
each request.

Installation
============

If you are using the ngx_openresty bundle (http://openresty.org ), then
you don't need to do anything because it already includes and enables
lua-resty-handlersocket by default. And you can just use it in your Lua code,
as in

    local handlersocket = require "resty.handlersocket"
    ...

If you're using your own nginx + ngx_lua build, then you need to configure
the lua_package_path directive to add the path of your lua-resty-handlersocket source
tree to ngx_lua's LUA_PATH search path, as in

    # nginx.conf
    http {
        lua_package_path "/path/to/lua-resty-handlersocket/lib/?.lua;;";
        ...
    }

TODO
====

Community
=========

English Mailing List
--------------------

The [openresty-en](https://groups.google.com/group/openresty-en) mailing list is for English speakers.

Chinese Mailing List
--------------------

The [openresty](https://groups.google.com/group/openresty) mailing list is for Chinese speakers.

Bugs and Patches
================

Please report bugs or submit patches by

1. creating a ticket on the [GitHub Issue Tracker](http://github.com/zhhchen/lua-resty-gearman/issues)

Author
======

Zhihua Chen (陈智华) <zhhchen@gmail.com>

Copyright and License
=====================

This module is licensed under the BSD license.

Copyright (C) 2012, by Zhihua Chen (陈智华) <zhhchen@gmail.com>.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

See Also
========
* the ngx_lua module: http://wiki.nginx.org/HttpLuaModule
* the handlersocket protocol specification: https://github.com/DeNA/HandlerSocket-Plugin-for-MySQL/blob/master/docs-en/protocol.en.txt

