/*
function ENTITY:FinishSpeedCalc()
	net.Start( "GS-GCompute-Speed" )
		net.WriteFloat( self.gs_PosTable.interval )
		net.WriteByte( self.gs_iSpeedIterations )
		
		for i = 1, #self.gs_PosTable do
			net.WriteDoubleVector( self.gs_PosTable.Pos )
			net.WriteDoubleVector( self.gs_PosTable.Vec )
		end
	net.Send( player.GetGraphViewers() )
end

*/

GCALC_PosTable = {}
local interval
local iterations

net.Receive("GS-GCompute-Speed", function(len)
	GCALC_PosTable = {}
	print(len, tostring((len / 64000) * 100) .. "%")

	interval = net.ReadFloat()
	iterations = net.ReadUInt(8)

	GCALC_PosTable.Iterations = iterations
	GCALC_PosTable.Interval = interval

	for i = 1, iterations do
		GCALC_PosTable[i] = {
			Time = (i - 1) * interval,
			Pos = Vector(net.ReadDouble(), net.ReadDouble(), net.ReadDouble()),
			Vel = Vector(net.ReadDouble(), net.ReadDouble(), net.ReadDouble())
		}
	end

	PrintTable(GCALC_PosTable)
end)