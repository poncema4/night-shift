--!strict
-- Collects log lines in memory with hard caps, so a flood of output can never grow without limit.
-- Pure Luau (no Roblox services) so the tests can run it.

export type Entry = { message: string, kind: string, time: number }

local LogBuffer = {}
LogBuffer.__index = LogBuffer

export type LogBuffer = typeof(setmetatable(
	{} :: { entries: { Entry }, dropped: number, maxEntries: number, maxLength: number },
	LogBuffer
))

function LogBuffer.new(maxEntries: number, maxLength: number): LogBuffer
	return setmetatable({ entries = {}, dropped = 0, maxEntries = maxEntries, maxLength = maxLength }, LogBuffer)
end

function LogBuffer.add(self: LogBuffer, message: string, kind: string, time: number)
	if #message > self.maxLength then
		message = string.sub(message, 1, self.maxLength) .. "...[cut]"
	end
	if #self.entries >= self.maxEntries then
		table.remove(self.entries, 1)
		self.dropped += 1
	end
	table.insert(self.entries, { message = message, kind = kind, time = time })
end

-- Returns what was collected and empties the buffer.
function LogBuffer.drain(self: LogBuffer): ({ Entry }, number)
	local entries, dropped = self.entries, self.dropped
	self.entries, self.dropped = {}, 0
	return entries, dropped
end

function LogBuffer.format(entries: { Entry }, dropped: number): string
	local lines = {}
	if dropped > 0 then
		table.insert(lines, `[{dropped} older lines dropped]`)
	end
	for _, entry in entries do
		table.insert(lines, string.format("[%.1f] %s %s", entry.time, string.upper(entry.kind), entry.message))
	end
	return table.concat(lines, "\n")
end

return LogBuffer
