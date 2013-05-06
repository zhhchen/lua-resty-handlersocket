-- Copyright (C) 2013 Zhihua Chen (zhhchen)
local bit = require("bit")
local sub = string.sub
local tcp = ngx.socket.tcp
local sleep = ngx.sleep
local insert = table.insert
local concat = table.concat
local foreach = table.foreach
local floor = math.floor
local len = string.len
local null = ngx.null
local print = ngx.print
local byte = string.byte
local setmetatable = setmetatable
local tonumber = tonumber
local error = error

module(...)

_VERSION = '0.01'

local commands = {
    open_index='open_index',
    find='find',
    find_modify='find_modify',
    insert='insert',
    auth='auth'
}


local mt = { __index = _M }


function new(self)
    local sock, err = tcp()
    if not sock then
        return nil, err
    end
    return setmetatable({ sock = sock }, mt)
end


function set_timeout(self, timeout)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    return sock:settimeout(timeout)
end


function connect(self, ...)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    return sock:connect(...)
end


function set_keepalive(self, ...)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    return sock:setkeepalive(...)
end


function get_reused_times(self)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    return sock:getreusedtimes()
end


function close(self)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    return sock:close()
end


function hsencode(str)
    local enstr = ''
    if str == 'NULL' then
        return '\0'
    end
    string.gsub(str, "([\0-\15])", function(c) enstr = '\1'..bit.bor(c,'\64') end) 
    return enstr
end

function hsdecode(str)
    local destr = ''
    if str == '\0' then
        return 'NULL'
    end
    string.gsub(str, "\1([\64-\79])", function(c) destr = bit.band(c,'\15') end) 
    return destr
end

local function _read_reply(sock,cmd)
    local line, err = sock:receiveuntil('\n')
    if not line then
        return nil, err
    end
    local resarr = split(line,'\t')
    if resarr[1] ~= '0' then
        if resarr[3] == nil then
            resarr[3] = 'read reply err'
        end
        return nil, resarr[3]
    end

    if cmd == 'insert' or cmd == 'auth' or cmd == 'open_index' then
        return 'ok'
    elseif cmd == 'find_modify' then
        return resarr[3]
    else
        local allrow = {}
        local onerow = {}
        local numcols = tonumber(resarr[2])
        for i=3,table.getn(resarr) do
            resarr[i] = hsdecode(resarr[i])
            table.insert(onerow,resarr[i])
            numcols = numcols - 1
            if numcols == 0 then
                table.insert(allrow,onerow)
                numcols = tonumber(resarr[2])
                onerow = {}
            end
        end
        return allrow
    end
end


local function _gen_req(cmd, args)
    local req = {}
    if cmd == 'open_index' then
        table.foreach(args[1], function(ii, vv) args[1][ii] = hsencode(vv) end)
        table.insert(req,'P\t'..concat(args[1], '\t'))
    elseif cmd == 'auth' then
        table.foreach(args[1], function(ii, vv) args[1][ii] = hsencode(vv) end)
        table.insert(req,'A\t'..concat(args[1], '\t'))
    else
        table.foreach(args, function(i, v) 
            table.foreach(v, function(ii, vv) v[ii] = hsencode(vv) end)
            table.insert(req,concat(v, '\t'))
        end)
    end

    return concat(req, '\n')..'\n'
end


local function _do_cmd(self, cmd, ...)
    local args = {...}
    if #args ~= 1 then
        return nil, "args error"
    end

    if table.getn(args[1]) < 1 then
        return nil, "args error"
    end

    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    local req = _gen_req(cmd, args[1])

    local bytes, err = sock:send(req)
    if not bytes then
        return nil, err
    end

    return _read_reply(sock, cmd)
end


foreach(commands, function(i, v, self)
    local cmd, val = i, v
    _M[cmd] =
        function (self, ...)
            return _do_cmd(self, val, ...)
        end
end)


local class_mt = {
    -- to prevent use of casual module global variables
    __newindex = function (table, key, val)
        error('attempt to write to undeclared variable "' .. key .. '"')
    end
}


setmetatable(_M, class_mt)

