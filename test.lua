--[[
local txd = TXDIO()
txd:load("infernus.txd")

local dff = DFFIO()
local tick = getTickCount()
dff:load("timetrain.dff")
print(getTickCount()-tick)
local tick = getTickCount()
dff:save("t.dff")
print(getTickCount()-tick)
]]
--[[
local col = COLIO()
col:load("peds.col")
col:save("a.col")
]]

--[[
local newBMP = BMP()
newBMP:load("test.bmp")
for i=60,1,-2 do
	newBMP.pixels:addColumn(i)
	newBMP.pixels:addRow(i)
end
newBMP:save("a.bmp")]]

local dff = DFFIO()
dff:new()
dff:save("test.dff")

--[[
local IMG = engineLoadIMGContainer("gta3.img")
local dffFile = IMG:getFile("mlamppost.dff")
local dff = DFFIO()
dff:load(dffFile)
dff.clump.geometryList.geometries[1].extension.effect2D.effects[1].color={255,255,255,255}
dff.clump.geometryList.geometries[1].extension.effect2D.effects[1].coronaShowMode=10
local theDFF = engineLoadDFF(dff:save())
engineReplaceModel(theDFF,1294)]]