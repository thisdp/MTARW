--[[
local newBMP = BMP()
newBMP:load("test.bmp")
newBMP.pixels:resize(newBMP.pixels.width*2,newBMP.pixels.height*2,"pixel")
newBMP:save("a.bmp")]]
--[[
dff = DFFIO()
dff:createClump()
dff.clump:addComponent()
]]

--local theTXD = engineLoadTXD("hillrace.txd")
--engineImportTXD(theTXD,3458)
--[[
local IMG = engineLoadIMGContainer("gta3.img")
local dffFile = IMG:getFile("mlamppost.dff")
local dff = DFFIO()
dff:load(dffFile)
dff.clump.geometryList.geometries[1].extension.effect2D.effects[1].color={255,255,255,255}
dff.clump.geometryList.geometries[1].extension.effect2D.effects[1].coronaShowMode=10
local theDFF = engineLoadDFF(dff:save())
engineReplaceModel(theDFF,1294)]]

------------------------TXD
--[[
--Simple TXD Load
local txd = TXDIO()
txd:load("infernus.txd")
]]

------------------------DFF
--[[
--Simple DFF Load/Save
local dff = DFFIO()
dff:load("object.dff")
dff:save("test.dff")
]]

--[[
--Simple Object Conversion from GTAVC to GTASA
local dff = DFFIO()
dff:load("object.dff")
dff:convert("GTASA")
if localPlayer then	--Clientsided
	local theDFF = engineLoadDFF(dff:save())
	engineReplaceModel(theDFF,3458)
end
]]


-----------------------Collisions
--[[
--Simple Collision Load/Save
local col = COLIO()
col:load("object.col")
col:save("test.col")
]]

--[[
--Collision Generation
local dff = DFFIO()
dff:load("object.dff")
local col = COLIO()
col:generateFromGeometry("COLL",dff.clumps[1].geometryList.geometries[1],{
	textureA = 26,	--find material ID by texture name, and convert to col material
	[{255,255,255}] = 1,	--find material ID by color, and convert to col material
})
col:save("test.col")
]]