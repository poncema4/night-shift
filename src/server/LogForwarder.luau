--!strict
-- Studio-only: sends the server Output to a tiny listener on this PC (tools/logserver.luau),
-- which pushes it to GitHub so Claude on the laptop can read errors. Never runs in the live game.
local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LogBuffer = require(ReplicatedStorage.Shared.Util.LogBuffer)

local URL = "http://localhost:8765/log"
local FLUSH_SECONDS = 2
local MAX_FAILURES = 3

local LogForwarder = {}

local KINDS: { [Enum.MessageType]: string } = {
	[Enum.MessageType.MessageOutput] = "output",
	[Enum.MessageType.MessageInfo] = "info",
	[Enum.MessageType.MessageWarning] = "warning",
	[Enum.MessageType.MessageError] = "error",
}

function LogForwarder.start()
	if not RunService:IsStudio() then
		return
	end
	local buffer = LogBuffer.new(500, 2000)
	local started = os.clock()
	local failures = 0
	local active = true

	LogService.MessageOut:Connect(function(message, messageType)
		if active then
			buffer:add(message, KINDS[messageType] or "output", os.clock() - started)
		end
	end)

	task.spawn(function()
		while active do
			task.wait(FLUSH_SECONDS)
			local entries, dropped = buffer:drain()
			if #entries > 0 or dropped > 0 then
				local ok = pcall(HttpService.PostAsync, HttpService, URL, LogBuffer.format(entries, dropped))
				failures = if ok then 0 else failures + 1
				if failures >= MAX_FAILURES then
					active = false -- stop first, so this print cannot feed back into the buffer
					print(
						"LogForwarder off: is scripts/logs running, and is Game Settings > Security > Allow HTTP Requests on?"
					)
				end
			end
		end
	end)
end

return LogForwarder
