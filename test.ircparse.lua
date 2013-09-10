local ircparse = require("ircparse")
local M = ircparse

local ppc, pm, pt, pmt = M.parsePrefixCommand, M.parseMiddle, M.parseTrailing, M.parseMiddleTrailing

local function ptest(data)
	local prefix, cmd, cmdEnd = ppc(data)
	local params, t = pmt(data, cmdEnd)

	local p
	for i,v in ipairs(params) do
		if not p then p = "" else p = p .. "," end
		p = p..("p%d='%s'"):format(i, v)
	end
	local r = ("prefix='%s'/cmd='%s'/params:%s/trailing='%s'"):format(prefix or "<none>", cmd, p or "<none>", t or "<none>")
	print(data)
	print("   "..r)
end


local i = {}
i[#i+1] = ":nick!user@host PRIVMSG #chan :text"
i[#i+1] = "NOTICE :text a b c : d"
i[#i+1] = "NOTICE target :text a b c : d"
i[#i+1] = "NOTICE target t2 t3 :text a b c : d"
i[#i+1] = "NOTICE target  t2   t3   :text a b c : d"
i[#i+1] = ":nick!user@host   NOTICE   target   t2   t3   :text a b c : d"




for _,line in ipairs(i) do
	ptest(line)
end


