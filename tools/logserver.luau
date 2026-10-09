--!strict
-- Run on the Windows PC next to Studio:  lune run tools/logserver
-- Receives Output lines from src/server/LogForwarder.luau on localhost:8765, appends them to
-- ../night-shift-logs/studio.log and pushes that to the separate private repo night-shift-logs, so this
-- repo never gets a log branch and Claude can still read the latest Output.
local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")
local task = require("@lune/task")

local PORT = 8765
local BRANCH = "main"
local MAX_BYTES = 200_000 -- keep the file small: only the newest part is pushed
local PUSH_SECONDS = 10

local function git(args: { string }, cwd: string?)
	return process.exec("git", args, if cwd then { cwd = cwd } else nil)
end

local repo = (process.cwd :: string):gsub("[/\\]+$", "")
local logs = repo .. "-logs"

-- The logs repo lives next to this one and is named after it: .../night-shift -> .../night-shift-logs.
local function logsUrl(): string
	local origin = git({ "remote", "get-url", "origin" })
	if not origin.ok then
		error("no origin remote: " .. origin.stderr)
	end
	local url = (origin.stdout:gsub("%s+$", ""):gsub("%.git$", ""))
	return url .. "-logs.git"
end

local function ensureLogsRepo()
	local url = logsUrl()
	if fs.isDir(logs) then
		local current = git({ "config", "--get", "remote.origin.url" }, logs)
		if current.ok and current.stdout:gsub("%s+$", "") == url then
			return
		end
		error(`{logs} is the old log folder. Delete it (and run: git worktree prune) then start this again.`)
	end
	local cloned = git({ "clone", "-q", url, logs })
	if not cloned.ok then
		error("could not clone the logs repo: " .. cloned.stderr)
	end
end

ensureLogsRepo()
local file = logs .. "/studio.log"
local dirty = false

local function append(text: string)
	local old = if fs.isFile(file) then fs.readFile(file) else ""
	local combined = old .. text .. "\n"
	if #combined > MAX_BYTES then
		combined = string.sub(combined, #combined - MAX_BYTES + 1)
	end
	fs.writeFile(file, combined)
	dirty = true
end

net.serve(PORT, function(request)
	if request.method == "POST" and request.path == "/log" then
		append(request.body)
		return { status = 200, body = "ok" }
	end
	return { status = 404, body = "not found" }
end)

print(`Listening on http://localhost:{PORT}/log  ->  {file}  ->  {logsUrl()} ({BRANCH})`)

-- One commit, force-pushed every time: no history growth, only the latest log matters.
while true do
	task.wait(PUSH_SECONDS)
	if dirty then
		dirty = false
		git({ "add", "studio.log" }, logs)
		local commit = { "-c", "user.name=night-shift-logs", "-c", "user.email=noreply@example.com", "commit", "-q" }
		if git({ "rev-parse", "--verify", "--quiet", "HEAD" }, logs).ok then
			table.insert(commit, "--amend")
		end
		table.insert(commit, "-m")
		table.insert(commit, "studio log")
		git(commit, logs)
		local pushed = git({ "push", "-q", "--force", "origin", "HEAD:" .. BRANCH }, logs)
		if not pushed.ok then
			print("push failed: " .. pushed.stderr)
		end
	end
end
