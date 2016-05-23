local _R = debug.getregistry()
util.AddNetworkString( "GS-GCompute-Speed" )

local function AddPos( ent, flInterval, iMaxIterations, PosTable, VelTable )
	if ( not ent:IsValid() ) then
		-- Entity went invalid before we could finish, abandon it
		return
	end
	
	-- Add position and engine velocity
	local iTblLength = #PosTable + 1
	PosTable[ iTblLength ] = ent:GetPos()
	VelTable[ iTblLength ] = ent:GetVelocity()
	
	-- We're done; send it to the client
	if ( iTblLength == iMaxIterations ) then
		-- Send our data to the client to draw the graphs
		net.Start( "GS-GCompute-Speed" )
			net.WriteFloat( flInterval ) -- For the horizontal axis
			net.WriteUInt( iMaxIterations, 8 ) -- How many points do we have? (Max 256)
			
			for i = 1, iMaxIterations do
				net.WriteDoubleVector( PosTable[i] )
				net.WriteDoubleVector( VelTable[i] )
			end
		net.Send( player.GetGraphViewers() )
	else
		-- Wait for the next point
		timer.Simple( interval, function()
			if ( ent:IsValid() ) then
				AddPos( ent, flInterval, iMaxIterations, PosTable, VelTable )
			end
		end )
	end
end

function _R.Entity:SetupPositionTracker( interval, iterations )
	AddPos( self, interval or 1, iterations or 10, {}, {} )
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
