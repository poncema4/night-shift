--!nonstrict
-- A small stand-in for the parts of Roblox the SERVER code touches (Instance, Vector3, CFrame, Enum, services, task),
-- so tests can actually run HotelBuilder, Props and RoundService.start() and catch runtime errors (a nil index,
-- a wrong argument) that the type-checker cannot see. It is deliberately simple: enough to execute the code, not to
-- be physically correct. Modules are loaded from src/ the way Rojo maps them: ReplicatedStorage.Shared -> src/shared,
-- script.Parent.X -> a sibling file.
local fs = require("@lune/fs")
local luau = require("@lune/luau")

local Fake = {}

-- ===== maths =====

local V3 = {}
local function v3(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3)
end
V3.__type = "Vector3"
V3.__index = function(t, k)
	if k == "Magnitude" then
		return math.sqrt(t.X ^ 2 + t.Y ^ 2 + t.Z ^ 2)
	elseif k == "Unit" then
		local m = math.sqrt(t.X ^ 2 + t.Y ^ 2 + t.Z ^ 2)
		return if m == 0 then v3(0, 0, 0) else v3(t.X / m, t.Y / m, t.Z / m)
	elseif k == "Lerp" then
		return function(a, b, alpha)
			return v3(a.X + (b.X - a.X) * alpha, a.Y + (b.Y - a.Y) * alpha, a.Z + (b.Z - a.Z) * alpha)
		end
	elseif k == "Dot" then
		return function(a, b)
			return a.X * b.X + a.Y * b.Y + a.Z * b.Z
		end
	end
	return nil
end
V3.__add = function(a, b)
	return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
V3.__sub = function(a, b)
	return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
V3.__mul = function(a, b)
	if type(a) == "number" then
		return v3(a * b.X, a * b.Y, a * b.Z)
	elseif type(b) == "number" then
		return v3(a.X * b, a.Y * b, a.Z * b)
	end
	return v3(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3.__div = function(a, b)
	if type(b) == "number" then
		return v3(a.X / b, a.Y / b, a.Z / b)
	end
	return v3(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
V3.__unm = function(a)
	return v3(-a.X, -a.Y, -a.Z)
end
V3.__eq = function(a, b)
	return a.X == b.X and a.Y == b.Y and a.Z == b.Z
end
V3.__tostring = function(a)
	return `{a.X}, {a.Y}, {a.Z}`
end
local Vector3 = { new = v3, zero = v3(0, 0, 0) }

-- CFrame: a position and a 3x3 rotation (rows).
local CF = {}
CF.__type = "CFrame"
local function cf(p, r)
	return setmetatable({ p = p, r = r }, CF)
end
local IDENTITY = { { 1, 0, 0 }, { 0, 1, 0 }, { 0, 0, 1 } }
local function matmul(a, b)
	local out = { {}, {}, {} }
	for i = 1, 3 do
		for j = 1, 3 do
			out[i][j] = a[i][1] * b[1][j] + a[i][2] * b[2][j] + a[i][3] * b[3][j]
		end
	end
	return out
end
local function apply(r, v)
	return v3(
		r[1][1] * v.X + r[1][2] * v.Y + r[1][3] * v.Z,
		r[2][1] * v.X + r[2][2] * v.Y + r[2][3] * v.Z,
		r[3][1] * v.X + r[3][2] * v.Y + r[3][3] * v.Z
	)
end
local function transpose(r)
	return { { r[1][1], r[2][1], r[3][1] }, { r[1][2], r[2][2], r[3][2] }, { r[1][3], r[2][3], r[3][3] } }
end
local function rotX(a)
	return { { 1, 0, 0 }, { 0, math.cos(a), -math.sin(a) }, { 0, math.sin(a), math.cos(a) } }
end
local function rotY(a)
	return { { math.cos(a), 0, math.sin(a) }, { 0, 1, 0 }, { -math.sin(a), 0, math.cos(a) } }
end
local function rotZ(a)
	return { { math.cos(a), -math.sin(a), 0 }, { math.sin(a), math.cos(a), 0 }, { 0, 0, 1 } }
end
CF.__mul = function(a, b)
	if getmetatable(b) == V3 then
		return apply(a.r, b) + a.p
	end
	return cf(apply(a.r, b.p) + a.p, matmul(a.r, b.r))
end
CF.__index = function(t, k)
	if k == "Position" then
		return t.p
	elseif k == "X" then
		return t.p.X
	elseif k == "Y" then
		return t.p.Y
	elseif k == "Z" then
		return t.p.Z
	elseif k == "Inverse" then
		return function(self)
			local rt = transpose(self.r)
			return cf(-apply(rt, self.p), rt)
		end
	elseif k == "ToObjectSpace" then
		return function(self, other)
			return CF.__index(self, "Inverse")(self) * other
		end
	elseif k == "ToWorldSpace" then
		return function(self, other)
			return self * other
		end
	elseif k == "LookVector" then
		return apply(t.r, v3(0, 0, -1))
	end
	return nil
end
CF.__tostring = function(a)
	return tostring(a.p)
end
local CFrame = {}
CFrame.identity = cf(v3(0, 0, 0), IDENTITY)
function CFrame.new(a, b, c)
	if a == nil then
		return CFrame.identity
	elseif type(a) == "number" then
		return cf(v3(a, b, c), IDENTITY)
	elseif b ~= nil then
		return CFrame.lookAt(a, b)
	end
	return cf(a, IDENTITY)
end
function CFrame.Angles(rx, ry, rz)
	return cf(v3(0, 0, 0), matmul(matmul(rotZ(rz), rotY(ry)), rotX(rx)))
end
function CFrame.lookAt(from, to)
	local look = (to - from).Unit
	local yaw = math.atan2(-look.X, -look.Z)
	return cf(from, rotY(yaw))
end

local C3 = {
	__type = "Color3",
	__eq = function(a, b)
		return math.abs(a.R - b.R) < 1e-6 and math.abs(a.G - b.G) < 1e-6 and math.abs(a.B - b.B) < 1e-6
	end,
}
local Color3 = {}
function Color3.new(r, g, b)
	return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, C3)
end
function Color3.fromRGB(r, g, b)
	return setmetatable({ R = r / 255, G = g / 255, B = b / 255 }, C3)
end
local UDim = {
	new = function(s, o)
		return { Scale = s, Offset = o }
	end,
}
local UDim2 = {
	new = function(xs, xo, ys, yo)
		return { X = { Scale = xs, Offset = xo }, Y = { Scale = ys, Offset = yo } }
	end,
	fromScale = function(x, y)
		return { X = { Scale = x, Offset = 0 }, Y = { Scale = y, Offset = 0 } }
	end,
	fromOffset = function(x, y)
		return { X = { Scale = 0, Offset = x }, Y = { Scale = 0, Offset = y } }
	end,
}
local Vector2 = {
	new = function(x, y)
		return { X = x, Y = y }
	end,
}
local NumberRange = {
	new = function(a, b)
		return { Min = a, Max = b or a }
	end,
}
local NumberSequence = {
	new = function(a, b)
		return { a, b }
	end,
}
local ColorSequence = {
	new = function(a)
		return { a }
	end,
}

-- Enum.<Type>.<Item> returns the same table every time, so comparisons work.
local function makeEnum()
	return setmetatable({}, {
		__index = function(enum, enumName)
			local items = setmetatable({}, {
				__index = function(list, itemName)
					local item = { Name = itemName, EnumType = enumName }
					rawset(list, itemName, item)
					return item
				end,
			})
			rawset(enum, enumName, items)
			return items
		end,
	})
end

-- ===== the world =====

function Fake.world()
	local world = {
		log = {},
		warnings = {},
		delayed = {},
		closers = {},
		players = {},
		tags = {},
		now = 1000,
		sleepers = {},
		actions = {},
		played = {},
		teleports = {},
		studio = true,
	}
	local depth = 0
	local moduleCache = {}

	-- signals
	local function newSignal()
		local handlers = {}
		local signal = {}
		function signal.Connect(_, fn)
			local handle = { fn = fn }
			table.insert(handlers, handle)
			return {
				Disconnect = function()
					handle.fn = nil
				end,
			}
		end
		function signal.Fire(_, ...)
			for _, h in handlers do
				if h.fn then
					h.fn(...)
				end
			end
		end
		function signal.Once(_, fn)
			return signal:Connect(fn)
		end
		return setmetatable(signal, { __type = "RBXScriptSignal" })
	end

	-- instances
	local parentClass = {
		Part = "BasePart",
		SpawnLocation = "Part",
		MeshPart = "BasePart",
		BasePart = "PVInstance",
		Model = "PVInstance",
		PVInstance = "Instance",
		PointLight = "Light",
		SpotLight = "Light",
		Light = "Instance",
	}
	local function isA(class, target)
		while class do
			if class == target then
				return true
			end
			class = parentClass[class]
		end
		return false
	end
	local signalNames = {
		Triggered = true,
		OnServerEvent = true,
		OnClientEvent = true,
		Died = true,
		Heartbeat = true,
		RenderStepped = true,
		PlayerAdded = true,
		PlayerRemoving = true,
		CharacterAdded = true,
		Changed = true,
		Activated = true,
		PromptGamePassPurchaseFinished = true,
		Equipped = true,
		Unequipped = true,
		MouseEnter = true,
		MouseLeave = true,
		InputBegan = true,
	}
	local Methods = {}
	local InstanceMT = { __type = "Instance" }
	local data = setmetatable({}, { __mode = "k" })

	local function create(class)
		local self = setmetatable({}, InstanceMT)
		local props = { Name = class }
		if isA(class, "BasePart") then
			props.Size = v3(4, 1, 2)
			props.CFrame = CFrame.identity
			props.Position = v3(0, 0, 0)
			props.Anchored = false
			props.CanCollide = true
			props.Transparency = 0
			props.Color = Color3.new(0.63, 0.63, 0.63)
		elseif isA(class, "Light") or class == "ScreenGui" or class == "ProximityPrompt" then
			props.Enabled = true
			props.Range = 8
			props.Brightness = 1
		elseif
			class == "Frame"
			or class == "TextLabel"
			or class == "TextButton"
			or class == "ImageLabel"
			or class == "ScrollingFrame"
		then
			props.Visible = true
			props.Active = false
			props.Text = ""
		elseif class == "Humanoid" then
			props.Health = 100
			props.MaxHealth = 100
			props.WalkSpeed = 16
			props.JumpHeight = 7.2
			props.MoveDirection = v3(0, 0, 0)
		end
		data[self] = { class = class, props = props, children = {}, attrs = {}, signals = {}, parent = nil }
		return self
	end

	local function reparent(self, newParent)
		local d = data[self]
		if d.parent then
			local siblings = data[d.parent].children
			local at = table.find(siblings, self)
			if at then
				table.remove(siblings, at)
			end
		end
		d.parent = newParent
		if newParent then
			table.insert(data[newParent].children, self)
		end
	end

	local function descendants(self, out)
		for _, child in data[self].children do
			table.insert(out, child)
			descendants(child, out)
		end
		return out
	end

	local function clone(self)
		local d = data[self]
		local copy = create(d.class)
		for k, v in d.props do
			data[copy].props[k] = v
		end
		for k, v in d.attrs do
			data[copy].attrs[k] = v
		end
		for _, child in d.children do
			reparent(clone(child), copy)
		end
		return copy
	end

	function Methods.IsA(self, class)
		return isA(data[self].class, class)
	end
	function Methods.GetChildren(self)
		return table.clone(data[self].children)
	end
	function Methods.GetDescendants(self)
		return descendants(self, {})
	end
	function Methods.FindFirstChild(self, name, recursive)
		for _, child in recursive and descendants(self, {}) or data[self].children do
			if data[child].props.Name == name then
				return child
			end
		end
		return nil
	end
	function Methods.WaitForChild(self, name)
		return Methods.FindFirstChild(self, name)
	end
	function Methods.FindFirstChildOfClass(self, class)
		for _, child in data[self].children do
			if data[child].class == class then
				return child
			end
		end
		return nil
	end
	function Methods.FindFirstChildWhichIsA(self, class)
		for _, child in data[self].children do
			if isA(data[child].class, class) then
				return child
			end
		end
		return nil
	end
	function Methods.Destroy(self)
		reparent(self, nil)
	end
	function Methods.Clone(self)
		return clone(self)
	end
	function Methods.SetAttribute(self, name, value)
		local d = data[self]
		local changed = d.attrs[name] ~= value
		d.attrs[name] = value
		local watcher = d.signals["attr:" .. name]
		if changed and watcher then
			watcher:Fire()
		end
	end
	function Methods.GetAttributeChangedSignal(self, name)
		local d = data[self]
		d.signals["attr:" .. name] = d.signals["attr:" .. name] or newSignal()
		return d.signals["attr:" .. name]
	end
	function Methods.Play(self)
		data[self].props.IsPlaying = true
		table.insert(world.played, data[self].props.SoundId)
	end
	function Methods.Pause(self)
		data[self].props.IsPlaying = false
	end
	function Methods.GetAttribute(self, name)
		return data[self].attrs[name]
	end
	function Methods.GetPropertyChangedSignal(self, name)
		local d = data[self]
		d.signals["prop:" .. name] = d.signals["prop:" .. name] or newSignal()
		return d.signals["prop:" .. name]
	end
	function Methods.GetPivot(self)
		return data[self].props.CFrame or CFrame.identity
	end
	function Methods.PivotTo(self, target)
		data[self].props.CFrame = target
	end
	function Methods.GetServerTimeNow(_)
		return world.now
	end
	function Methods.Raycast(_, _origin, _direction, _params)
		return if world.rayBlocked then { Instance = world.workspace } else nil
	end
	-- Remotes deliver to the local fake client too, so server and client code talk to each other in one world.
	function Methods.FireClient(self, player, ...)
		table.insert(world.log, { remote = data[self].props.Name, to = "client", args = { player, ... } })
		if world.localPlayer == player then
			self.OnClientEvent:Fire(...)
		end
	end
	function Methods.FireAllClients(self, ...)
		table.insert(world.log, { remote = data[self].props.Name, to = "all", args = { ... } })
		if world.localPlayer then
			self.OnClientEvent:Fire(...)
		end
	end
	-- Tools: equipping moves the tool from the Backpack into the character (and back), firing the same events as Roblox.
	local function ownerOf(humanoid)
		for _, p in world.players do
			if p.Character and data[p.Character] and humanoid.Parent == p.Character then
				return p
			end
		end
		return nil
	end
	function Methods.EquipTool(self, tool)
		local player = ownerOf(self)
		if player then
			reparent(tool, player.Character)
			tool.Equipped:Fire()
		end
	end
	function Methods.UnequipTools(self)
		local player = ownerOf(self)
		local backpack = player and player:FindFirstChild("Backpack")
		if player and backpack then
			for _, child in player.Character:GetChildren() do
				if child:IsA("Tool") then
					reparent(child, backpack)
					child.Unequipped:Fire()
				end
			end
		end
	end
	function Methods.SetTeleportData(self, value)
		data[self].props.TeleportData = value
	end
	function Methods.FireServer(self, ...)
		table.insert(world.log, { remote = data[self].props.Name, to = "server", args = { ... } })
		if world.localPlayer then
			self.OnServerEvent:Fire(world.localPlayer, ...)
		end
	end

	InstanceMT.__index = function(self, key)
		local d = data[self]
		if key == "ClassName" then
			return d.class
		elseif key == "Parent" then
			return d.parent
		elseif Methods[key] then
			return Methods[key]
		elseif signalNames[key] then
			d.signals[key] = d.signals[key] or newSignal()
			return d.signals[key]
		end
		local value = d.props[key]
		if value ~= nil then
			return value
		end
		if d.class == "ReplicatedStorage" and key == "Shared" then
			return world.shared
		end
		if d.class == "Player" and key == "LoadCharacter" then
			return function(player)
				return world.spawnCharacter(player)
			end
		end
		return Methods.FindFirstChild(self, key)
	end
	InstanceMT.__newindex = function(self, key, value)
		local d = data[self]
		if key == "Parent" then
			reparent(self, value)
			return
		end
		d.props[key] = value
		if key == "Health" and d.class == "Humanoid" and value <= 0 and not d.died then
			d.died = true
			self.Died:Fire()
		end
		if key == "Position" and d.props.CFrame then
			d.props.CFrame = CFrame.new(value) * cf(v3(0, 0, 0), d.props.CFrame.r)
		elseif key == "CFrame" then
			d.props.Position = value.p
		end
		local watcher = d.signals["prop:" .. key]
		if watcher then
			watcher:Fire()
		end
	end

	local Instance = {
		new = function(class, parent)
			local inst = create(class)
			if parent then
				reparent(inst, parent)
			end
			return inst
		end,
	}

	-- services
	local services = {}
	local function service(name)
		if services[name] then
			return services[name]
		end
		local s = create(name)
		data[s].props.Name = name
		services[name] = s
		if name == "Players" then
			data[s].props.CharacterAutoLoads = true
			s.GetPlayers = function()
				return table.clone(world.players)
			end
			s.GetPlayerFromCharacter = function()
				return nil
			end
			s.GetUserThumbnailAsync = function()
				return "rbxthumb://fake", true
			end
			s.GetPlayerByUserId = function(_, userId)
				for _, player in world.players do
					if player.UserId == userId then
						return player
					end
				end
				return nil
			end
		elseif name == "ContextActionService" then
			s.BindAction = function(_, actionName, fn)
				world.actions[actionName] = fn
			end
			s.UnbindAction = function(_, actionName)
				world.actions[actionName] = nil
			end
			s.SetTitle = function() end
			s.SetPosition = function() end
		elseif name == "RunService" then
			s.IsStudio = function()
				return world.studio
			end
		elseif name == "CollectionService" then
			s.AddTag = function(_, inst, tag)
				world.tags[tag] = world.tags[tag] or {}
				table.insert(world.tags[tag], inst)
			end
			s.GetInstanceAddedSignal = function()
				return {
					Connect = function()
						return { Disconnect = function() end }
					end,
				}
			end
			s.GetTagged = function(_, tag)
				return world.tags[tag] or {}
			end
		elseif name == "MarketplaceService" then
			s.prompts = {}
			s.owned = {}
			s.PromptGamePassPurchase = function(_, player, id)
				table.insert(s.prompts, { kind = "pass", player = player, id = id })
			end
			s.PromptProductPurchase = function(_, player, id)
				table.insert(s.prompts, { kind = "product", player = player, id = id })
			end
			s.UserOwnsGamePassAsync = function(_, userId, id)
				return s.owned[userId .. ":" .. id] == true
			end
		elseif name == "TeleportService" then
			s.SetTeleportGui = function(_, gui)
				world.teleportGui = gui
			end
			s.ReserveServer = function()
				return "reserved-code"
			end
			s.TeleportAsync = function(_, placeId, players, options)
				table.insert(world.teleports, { placeId = placeId, players = players, options = options })
			end
		elseif name == "DataStoreService" then
			s.GetDataStore = function()
				local store = {}
				return {
					GetAsync = function(_, key)
						return store[key]
					end,
					UpdateAsync = function(_, key, fn)
						store[key] = fn(store[key])
						return store[key]
					end,
				}
			end
		end
		return s
	end

	local game = { PlaceId = 1, PrivateServerId = "", PrivateServerOwnerId = 0 }
	function game.GetService(_, name)
		return service(name)
	end
	function game.BindToClose(_, fn)
		table.insert(world.closers, fn)
	end
	local workspaceInstance = create("Workspace")
	data[workspaceInstance].props.Name = "Workspace"

	-- modules: ReplicatedStorage.Shared.X -> src/shared/X, script.Parent.X -> a sibling
	local function dirname(path)
		return (string.gsub(path, "/[^/]*$", ""))
	end
	local function proxy(path)
		return setmetatable({ __proxy = path }, {
			__index = function(_, k)
				if k == "Parent" then
					return proxy(dirname(path))
				end
				return proxy(path .. "/" .. k)
			end,
		})
	end
	world.shared = proxy("src/shared")

	local function fakeTypeof(x)
		local mt = getmetatable(x)
		if type(x) == "table" and mt and mt.__type then
			return mt.__type
		end
		return type(x)
	end
	local task = {
		spawn = function(f, ...)
			local co = coroutine.create(f)
			depth += 1
			local ok, err = coroutine.resume(co, ...)
			depth -= 1
			if not ok then
				error(err, 0)
			end
			return co
		end,
		wait = function(t)
			if depth > 0 then
				table.insert(world.sleepers, { co = coroutine.running(), wake = world.now + (t or 0.03) })
				coroutine.yield()
			end
			return t or 0
		end,
		delay = function(t, f, ...)
			local args = table.pack(...)
			table.insert(world.sleepers, {
				fn = function()
					f(table.unpack(args, 1, args.n))
				end,
				wake = world.now + t,
			})
		end,
	}
	task.defer = task.spawn

	local loadModule
	local function environmentFor(path)
		local env = {
			Instance = Instance,
			Vector3 = Vector3,
			Vector2 = Vector2,
			CFrame = CFrame,
			Color3 = Color3,
			UDim = UDim,
			UDim2 = UDim2,
			NumberRange = NumberRange,
			NumberSequence = NumberSequence,
			ColorSequence = ColorSequence,
			Enum = world.enum,
			RaycastParams = {
				new = function()
					return { FilterDescendantsInstances = {} }
				end,
			},
			game = game,
			workspace = workspaceInstance,
			script = proxy(path),
			task = task,
			os = setmetatable({
				clock = function()
					return world.now
				end,
			}, { __index = os }),
			typeof = fakeTypeof,
			print = function(...)
				local parts = {}
				for _, v in { ... } do
					table.insert(parts, tostring(v))
				end
				table.insert(world.log, { print = table.concat(parts, " ") })
			end,
			warn = function(...)
				local parts = {}
				for _, v in { ... } do
					table.insert(parts, tostring(v))
				end
				table.insert(world.warnings, table.concat(parts, " "))
			end,
		}
		env.require = function(target)
			if type(target) == "string" then
				return loadModule(dirname(path) .. "/" .. target) -- "./Hotel" or "../x/Y": relative to this module
			end
			return loadModule(rawget(target, "__proxy"))
		end
		return env
	end

	loadModule = function(path)
		path = string.gsub(path, "//+", "/")
		-- collapse "a/b/../c" and "a/./b"
		local parts = {}
		for piece in string.gmatch(path, "[^/]+") do
			if piece == ".." then
				table.remove(parts)
			elseif piece ~= "." then
				table.insert(parts, piece)
			end
		end
		path = table.concat(parts, "/")
		if moduleCache[path] ~= nil then
			return moduleCache[path].value
		end
		local file = path .. ".luau"
		if not fs.isFile(file) then
			error(`fake require: no module at {file}`)
		end
		local chunk = luau.load(fs.readFile(file), { debugName = path, environment = environmentFor(path) })
		local entry = { value = nil }
		moduleCache[path] = entry
		entry.value = chunk()
		return entry.value
	end

	-- Moves the clock forward in small steps: wakes sleeping tasks and fires RunService.Heartbeat each step.
	function world.advance(seconds, step)
		step = step or 0.1
		local steps = math.max(1, math.floor(seconds / step + 0.5))
		for _ = 1, steps do
			world.now += step
			local due = {}
			local waiting = {}
			for _, sleeper in world.sleepers do
				table.insert(if sleeper.wake <= world.now then due else waiting, sleeper)
			end
			world.sleepers = waiting
			for _, sleeper in due do
				depth += 1
				local co = sleeper.co or coroutine.create(sleeper.fn)
				local ok, err = coroutine.resume(co)
				depth -= 1
				if not ok then
					error(err, 0)
				end
			end
			service("RunService").Heartbeat:Fire(step)
		end
	end

	function world.spawnCharacter(player)
		local d = data[player]
		local old = d.props.Character
		if old then
			old:Destroy()
		end
		local character = create("Model")
		data[character].props.Name = d.props.Name
		local humanoid = create("Humanoid")
		data[humanoid].props.Name = "Humanoid"
		reparent(humanoid, character)
		for _, name in { "HumanoidRootPart", "Head" } do
			local part = create("Part")
			data[part].props.Name = name
			data[part].props.Size = v3(2, 2, 1)
			reparent(part, character)
		end
		character.HumanoidRootPart.Position = v3(-45, 3, -14)
		reparent(character, workspaceInstance)
		d.props.Character = character
		player.CharacterAdded:Fire(character)
		return character
	end

	-- A fake player already in the server.
	function world.addPlayer(name, userId)
		local player = create("Player")
		data[player].props.Name = name
		data[player].props.UserId = userId
		local gui = create("PlayerGui")
		data[gui].props.Name = "PlayerGui"
		reparent(gui, player)
		local backpack = create("Backpack")
		data[backpack].props.Name = "Backpack"
		reparent(backpack, player)
		table.insert(world.players, player)
		service("Players").PlayerAdded:Fire(player)
		return player
	end

	-- A player leaves the server (the DataStore keeps what was saved).
	function world.removePlayer(player)
		service("Players").PlayerRemoving:Fire(player)
		local at = table.find(world.players, player)
		if at then
			table.remove(world.players, at)
		end
		data[player].props.Character = nil
	end

	-- Makes `player` the one this fake client belongs to (Players.LocalPlayer) and gives it a camera.
	function world.setLocal(player)
		world.localPlayer = player
		data[service("Players")].props.LocalPlayer = player
		local camera = create("Camera")
		data[camera].props.Name = "Camera"
		data[workspaceInstance].props.CurrentCamera = camera
	end

	-- One rendered frame on the client.
	function world.render(dt)
		service("RunService").RenderStepped:Fire(dt or 1 / 60)
	end

	function world.humanoid(player)
		return player.Character:FindFirstChildOfClass("Humanoid")
	end

	function world.root(player)
		return player.Character:FindFirstChild("HumanoidRootPart")
	end

	-- The first ProximityPrompt under `root` whose ActionText matches (optionally closest to `near`).
	function world.prompts(root, actionText)
		local found = {}
		for _, inst in root:GetDescendants() do
			if inst:IsA("ProximityPrompt") and inst.ActionText == actionText then
				table.insert(found, inst)
			end
		end
		return found
	end

	world.enum = makeEnum()
	world.Vector3 = Vector3
	world.CFrame = CFrame
	world.game = game
	world.workspace = workspaceInstance
	world.service = service
	world.data = data
	world.load = loadModule
	world.instance = Instance
	world.typeof = fakeTypeof
	return world
end

return Fake
