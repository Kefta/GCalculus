local _R = debug.getregistry()
util.AddNetworkString( "GS-GCompute-Speed" )

local function AddPos( ent, interval, iterations )
	if ( not ent:IsValid() ) then
		-- Entity went invalid before we could finish, abandon it
		return
	end
	
	-- Add position and engine velocity
	ent.gs_PosTable[ ent.gs_iSpeedIterations ] = { Pos = ent:GetPos(), Vel = ent:GetVelocity() }
	
	-- We're done; send it to the client
	if ( ent.gs_iSpeedIterations == iterations ) then
		FinishCalc( ent )
	else
		ent.gs_iSpeedIterations = ent.gs_iSpeedIterations + 1
		
		-- Wait for the next point
		timer.Simple( interval, function()
			AddPos( ent, interval, iterations )
		end )
	end
end

function _R.Entity:SetupPositionTracker( interval, iterations )
	interval = interval or 1 -- Default 1 second
	
	self.gs_PosTable = { interval = interval }
	self.gs_iSpeedIterations = 1
	
	AddPos( self, interval, iterations or 10 ) -- Default 10 points
end

-- More precise than WriteVector, which uses floats
function net.WriteDoubleVector( vec )
	net.WriteDouble( vec.x )
	net.WriteDouble( vec.y )
	net.WriteDouble( vec.z )
end

-- Everyone gets the data packs by default
function player.GetGraphViewers()
	return player.GetAll()
end

local function FinishCalc( ent )
	-- Send our data to the client to draw the graphs
	net.Start( "GS-GCompute-Speed" )
		net.WriteFloat( ent.gs_PosTable.interval ) -- For the horizontal axis
		net.WriteUInt( ent.gs_iSpeedIterations, 8 ) -- How many points do we have?
		
		for i = 1, ent.gs_iSpeedIterations do
			net.WriteDoubleVector( ent.gs_PosTable[i].Pos )
			net.WriteDoubleVector( ent.gs_PosTable[i].Vel )
		end
	net.Send( player.GetGraphViewers() )
end
