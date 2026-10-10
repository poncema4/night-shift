--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Audio = require(script.Parent.Audio)
local CameraUi = require(script.Parent.CameraUi)
local CatchCam = require(script.Parent.CatchCam)
local Controls = require(script.Parent.Controls)
local Fx = require(script.Parent.Fx)
local Hiding = require(script.Parent.Hiding)
local Hud = require(script.Parent.Hud)
local Jail = require(script.Parent.Jail)
local Locker = require(script.Parent.Locker)
local MeetingUi = require(script.Parent.MeetingUi)
local Menu = require(script.Parent.Menu)
local Results = require(script.Parent.Results)
local Spectate = require(script.Parent.Spectate)
local ThreatView = require(script.Parent.ThreatView)

-- The server says whether this is the party lobby or a match (see Shared/Game/ServerMode).
while ReplicatedStorage:GetAttribute("ServerMode") == nil do
	ReplicatedStorage:GetAttributeChangedSignal("ServerMode"):Wait()
end
local mode = ReplicatedStorage:GetAttribute("ServerMode")

local Ui = require(script.Parent.Ui)

print(`{Config.GameName} client v{Config.Version} started in {mode}`)
if mode == "Lobby" then
	Menu.start()
else
	Hud.start()
	Fx.start()
	Hiding.start()
	CatchCam.start()
	Jail.start()
	ThreatView.start()
	Controls.start()
	MeetingUi.start()
	Results.start()
	Locker.start()
	CameraUi.start()
	Spectate.start()
	Audio.start()
	-- one pass over every match screen (and any that appear later): text never grows past its cap
	local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	for _, screen in playerGui:GetChildren() do
		Ui.tidy(screen)
	end
	playerGui.ChildAdded:Connect(Ui.tidy)
end
