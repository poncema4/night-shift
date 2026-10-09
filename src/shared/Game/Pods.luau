--!strict
-- The lobby's queue pods (the "step onto a pad" mechanic big lobby games use): each pod is a round pad that fits one party
-- size. Standing on a pad puts you in that pod's party, stepping off takes you out. Pure layout + hit test.

export type Pod = { id: number, label: string, size: number, x: number, z: number, radius: number }

local Pods = {}

Pods.RADIUS = 4

-- Six pods in a row along the back of the lobby: solo up to a full eight.
local SIZES: { { label: string, size: number } } = {
	{ label = "SOLO", size = 1 },
	{ label = "DUO", size = 2 },
	{ label = "TRIO", size = 3 },
	{ label = "SQUAD", size = 4 },
	{ label = "SIX", size = 6 },
	{ label = "FULL HOUSE", size = 8 },
}

function Pods.layout(centerX: number, z: number, spacing: number): { Pod }
	local list: { Pod } = {}
	local count = #SIZES
	for i, entry in SIZES do
		table.insert(list, {
			id = i,
			label = entry.label,
			size = entry.size,
			x = centerX + (i - (count + 1) / 2) * spacing,
			z = z,
			radius = Pods.RADIUS,
		})
	end
	return list
end

-- Which pod (if any) the point is standing in.
function Pods.at(pods: { Pod }, x: number, z: number): Pod?
	for _, pod in pods do
		if (x - pod.x) ^ 2 + (z - pod.z) ^ 2 <= pod.radius ^ 2 then
			return pod
		end
	end
	return nil
end

-- "2/4  need 2 more" / "full" / "empty": the line shown on a pod's sign and on the party screen.
function Pods.status(count: number, size: number): string
	if count >= size then
		return `{count}/{size}  full`
	end
	return `{count}/{size}  need {size - count} more`
end

return Pods
