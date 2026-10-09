--!strict
-- The Night Manager's body: a tall figure in a long dark bellhop coat with a pale mask and arms that
-- hang to his knees. Built from parts grouped into limbs so a client can pose it every frame.
-- Front is -Z. Groups rotate about their pivot; children follow their parent group.
local NightManagerRig = {}

export type Piece = { part: Part, offset: CFrame }
export type Limb = { name: string, parent: string?, pivot: CFrame, pieces: { Piece } }
export type Rig = { model: Model, limbs: { [string]: Limb }, order: { string } }

local COAT = Color3.fromRGB(14, 12, 18)
local COAT_TRIM = Color3.fromRGB(96, 18, 28)
local MASK = Color3.fromRGB(226, 220, 205)
local BRASS = Color3.fromRGB(190, 140, 62)
local EYE = Color3.fromRGB(255, 40, 60)

local function newPart(model: Model, name: string, size: Vector3, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

function NightManagerRig.build(): Rig
	local model = Instance.new("Model")
	model.Name = "NightManager"
	local limbs: { [string]: Limb } = {}
	local order: { string } = {}

	local function limb(name: string, parent: string?, pivot: Vector3): Limb
		local l: Limb = { name = name, parent = parent, pivot = CFrame.new(pivot), pieces = {} }
		limbs[name] = l
		table.insert(order, name)
		return l
	end
	local function add(
		l: Limb,
		name: string,
		size: Vector3,
		offset: Vector3,
		color: Color3,
		material: Enum.Material?
	): Part
		local p = newPart(model, name, size, color, material or Enum.Material.SmoothPlastic)
		table.insert(l.pieces, { part = p, offset = CFrame.new(offset) })
		return p
	end

	-- hips: a long coat that narrows toward the waist, with a tail that hangs lower at the back
	local hips = limb("Hips", nil, Vector3.new(0, 3.2, 0))
	add(hips, "Hem", Vector3.new(3.6, 0.2, 2.0), Vector3.new(0, 0.1, 0), COAT_TRIM, Enum.Material.Fabric)
	add(hips, "SkirtLow", Vector3.new(3.6, 0.9, 2.0), Vector3.new(0, 0.65, 0), COAT, Enum.Material.Fabric)
	add(hips, "SkirtMid", Vector3.new(3.1, 1.1, 1.8), Vector3.new(0, 1.65, 0), COAT, Enum.Material.Fabric)
	add(hips, "SkirtHigh", Vector3.new(2.6, 1.0, 1.7), Vector3.new(0, 2.7, 0), COAT, Enum.Material.Fabric)
	add(hips, "Tail", Vector3.new(2.8, 2.6, 0.2), Vector3.new(0, -0.1, 1.1), COAT, Enum.Material.Fabric)

	-- legs
	for _, side in { -1, 1 } do
		local leg = limb(if side < 0 then "LegL" else "LegR", "Hips", Vector3.new(side * 0.7, 3.2, 0))
		add(leg, "Leg", Vector3.new(0.8, 2.8, 0.8), Vector3.new(0, -1.4, 0), COAT, Enum.Material.Fabric)
		add(
			leg,
			"Shoe",
			Vector3.new(1, 0.4, 1.5),
			Vector3.new(0, -3.0, -0.25),
			Color3.fromRGB(6, 6, 8),
			Enum.Material.SmoothPlastic
		)
	end

	-- chest: narrow torso under a wide shoulder bar
	local chest = limb("Chest", "Hips", Vector3.new(0, 6.4, 0))
	add(chest, "Chest", Vector3.new(2.4, 2.5, 1.5), Vector3.new(0, 1.25, 0), COAT, Enum.Material.Fabric)
	add(chest, "Shoulders", Vector3.new(3.2, 0.5, 1.4), Vector3.new(0, 2.75, 0), COAT, Enum.Material.Fabric)
	add(chest, "Tie", Vector3.new(0.26, 2.0, 0.08), Vector3.new(0, 1.4, -0.79), COAT_TRIM, Enum.Material.Fabric)
	add(chest, "Badge", Vector3.new(0.5, 0.26, 0.06), Vector3.new(0.7, 2.0, -0.78), BRASS, Enum.Material.Metal)
	for i = 0, 2 do
		add(
			chest,
			"Button",
			Vector3.new(0.2, 0.2, 0.06),
			Vector3.new(-0.6, 0.5 + i * 0.6, -0.78),
			BRASS,
			Enum.Material.Metal
		)
	end

	-- head: tall pale mask, hollow eyes with a red spark, bellhop cap
	local head = limb("Head", "Chest", Vector3.new(0, 9.4, 0))
	add(head, "Neck", Vector3.new(0.5, 0.5, 0.5), Vector3.new(0, 0.25, 0), COAT, Enum.Material.Fabric)
	add(head, "Skull", Vector3.new(1.6, 2.7, 1.7), Vector3.new(0, 1.85, 0), COAT, Enum.Material.SmoothPlastic)
	add(head, "Mask", Vector3.new(1.3, 2.4, 0.12), Vector3.new(0, 1.85, -0.91), MASK, Enum.Material.SmoothPlastic)
	add(head, "Mouth", Vector3.new(0.8, 0.1, 0.04), Vector3.new(0, 1.0, -0.99), COAT, Enum.Material.SmoothPlastic)
	for _, side in { -1, 1 } do
		add(
			head,
			"Hollow",
			Vector3.new(0.34, 0.6, 0.06),
			Vector3.new(side * 0.32, 2.15, -0.99),
			COAT,
			Enum.Material.SmoothPlastic
		)
		add(
			head,
			"Spark",
			Vector3.new(0.13, 0.13, 0.04),
			Vector3.new(side * 0.32, 2.15, -1.04),
			EYE,
			Enum.Material.Neon
		)
	end
	add(head, "CapBand", Vector3.new(1.64, 0.2, 1.74), Vector3.new(0, 3.3, 0), BRASS, Enum.Material.Metal)
	add(head, "Cap", Vector3.new(1.6, 0.7, 1.7), Vector3.new(0, 3.75, 0), COAT_TRIM, Enum.Material.Fabric)

	-- arms that reach his knees, ending in long fingers
	for _, side in { -1, 1 } do
		local arm = limb(if side < 0 then "ArmL" else "ArmR", "Chest", Vector3.new(side * 1.95, 9.0, 0))
		add(arm, "Upper", Vector3.new(0.38, 3.2, 0.38), Vector3.new(0, -1.6, 0), COAT, Enum.Material.Fabric)
		add(arm, "Fore", Vector3.new(0.34, 3, 0.34), Vector3.new(0, -4.7, 0), COAT, Enum.Material.Fabric)
		add(arm, "Hand", Vector3.new(0.7, 0.9, 0.7), Vector3.new(0, -6.65, 0), MASK, Enum.Material.SmoothPlastic)
		for f = -1, 1 do
			add(
				arm,
				"Finger",
				Vector3.new(0.12, 1.1, 0.12),
				Vector3.new(f * 0.22, -7.65, 0),
				MASK,
				Enum.Material.SmoothPlastic
			)
		end
	end

	local glow = Instance.new("PointLight")
	glow.Color = EYE
	glow.Range = 14
	glow.Brightness = 1.2
	glow.Parent = limbs.Head.pieces[1].part

	return { model = model, limbs = limbs, order = order }
end

-- Poses every limb. `moving` is 0..1 (how fast he is walking), `chasing` raises the arms and leans him in.
function NightManagerRig.pose(rig: Rig, root: CFrame, clock: number, moving: number, chasing: boolean)
	local phase = clock * (if chasing then 9 else 4.5)
	local swing = math.sin(phase) * moving
	local lean = if chasing then 0.3 else 0.1
	local armRaise = if chasing then 1.25 + math.sin(phase * 2) * 0.08 else 0.12 + swing * 0.1
	local rotations: { [string]: CFrame } = {
		Hips = CFrame.Angles(0, 0, math.sin(phase) * 0.03 * moving),
		LegL = CFrame.Angles(swing * 0.6, 0, 0),
		LegR = CFrame.Angles(-swing * 0.6, 0, 0),
		Chest = CFrame.Angles(-lean, math.sin(phase * 0.5) * 0.08 * moving, 0),
		Head = CFrame.Angles(math.sin(clock * 0.7) * 0.06 - 0.22, 0, math.sin(clock * 1.3) * 0.12),
		ArmL = CFrame.Angles(armRaise, 0, 0.05),
		ArmR = CFrame.Angles(armRaise, 0, -0.05),
	}
	local frames: { [string]: CFrame } = {}
	for _, name in rig.order do
		local l = rig.limbs[name]
		local parent = if l.parent then rig.limbs[l.parent] else nil
		local base = if parent and l.parent then frames[l.parent] * parent.pivot:Inverse() * l.pivot else root * l.pivot
		local frame = base * (rotations[name] or CFrame.identity)
		frames[name] = frame
		for _, piece in l.pieces do
			piece.part.CFrame = frame * piece.offset
		end
	end
end

return NightManagerRig
