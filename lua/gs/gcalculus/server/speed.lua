local ENTITY = FindMetaTable("Entity")
util.AddNetworkString( "GS-GCompute-Speed" )

local function AddPos( ent, interval, iterations )
	if ( not ent:IsValid() ) then
		-- Entity went invalid before we could finish, abandon it
		return
	end
	
	ent.gs_PosTable[ ent.gs_iSpeedIterations ] = { Pos = ent:GetPos(), Vel = ent:GetVelocity() }
	ent.gs_iSpeedIterations = ent.gs_iSpeedIterations + 1
	
	if ( ent.gs_iSpeedIterations > iterations ) then
		ent:FinishSpeedCalc()
	else
		timer.Simple( interval, function()
			AddPos( ent, interval, iterations ) -- Pretty sure this could cause a stack overflow
		end )
	end
end

function ENTITY:StartSpeedCalc( interval, iterations )
	interval = interval or 1
	
	self.gs_PosTable = { interval = interval }
	self.gs_iSpeedIterations = 1
	
	AddPos( self, interval, iterations )
end

function net.WriteDoubleVector( vec )
	net.WriteDouble( vec.x )
	net.WriteDouble( vec.y )
	net.WriteDouble( vec.z )
end

function player.GetGraphViewers()
	return player.GetAll()
end

function ENTITY:FinishSpeedCalc()
	net.Start( "GS-GCompute-Speed" )
		net.WriteFloat( self.gs_PosTable.interval )
		net.WriteUInt( #self.gs_PosTable, 8 )
		
		for i = 1, #self.gs_PosTable do
			net.WriteDoubleVector( self.gs_PosTable[i].Pos )
			net.WriteDoubleVector( self.gs_PosTable[i].Vel )
		end
	net.Send( player.GetGraphViewers() )
end
