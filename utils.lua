local tostring = tostring
local strRep = string.rep
local type = type
local pairs = pairs
local mathFrexp = math.frexp
local mathFloor = math.floor
local tableConcat = table.concat
local strChar = string.char
local mathHuge = math.huge

--Table Utils
function table.count(tabl)
	local cnt = 0
	for k,v in pairs(tabl) do
		cnt = cnt + 1
	end
	return cnt
end

function table.inspect(theTable,appendTable,depth,arrayMark)
	depth = depth or 0
	local appendTable = appendTable or {nil,nil,nil,nil}
	local theType = type(theTable)
	if theType == "table" then
		if #theTable == table.count(theTable) then	--Array
			for key,value in ipairs(theTable) do
				local valueType = type(value)
				if valueType ~= "function" and key ~= "parent" then
					if valueType == "table" then
						appendTable[#appendTable+1] = "\n"
						appendTable[#appendTable+1] = strRep("	",depth+1)
					end
					table.inspect(value,appendTable,depth+1,true)
				end
			end
		else
			appendTable[#appendTable+1] = "\n"
			for key,value in pairs(theTable) do
				if type(value) ~= "function" and key ~= "parent" then
					appendTable[#appendTable+1] = strRep("	",depth+1)
					appendTable[#appendTable+1] = "["
					appendTable[#appendTable+1] = tostring(key)
					appendTable[#appendTable+1] = "] = "
					table.inspect(value,appendTable,depth+1)
					appendTable[#appendTable+1] = "\n"
				end
			end
			appendTable[#appendTable+1] = strRep("	",depth)
		end
	else
		appendTable[#appendTable+1] = tostring(theTable)
		if arrayMark then
			appendTable[#appendTable+1] = ","
		end
	end
	return tableConcat(appendTable)
end


function table.inspectToFile(file,theTable,appendTable,depth,arrayMark)
	depth = depth or 0
	local theType = type(theTable)
	if theType == "table" then
		if #theTable == table.count(theTable) then	--Array
			for key,value in ipairs(theTable) do
				local valueType = type(value)
				if valueType ~= "function" and key ~= "parent" then
					if valueType == "table" then
						fileWrite(file,"\n",strRep("	",depth+1))
					end
					table.inspectToFile(file,value,appendTable,depth+1,true)
				end
			end
		else
			fileWrite(file,"\n")
			for key,value in pairs(theTable) do
				if type(value) ~= "function" and key ~= "parent"  then
					fileWrite(file,strRep("	",depth+1),"[",tostring(key),"] = ")
					table.inspectToFile(file,value,appendTable,depth+1)
					fileWrite(file,"\n")
				end
			end
			fileWrite(file,strRep("	",depth))
		end
	else
		fileWrite(file,tostring(theTable))
		if arrayMark then
			fileWrite(file,",")
		end
	end
end

function table.deepcopy(obj)
    local InTable = {}
    local function Func(obj)
        if type(obj) ~= "table" then
            return obj
        end
        local NewTable = {}
        InTable[obj] = NewTable
        for k,v in pairs(obj) do
            NewTable[Func(k)] = Func(v)
        end
        return setmetatable(NewTable,getmetatable(obj))
    end
    return Func(obj)
end

function table.find(tab,item)
	for key,value in pairs(tab) do
		if value == item then return key end
	end
end

--Math Utils
local Rad2Deg = 57.29577951308238
local Deg2Rad = 0.0174532925199433
local cos,sin,atan2 = math.cos,math.sin,math.atan2
function mul(m1,m2)
	local m11,m12,m13,m21,m22,m23,m31,m32,m33
	m11,m12,m13 = m1[1][1]*m2[1][1]+m1[1][2]*m2[2][1]+m1[1][3]*m2[3][1],m1[1][1]*m2[1][2]+m1[1][2]*m2[2][2]+m1[1][3]*m2[3][2],m1[1][1]*m2[1][3]+m1[1][2]*m2[2][3]+m1[1][3]*m2[3][3]
	m21,m22,m23 = m1[1][1]*m2[1][1]+m1[1][2]*m2[2][1]+m1[1][3]*m2[3][1],m1[1][1]*m2[1][2]+m1[1][2]*m2[2][2]+m1[1][3]*m2[3][2],m1[1][1]*m2[1][3]+m1[1][2]*m2[2][3]+m1[1][3]*m2[3][3]
	m31,m32,m33 = m1[3][1]*m2[1][1]+m1[3][2]*m2[2][1]+m1[3][3]*m2[3][1],m1[3][1]*m2[1][2]+m1[3][2]*m2[2][2]+m1[3][3]*m2[3][2],m1[3][1]*m2[1][3]+m1[3][2]*m2[2][3]+m1[3][3]*m2[3][3]
	m1[1][1],m1[1][2],m1[1][3] = m11,m12,m13
	m1[2][1],m1[2][2],m1[2][3] = m21,m22,m23
	m1[3][1],m1[3][2],m1[3][3] = m31,m32,m33
	return m1
end

eulerToRotationMatrix = function(rx,ry,rz)
	local rx,ry,rz = rx*Deg2Rad,ry*Deg2Rad,rz*Deg2Rad
	local cX,sX = cos(rx),sin(rx)
	local cY,sY = cos(ry),sin(ry)
	local cZ,sZ = cos(rz),sin(rz)
	local matrixRX = {
		{1,0,0},
		{0,cX,-sX},
		{0,sX,cX},
	}
    local matrixRY = {
		{cY,0,sY},
		{0,1,0},
		{-sY,0,cY},
	}
	local matrixRZ = {
		{cZ,-sZ,0},
		{sZ,cZ,0},
		{0,0,1},
	}
	rotMatrix = mul(mul(matrixRZ,matrixRY),matrixRX)
	return rotMatrix
end

rotationMatrixToEuler = function(rotMatrix)
    local cY = (rotMatrix[1][1]*rotMatrix[1][1] + rotMatrix[2][1]*rotMatrix[2][1])^0.5
    if cY >= 1e-6 then
        x = atan2( rotMatrix[3][2], rotMatrix[3][3])
        y = atan2(-rotMatrix[3][1], cY)
        z = atan2( rotMatrix[2][1], rotMatrix[1][1])
    else
        x = atan2(-rotMatrix[2][3], rotMatrix[2][2])
        y = atan2(-rotMatrix[3][1], cY)
        z = 0
	end
	return x*Rad2Deg,y*Rad2Deg,z*Rad2Deg
end

--Binary Utils
local function Hex2Float(c)
	if c == 0 then return 0.0 end
	local b1,b2,b3,b4 = 0,0,0,0
	b1 = c/0x1000000
	b1 = b1-b1%1
	c = c - b1*0x1000000
	b2 = c/0x10000
	b2 = b2-b2%1
	c = c - b2*0x10000
	b3 = c/0x100
	b3 = b3-b3%1
	c = c - b3*0x100
	b4 = c
	b4 = b4-b4%1
	local sign,temp = (b1>0x7F) and -1 or 1,b2/0x80
	local expo = b1%0x80*0x2+temp-temp%1
	local mant = (b2%0x80*0x100+b3)*0x100+b4
	local n
	if mant == 0 and expo == 0 then
		n = sign * 0.0
	elseif expo == 0xFF then
		if mant == 0 then
			n = sign * mathHuge
		else
			n = 0.0/0.0
		end
	else
		n = sign*(1.0+mant/0x800000)*2^(expo-0x7F)
	end
	return n
end

local function Float2Hex(n)
	if n == 0 then return 0 end
	local sign = 0
	if n < 0 then
		sign = 0x80
		n = -n
	end
	local mant,expo = mathFrexp(n)
	local hext1,hext2,hext3,hext4
	if mant ~= mant then
		return 0xFF880000
	elseif mant == mathHuge or expo > 0x80 then
		hext1 = sign == 0 and 0x7F or 0xFF
		return 0x880000+hext1*0x1000000
	elseif (mant == 0.0 and expo == 0) or expo < -0x7E then
		return sign*0x1000000
	else
		expo = expo + 0x7E
		mant = (mant*2.0-1.0)*0x800000
		local temp1 = expo/0x2
		local temp2 = mant/0x10000
		local temp3 = mant/0x100
		hext1 = sign + temp1-temp1%1
		hext2 = expo%0x2*0x80+temp2-temp2%1
		hext3 = (temp3-temp3%1)%0x100
		hext4 = mant%0x100
		local hexValue = hext1*0x1000000+hext2*0x10000+hext3*0x100+hext4
		return hexValue-hexValue%1
	end
end

function bAssemble(...)
	local size = select("#",...)
	local result = 0
	for i=1,size do
		result = result+((select(i,...) and 1 or 0)*2^(i-1))
	end
	return result
end

function bExtract(num,pos,length)
	local v = num%(2^(pos+(length or 1)))/(2^pos)
	return v-v%1
end

function bReplace(num,bit,pos)
	local v = num%(2^(pos+1))/(2^pos)
	local p = (v-v%1)
	local v = (((p == 1) or (bit == 1)) == true) and 1 or 0
	num = num-p*(2^pos)+v*(2^pos)
	return num
end

local charNumTable = {}
for i=0,255 do
	local c = strChar(i)
	charNumTable[i] = c
	charNumTable[c] = i
end

uint32 = {type="number",name="uint32","unsigned",4}
uint24 = {type="number",name="uint24","unsigned",3}
uint16 = {type="number",name="uint16","unsigned",2}
uint8 = {type="number",name="uint8","unsigned",1}
int32 = {type="number",name="int32","signed",4}
int24 = {type="number",name="int24","signed",3}
int16 = {type="number",name="int16","signed",2}
int8 = {type="number",name="int8","signed",1}
float = {type="number",name="float","float",4}
char = {type="string",name="char","char",-1}
bytes = {type="bytes",name="bytes","bytes",-1}


local numberWriter = {}
function writeNumber(number,numberType)
	if not number then
		local db = debug.getinfo(3)
		error(db.source..":"..db.currentline..": Bad argument @writeNumber at argument 1, expected a number got "..type(number))
	end
	local len = numberType[2]
	if numberType[1] == "float" then
		number = Float2Hex(number)
	else
		if number < 0 then number = number+0x100^len end
	end
	for i=1,len do
		local byte = number%0x100
		byte = byte-byte%1
		numberWriter[i] = charNumTable[byte]
		number = (number-byte)/0x100
	end
	return tableConcat(numberWriter,_,_,len),len
end

local readNumberList = {}
local function readNumber(data,numberType,offset)
	local len = numberType[2]
	local numberTag = numberType[1]
	local num1,num2,num3,num4 = data:byte(offset,offset+len-1)
	readNumberList[1] = num1
	readNumberList[2] = num2
	readNumberList[3] = num3
	readNumberList[4] = num4
	local num = 0
	for i=1,len do
		num = num+readNumberList[i]*0x100^(i-1)
	end
	if numberTag == "signed" then
		local s = num/0x100^(len-1)
		if s > 0x7F then num = num-0x100^len end
	elseif numberTag == "float" then
		num = Hex2Float(num)
	end
	return num
end

local function writeString(str,length)
	length = length or (#str+1)
	local data = str:sub(1,length)..strRep("\0",length-#str)
	return data,#data
end

local function readString(data,length,offset)
	local str = data:sub(offset,offset+length-1)
	local strEnd = str:find("\0") or length
	str = str:sub(1,strEnd):gsub("%z","")
	return str
end

local function writeBytes(str,length)
	local bytes = str:sub(1,length)..strRep("\0",length-#str)
	return bytes,#bytes
end

local function readBytes(data,length,offset)
	local str = data:sub(offset,offset+length-1)
	return str
end

class "ReadStream" {
	cachedStr = "",
	cachedPos = 1,
	length = 0,
	readingPos = 1,
	constructor = function(self,streamString)
		self.cachedStr = streamString
		self.length = #streamString
	end,
	read = function(self,dataType,additionLen)
		local length,result
		local dType = dataType.type
		local readingPos = self.readingPos
		if dType == "string" then
			result = readString(self.cachedStr,additionLen or (self.length-readingPos),readingPos)
			length = additionLen
		elseif dType == "bytes" then
			result = readBytes(self.cachedStr,additionLen or (self.length-readingPos),readingPos)
			length = additionLen
		elseif dType == "number" then
			result = readNumber(self.cachedStr,dataType,readingPos)
			length = dataType[2]
		end
		self.readingPos = readingPos+length
		return result
	end,
}

class "WriteStream" {
	constructor = function(self)
		self.buffer = {}
		self.writingPos = 1
	end,
	write = function(self,data,dataType,additionLen)
		local dType = dataType.type
		local buffer = self.buffer
		local bufferPos = #buffer+1
		local addOffset = 0
		if dType == "string" then
			buffer[bufferPos],addOffset = writeString(data,additionLen or #data)
		elseif dType == "bytes" then
			buffer[bufferPos],addOffset = writeBytes(data,additionLen or #data)
		elseif dType == "number" then
			buffer[bufferPos],addOffset = writeNumber(data,dataType)
		end
		self.writingPos = self.writingPos+addOffset
		return bufferPos
	end,
	overwrite = function(self,bufferPos,data,dataType,additionLen)
		local dType = dataType.type
		local buffer = self.buffer
		if dType == "string" then
			buffer[bufferPos] = writeString(data,additionLen or #data)
		elseif dType == "bytes" then
			buffer[bufferPos] = writeBytes(data,additionLen or #data)
		elseif dType == "number" then
			buffer[bufferPos] = writeNumber(data,dataType)
		end
		return bufferPos
	end,
	getSize = function(self)
		local size = 0
		for i=1,#self.buffer do
			size = size+#self.buffer[i]
		end
		return size
	end,
	save = function(self)
		return tableConcat(self.buffer)
	end
}

EnumCoreID = {
	NAOBJECT      = 0x00,
	STRUCT        = 0x01,
	STRING        = 0x02,
	EXTENSION     = 0x03,
	CAMERA        = 0x05,
	TEXTURE       = 0x06,
	MATERIAL      = 0x07,
	MATLIST       = 0x08,
	WORLD         = 0x0B,
	MATRIX        = 0x0D,
	FRAMELIST     = 0x0E,
	GEOMETRY      = 0x0F,
	CLUMP         = 0x10,
	LIGHT         = 0x12,
	ATOMIC        = 0x14,
	TEXTURENATIVE = 0x15,
	TEXDICTIONARY = 0x16,
	IMAGE         = 0x18,
	GEOMETRYLIST  = 0x1A,
	ANIMANIMATION = 0x1B,
	RIGHTTORENDER = 0x1F,
	UVANIMDICT    = 0x2B,
}

EnumPlatform = {
	PLATFORM_NULL = 0,
	PLATFORM_GL   = 2,
	PLATFORM_PS2  = 4,
	PLATFORM_XBOX = 5,
	PLATFORM_D3D8 = 8,
	PLATFORM_D3D9 = 9,
	PLATFORM_WDGL = 11,
	PLATFORM_GL3  = 12,
	NUM_PLATFORMS = 13,
	FOURCC_PS2 = 0x00325350,
}

function getRWVersion(ver)
	
end