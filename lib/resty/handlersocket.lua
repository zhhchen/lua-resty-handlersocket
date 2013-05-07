-- Copyright (C) 2013 Zhihua Chen (zhhchen)

local sub     = string.sub
local find    = string.find
local gsub    = string.gsub
local match   = string.match
local format  = string.format
local byte    = string.byte
local char    = string.char
local tcp     = ngx.socket.tcp
local insert  = table.insert
local concat  = table.concat
local getn    = table.getn
local foreach = table.foreach
local print   = ngx.print
local setmetatable = setmetatable
local tonumber = tonumber
local error = error

module(...)

_VERSION = '0.02'

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


local function hsencode(str)
    local enstr = ''
    if str == 'NULL' then
        return char(0)
    end
    enstr = gsub(str, "([%z"..char(1).."-"..char(15).."])", function(c)
    	return char(1)..char(byte(c)+64)
    end)
    return enstr
end

local function hsdecode(str)
    local destr = ''
    if str == char(0) then
        return 'NULL'
    end
    destr = gsub(str, char(1).."(["..char(64).."-"..char(79).."])", function(c)
    	return char(byte(c)-64)
    end)
    return destr
end

local function explode(p,d)
	local t, ll, l
	t={}
	ll=0
	if(#p == 1) then return {p} end
	while true do
		l=find(p,d,ll,true) -- find the next d in the string
		if l~=nil then -- if "not not" found then..
			insert(t, sub(p,ll,l-1)) -- Save it in our array.
			ll=l+1 -- save just after where we found it for searching next time.
		else
			insert(t, sub(p,ll)) -- Save what's left in our array.
			break -- Break at end, as it should be, according to the lua manual.
		end
	end
	return t
end

local function _read_reply(sock,cmd)
    local reader = sock:receiveuntil('\n')
    local data, err, partial = reader()
    if not data then
        return nil, err
    end

    local resarr = explode(data,'\t')
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
        for i=3,getn(resarr) do
            resarr[i] = hsdecode(resarr[i])
            insert(onerow,resarr[i])
            numcols = numcols - 1
            if numcols == 0 then
                insert(allrow,onerow)
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
        foreach(args, function(i, v) args[i] = hsencode(v) end)
        insert(req,'P\t'..concat(args, '\t'))
    elseif cmd == 'auth' then
        foreach(args, function(i, v) args[i] = hsencode(v) end)
        insert(req,'A\t'..concat(args, '\t'))
    else
        foreach(args, function(i, v) args[i] = hsencode(v) end)
        insert(req,concat(args, '\t'))
    end

    return concat(req, '\n')..'\n'
end


local function _do_cmd(self, cmd, args)

    if getn(args) < 1 then
        return nil, "args error"
    end

    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    local req = _gen_req(cmd, args)
--    print(req)
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

