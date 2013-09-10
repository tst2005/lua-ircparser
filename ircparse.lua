local assert = assert

local _M = {} -- the module

--protocol parsing
--[[ RFC 1459 / 2.3.1

	<message>  ::= [':' <prefix> <SPACE> ] <command> <params> <crlf>
	<prefix>   ::= <servername> | <nick> [ '!' <user> ] [ '@' <host> ]
	<command>  ::= <letter> { <letter> } | <number> <number> <number>
	<SPACE>    ::= ' ' { ' ' }
	<params>   ::= <SPACE> [ ':' <trailing> | <middle> <params> ]

	<middle>   ::= <Any *non-empty* sequence of octets not including SPACE
	               or NUL or CR or LF, the first of which may not be ':'>
	<trailing> ::= <Any, possibly *empty*, sequence of octets not including
	                 NUL or CR or LF>
	<crlf>     ::= CR LF
]]--
--[[ RFC 2812 / 2.3.1
    message    =  [ ":" prefix SPACE ] command [ params ] crlf
    prefix     =  servername / ( nickname [ [ "!" user ] "@" host ] )
    command    =  1*letter / 3digit
    params     =  *14( SPACE middle ) [ SPACE ":" trailing ]
               =/ 14( SPACE middle ) [ SPACE [ ":" ] trailing ]

    nospcrlfcl =  %x01-09 / %x0B-0C / %x0E-1F / %x21-39 / %x3B-FF
                    ; any octet except NUL, CR, LF, " " and ":"
    middle     =  nospcrlfcl *( ":" / nospcrlfcl )
    trailing   =  *( ":" / " " / nospcrlfcl )

    SPACE      =  %x20        ; space character
    crlf       =  %x0D %x0A   ; "carriage return" "linefeed"
]]--

local function parsePrefixCommand(line)
	local prefix
	local lineStart = 1 -- the begin of the current parsing task (prefix -> command -> middle...)
	if line:sub(1,1) == ":" then
		local space = line:find(" ", nil, true) -- plaintext search
		prefix = line:sub(2, space-1)
		lineStart = space
	end

	local _, cmdEnd, cmd = line:find("([^ ]+)", lineStart)

	return prefix, cmd, cmdEnd
end
_M.parsePrefixCommand = parsePrefixCommand

local function parseMiddle(line, cmdEnd, middleStop)
	local params = {}
	local pos = cmdEnd + 1
	while true do
		local _, stop, param = line:find("([^ ]+)", pos)

		if not param or (middleStop and stop > middleStop-1) then
			break
		end

		pos = stop + 1
		params[#params+1] = param
	end
	return params
end
_M.parseMiddle = parseMiddle

local function parseTrailing(line, cmdEnd)

	-- search ' :' plain (middleStop peux choper des espaces finaux ... pas grave)
	local middleStop, trailingStart = line:find("[ ]+:", cmdEnd)
	-- trailingStart : begin of trailing
	-- middleStop    : end   of middle (nil = end of line because no trailing)

	local trailing
	if trailingStart then
		trailing = line:sub(trailingStart + 1)
	end

	return trailing, middleStop
end
_M.parseTrailing = parseTrailing

local function parseMiddleTrailing(line, cmdEnd)
	local trailing, middleStop = parseTrailing(line, cmdEnd)
	local params = parseMiddle(line, cmdEnd, middleStop)
	return params, trailing
end
_M.parseMiddleTrailing = parseMiddleTrailing

-- FIXME: no hardcoded accessflaglist
local function parseAccessNick(access_nick, accesschars)
	local accesschars = accesschars or "%+@"
	local access, nick = access_nick:match("^(["..accesschars.."]?)(.+)$")
	return nick, access
end

-- FIXME: no hardcoded accessflaglist
local function parsePrefix(prefix)
	local user = {}
	if prefix then
		--FIXME: support nick / nick@host / nick!? / ?@host
		user.nick, user.username, user.host = prefix:match("^(.+)!(.+)@(.+)$")
	end
	return user
end

return _M -- the module
