
local txd = TXDIO()
txd:load("infernus.txd")


local dff = DFFIO()
local tick = getTickCount()
dff:load("timetrain.dff")
print(getTickCount()-tick)
local tick = getTickCount()
dff:save("t.dff")
print(getTickCount()-tick)
