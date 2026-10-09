--!strict
-- Run on the Windows PC next to Studio:  lune run tools/logserver
-- Receives Output lines from src/server/LogForwarder.luau on localhost:8765, appends them to
-- ../night-shift-logs/studio.log and pushes that to the `studio-logs` branch so Claude can read it.
local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")
local task = require("@lune/task")

local PORT = 8765
local BRANCH = "studio-logs"
local MAX_BYTES = 200_000 -- keep the file small: only the newest part is pushed
local PUSH_SECONDS = 10

local function git(args: { string }, cwd: string?)
	return process.exec("git", args, if cwd then { cwd = cwd } else nil)
end

local repo = process.cwd
local logs = (repo :: string):gsub("[/\\]+$", "") .. "-logs"

local function ensureWorktree()
	if fs.isDir(logs) then
		return
	end
	local has = git({ "rev-parse", "--verify", "--quiet", "refs/remotes/origin/" .. BRANCH }).ok
	local made = if has
		then git({ "worktree", "add", "-B", BRANCH, logs, "origin/" .. BRANCH })
		else git({ "worktree", "add", "--orphan", "-b", BRANCH, logs })
	if not made.ok then
		error("could not create the logs worktree: " .. made.stderr)
	end
end

ensureWorktree()
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

print(`Listening on http://localhost:{PORT}/log  ->  {file}  ->  branch {BRANCH}`)

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
		local pushed = git({ "push", "-q", "--force", "origin", BRANCH }, logs)
		if not pushed.ok then
			print("push failed: " .. pushed.stderr)
		end
	end
end
