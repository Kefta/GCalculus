local gcalcRender = false
local time = 0

surface.CreateFont("graphLabel", {font="roboto", size=23, weight=500, antialias=true})
surface.CreateFont("graphVariable", {font="roboto", size=20, weight=500, antialias=true})
surface.CreateFont("graphSmall", {font="roboto", size=15, weight=500, antialias=true})

local function drawGraphPrototype(x, y, w, h, name, ind, dep1, dep2, max, unit)
	surface.SetFont("graphLabel")
	surface.SetTextColor(200, 200, 200)

	surface.SetDrawColor(200, 200, 200, 100)
	surface.DrawRect(x + 15, y + (h * 0.5) - 1, w - 30, 2)
	surface.DrawRect(x + 14, y + h * 0.1, 2, h * 0.8)

	local tw, th = surface.GetTextSize(name)
	surface.SetTextPos(x + (w - tw) * 0.5, y + 5)
	surface.DrawText(name)

	tw, th = surface.GetTextSize(dep1)
	surface.SetTextPos(x + (w - tw) * 0.5, y + 25)
	surface.SetTextColor(255, 50, 50)
	surface.DrawText(dep1)
	if (dep2) then
		tw, th = surface.GetTextSize(dep2)
		surface.SetTextPos(x + (w - tw) * 0.5, y + 45)
		surface.SetTextColor(50, 255, 50)
		surface.DrawText(dep2)
	end

	tw, th = surface.GetTextSize(ind)
	surface.SetTextPos(x + (w - tw) * 0.5, y + h - 28)
	surface.SetTextColor(200, 200, 200)
	surface.DrawText(ind)

	if (max) then
		surface.SetTextColor(200, 200, 200)
		surface.SetFont("graphSmall")
		surface.SetTextPos(x + 20, y + (h * 0.1))
		surface.DrawText(tostring(math.Round(max)) .. unit)
		surface.SetTextPos(x + 20, y + (h * 0.9) - 14)
		surface.DrawText(tostring(math.Round(-max)) .. unit)
	end
end

local function calculateAllValues(w, h)
	if (GCALC_PosTable.Velocities) then return end
	
	GCALC_PosTable.Velocities = {}
	GCALC_PosTable.Accelerations = {}
	GCALC_PosTable.Distances = {}

	local maxvel = 0
	local maxacc = 0
	local maxdist = 0
	local vec0 = Vector(0, 0, 0)
	for k, v in ipairs(GCALC_PosTable) do
		local vel = v.Vel.x
		local velComp = k == 1 and 0 or ((v.Pos.x - GCALC_PosTable[k-1].Pos.x) / GCALC_PosTable.Interval)
		local acc = (k == 1 and 0 or (v.Vel.x - GCALC_PosTable[k-1].Vel.x))
		local accComp = (k == 1 and 0 or ((v.Pos.x - GCALC_PosTable[k-1].Pos.x) / GCALC_PosTable.Interval) - GCALC_PosTable.Velocities[k-1].Computed)
		local dist = (k == 1 and 0 or v.Pos.x - GCALC_PosTable[1 ].Pos.x)

		if (math.abs(vel) > maxvel) then
			maxvel = math.abs(vel)
		end
		if (math.abs(acc) > maxacc) then
			maxacc = math.abs(acc)
		end
		if (math.abs(velComp) > maxvel) then
			maxvel = math.abs(velComp)
		end
		if (math.abs(accComp) > maxacc) then
			maxacc = math.abs(accComp)
		end
		if (math.abs(dist) > maxdist) then
			maxdist = math.abs(dist)
		end

		GCALC_PosTable.Velocities[k] = {
			Actual = vel,
			Computed = velComp
		}

		GCALC_PosTable.Accelerations[k] = {
			Actual = acc,
			Computed = accComp
		}

		GCALC_PosTable.Distances[k] = dist
	end

	for k, v in ipairs(GCALC_PosTable) do
		local vel = GCALC_PosTable.Velocities[k]
		local acc = GCALC_PosTable.Accelerations[k]
		local dist = GCALC_PosTable.Distances[k]

		local mul = vel.Actual / maxvel
		GCALC_PosTable.Velocities[k].ay = mul * (h * 0.4)
		mul = vel.Computed / maxvel
		GCALC_PosTable.Velocities[k].cy = mul * (h * 0.4)

		mul = acc.Actual / maxacc
		GCALC_PosTable.Accelerations[k].ay = mul * (h * 0.4)
		mul = acc.Computed / maxacc
		GCALC_PosTable.Accelerations[k].cy = mul * (h * 0.4)

		mul = dist / maxdist
		GCALC_PosTable.Distances[k] = mul * (h * 0.4)
	end

	GCALC_PosTable.Velocities.Max = maxvel
	GCALC_PosTable.Accelerations.Max = maxacc
	GCALC_PosTable.Distances.Max = maxdist

	PrintTable(GCALC_PosTable.Distances)
end

hook.Add("HUDPaint", "", function()
	if (!gcalcRender) then time = 0 return end
	
	local w, h = ScrW(), ScrH()

	surface.SetDrawColor(50, 50, 50)
	surface.DrawRect(0, 0, w, h)

	w = w * 0.5
	h = h * 0.5

	if (time == 0) then
		if (!GCALC_PosTable.Iterations) then gcalcRender = false return end
		
		time = SysTime()
		calculateAllValues(w - 10, h - 83)
	end

	local diff = SysTime() - time
	local maxX = (diff / (GCALC_PosTable.Interval * GCALC_PosTable.Iterations)) * (w - 10)

	surface.SetDrawColor(0, 255, 0)
	surface.DrawRect(0, h, w, h)

	local secW = (w - 35) / GCALC_PosTable.Iterations

	drawGraphPrototype(0, 0, w, h, "Velocity", "Time", "Actual", "Computed", GCALC_PosTable.Velocities.Max, " units/S")
	drawGraphPrototype(w, 0, w, h, "Acceleration", "Time", "Actual", "Computed", GCALC_PosTable.Accelerations.Max, " units/S^2")
	drawGraphPrototype(w, h, w, h, "Distance from Origin", "Time", "Distance", nil, GCALC_PosTable.Distances.Max, " units")

	--G1
	--Velocity/Predicted Velocity
	render.SetScissorRect(0, 0, maxX, h, true)
	local y = h * 0.5
	for k, v in ipairs(GCALC_PosTable.Velocities) do
		if (k == 1) then continue end
		
		local x = (k - 2) * secW + 20 + secW * 0.5

		if (x > maxX) then break end

		surface.SetDrawColor(255, 50, 50)
		surface.DrawLine(x, y + GCALC_PosTable.Velocities[k-1].ay, x + secW, y + v.ay)
		surface.SetDrawColor(50, 255, 50)
		surface.DrawLine(x, y + GCALC_PosTable.Velocities[k-1].cy, x + secW, y + v.cy)
	end
	render.SetScissorRect(0, 0, maxX, h, false)

	--G2
	--Acceleration/Predicted Acceleration
	render.SetScissorRect(0, 0, maxX + w, h * 2, true)
	local y = h * 0.5
	for k, v in ipairs(GCALC_PosTable.Accelerations) do
		if (k == 1) then continue end
		
		local x = (k - 2) * secW + 20 + secW * 0.5

		if (x > maxX) then break end

		surface.SetDrawColor(255, 50, 50)
		surface.DrawLine(x + w, y + GCALC_PosTable.Accelerations[k-1].ay, x + secW + w, y + v.ay)
		surface.SetDrawColor(50, 255, 50)
		surface.DrawLine(x + w, y + GCALC_PosTable.Accelerations[k-1].cy, x + secW + w, y + v.cy)
	end

	--G3
	--Distance From Origin
	local y = h * 1.5
	for k, v in ipairs(GCALC_PosTable.Distances) do
		if (k == 1) then continue end
		
		local x = (k - 2) * secW + 20 + secW * 0.5

		if (x > maxX) then break end

		surface.SetDrawColor(255, 50, 50)
		surface.DrawLine(x + w, y + GCALC_PosTable.Distances[k-1], x + secW + w, y + v)
	end
	render.SetScissorRect(0, 0, maxX + w, h, false)

	surface.SetDrawColor(0, 0, 0)
	surface.DrawLine(0, h, w * 2, h)
	surface.DrawLine(w, 0, w, h * 2)
end)

hook.Add("HUDShouldDraw", "", function(e)
	if (e == "CHudHealth") then return false end
end)

concommand.Add("togglegcalc", function() gcalcRender = !gcalcRender end)