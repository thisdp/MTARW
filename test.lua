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

local tick = getTickCount()
local IMG = engineLoadIMGContainer("gta3.img")
print("Load IMG",getTickCount()-tick)
local tick = getTickCount()
local dffFile = IMG:getFile("mlamppost.dff")
print("Get DFF",getTickCount()-tick)
local dff = DFFIO()
local tick = getTickCount()
dff:load(dffFile)
dff.clump.geometryList.geometries[1].extension.effect2D.effects[1].color={0,0,255,255}
local theDFF = engineLoadDFF(dff:save())
engineReplaceModel(theDFF,1294)
print("Load DFF",getTickCount()-tick)

