--!strict
-- The lobby's queue pods: square cells in a row. They are all the same: the FIRST player to step into an empty pod chooses
-- how many people the party is for (1 to 8) and the pod follows that choice. Anyone else can step in until it is full.
-- Pure layout and hit tests; the rules about who is queued live in Party and LobbyService.

export type Pod = { id: number, label: string, x: number, z: number, half: number }

local Pods = {}

Pods.HALF = 5 -- each cell is 10 x 10 studs
Pods.COUNT = 6

function Pods.layout(centerX: number, z: number, spacing: number): { Pod }
	local list: { Pod } = {}
	for i = 1, Pods.COUNT do
		table.insert(list, {
			id = i,
			label = `POD {i}`,
			-- the player faces +z toward the cells, so +x is on their LEFT: pod 1 sits at the largest x and the numbers
			-- read 1 to 6 from left to right
			x = centerX - (i - (Pods.COUNT + 1) / 2) * spacing,
			z = z,
			half = Pods.HALF,
		})
	end
	return list
end

-- Is the point inside this pod's square? `margin` widens it (used to tell "left the cell" from "stood at the edge").
function Pods.inside(pod: Pod, x: number, z: number, margin: number?): boolean
	local reach = pod.half + (margin or 0)
	return math.abs(x - pod.x) <= reach and math.abs(z - pod.z) <= reach
end

-- Which pod (if any) the point is standing in.
function Pods.at(pods: { Pod }, x: number, z: number): Pod?
	for _, pod in pods do
		if Pods.inside(pod, x, z) then
			return pod
		end
	end
	return nil
end

-- "2/4  need 2 more" / "4/4  full" : the line shown on a pod's sign and on the party screen.
function Pods.status(count: number, size: number): string
	if count >= size then
		return `{count}/{size}  full`
	end
	return `{count}/{size}  need {size - count} more`
end

return Pods
