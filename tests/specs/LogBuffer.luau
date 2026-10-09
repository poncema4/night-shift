--!strict
local LogBuffer = require("../../src/shared/Util/LogBuffer")

return function(t)
	local b = LogBuffer.new(3, 10)
	b:add("one", "output", 1)
	b:add("two", "error", 2.25)
	local entries, dropped = b:drain()
	t.equal("drain returns what was added", #entries, 2)
	t.equal("nothing dropped under the cap", dropped, 0)
	t.equal("drain empties the buffer", #(b:drain()), 0)

	for i = 1, 5 do
		b:add("m" .. i, "output", i)
	end
	entries, dropped = b:drain()
	t.equal("cap keeps only the newest entries", #entries, 3)
	t.equal("cap counts what it dropped", dropped, 2)
	t.equal("oldest kept entry is m3", entries[1].message, "m3")

	b:add("abcdefghijklmnop", "warning", 0)
	entries = b:drain()
	t.equal("long messages are cut", entries[1].message, "abcdefghij...[cut]")

	t.equal(
		"format prints time, kind, message",
		LogBuffer.format({ { message = "boom", kind = "error", time = 2.25 } }, 0),
		"[2.2] ERROR boom"
	)
	t.check(
		"format mentions dropped lines",
		string.find(LogBuffer.format({}, 4), "4 older lines dropped", 1, true) ~= nil
	)
end
