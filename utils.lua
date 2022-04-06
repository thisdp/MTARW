local tostring = tostring
local strRep = string.rep
local type = type
local pairs = pairs
local mathFrexp = math.frexp
local mathFloor = math.floor

function table.count(tabl)
	local cnt = 0
	for k,v in pairs(tabl) do
		cnt = cnt + 1
	end
	return cnt
end

function table.inspect(theTable,appendTable,depth,arrayMark)
	depth = depth or 0
	local appendTable = appendTable or {}
	local theType = type(theTable)
	if theType == "table" then
		if #theTable == table.count(theTable) then	--Array
			for key,value in ipairs(theTable) do
				if type(value) ~= "function" then
					if type(value) == "table" then
						appendTable[#appendTable+1] = "\n"
						appendTable[#appendTable+1] = strRep("	",depth+1)
					end
					table.inspect(value,appendTable,depth+1,true)
				end
			end
		else
			appendTable[#appendTable+1] = "\n"
			for key,value in pairs(theTable) do
				if type(value) ~= "function" then
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
	return table.concat(appendTable)
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

function bExtract(num,pos,length)
	local v = num%(2^(pos+(length or 1)))/(2^pos)
	return v-v%1
end

charNumTable = {}
for i=0,255 do
	local c = string.char(i)
	charNumTable[i] = c
	charNumTable[c] = i
end

uint32 = {type="number",name="uint32","unsigned",4}
uint16 = {type="number",name="uint16","unsigned",2}
uint8 = {type="number",name="uint8","unsigned",1}
int32 = {type="number",name="int32","signed",4}
int16 = {type="number",name="int16","signed",2}
int8 = {type="number",name="int8","signed",1}
float = {type="number",name="float","float",4}
char = {type="string",name="char","char",-1}
bytes = {type="bytes",name="bytes","bytes",-1}

function writeNumber(number,numberType)
	local len = numberType[2]
	if numberType[1] == "float" then
		number = Float2Hex(number)
	else
		if number < 0 then number = number+0x100^len end
	end
	local str = {}
	for i=1,len do
		local byte = number%0x100
		byte = byte-byte%1
		str[i] = string.char(byte)
		number = (number-byte)/0x100
	end
	return table.concat(str,"")
end

function readNumber(data,numberType,offset,maybeResult)
	local len = numberType[2]
	local strNum = data:sub(offset,offset+len-1)
	local num = 0
	if len ~= #strNum then iprint(debug.getinfo(3)) end
	for i=1,len do num = num+strNum:sub(i,i):byte()*0x100^(i-1) end
	if numberType[1] == "signed" then
		local s = num/0x100^(len-1)
		if s > 0x7F then num = num-0x100^len end
	elseif numberType[1] == "float" then
		num = Hex2Float(num)
	end
	if maybeResult then maybeResult[1] = num return end
	return num
end

function writeString(str,length)
	length = length or (#str+1)
	local data = str:sub(1,length)..string.rep("\0",length-#str)
	return data
end

function readString(data,length,offset,maybeResult)
	local str = data:sub(offset,offset+length-1)
	local strEnd = str:find("\0") or length
	str = str:sub(1,strEnd):gsub("%z","")
	if maybeResult then maybeResult[1] = str return end
	return str
end

function writeBytes(str,length)
	return str:sub(1,length)..string.rep("\0",length-#str)
end

function readBytes(data,length,offset,maybeResult)
	local str = data:sub(offset,offset+length-1)
	if maybeResult then maybeResult[1] = str return end
	return str
end

function splitToBit(uint8Num)
	local bits = {}
	for i=1,8 do
		bits[i] = bitExtract(uint8Num,i-1)
	end
	return bits
end

function Hex2Float(c)
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
	local sign,temp = b1 > 0x7F, b2 / 0x80
	local expo = b1 % 0x80 * 0x2 + temp-temp%1
	local mant = (b2 % 0x80 * 0x100 + b3) * 0x100 + b4
	if sign then
		sign = -1
	else
		sign = 1
	end
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

function Float2Hex(n)
	if n == 0 then return 0 end
	local sign = 0
	if n < 0 then
		sign = 0x80
		n = -n
	end
	local mant, expo = mathFrexp(n)
	local hext1,hext2,hext3,hext4
	if mant ~= mant then
		hext1 = 0xFF
		hext2 = 0x88
		hext3 = 0x00
		hext4 = 0x00
	elseif mant == mathHuge or expo > 0x80 then
		hext2 = 0x80
		hext3 = 0x00
		hext4 = 0x00
		if sign == 0 then
			hext1 = 0x7F
		else
			hext1 = 0xFF
		end
	elseif (mant == 0.0 and expo == 0) or expo < -0x7E then
		hext1 = sign
		hext2 = 0x00
		hext3 = 0x00
		hext4 = 0x00
	else
		expo = expo + 0x7E
		mant = (mant*2.0-1.0)*0x800000
		local temp1 = expo/0x2
		temp1=temp1-temp1%1
		local temp2 = mant/0x10000
		temp2=temp2-temp2%1
		local temp3 = mant/0x100
		temp3=temp3-temp3%1
		hext1 = sign + temp1
		hext2 = expo%0x2*0x80+temp2
		hext3 = temp3%0x100
		hext4 = mant%0x100
	end
	return mathFloor(hext1*0x1000000+hext2*0x10000+hext3*0x100+hext4)
end

function struct(name)
	return function(structure)
		setmetatable(structure,{
			__call = function(self,...)
				local instance = table.deepcopy(structure)
				if structure[name] then
					structure[name](instance,...)
				end
				return instance
			end,
		})
		_G[name] = structure
	end
end
--[[
struct "Struct" {
	headSection = false,
	unpackRead = function(self,readStream) end,
	packWrite = function(self,writeStream) end,
	unpack = function(self,readStream)
		self.headSection = ChunkHeaderInfo()
		self.headSection:unpack(readStream)
		if self.headSection.type ~= 0x01 then print("Bad struct at @Struct, expected Struct(0x01), got "..self.headSection.type) end
		self:unpackRead(readStream)
	end,
	pack = function(self,writeStream)
		self.headSection:pack(writeStream)
		self:packWrite(writeStream)
	end,
	_getSize = function(self)
		return self.headSection:getSize()
	end
}]]

struct "ChunkHeaderInfo" {
	type = false, --uint32
	size = false, --uint32
	version = false, --uint32
	unpack = function(self,readStream)
		self.type = readStream:read(uint32)
		self.size = readStream:read(uint32)
		self.version = readStream:read(uint32)
	end,
	pack = function(self,writeStream)
		writeStream:write(self.type,uint32)
		writeStream:write(self.size,uint32)
		writeStream:write(self.version,uint32)
	end,
	getSize = function(self)
		return 12
	end,
}
--[[
struct "Extension" {
	headSection = false,
	unpackRead = function(self,readStream) end,
	packWrite = function(self,writeStream) end,
	unpack = function(self,readStream)
		self.headSection = ChunkHeaderInfo()
		self.headSection:unpack(readStream)
		if self.headSection.type ~= 0x03 then
			local db = debug.getinfo(2)
			print(db.source..":"..db.currentline..": Bad type at @Extension, expected Extension(0x03), got "..self.headSection.type)
		end
		self:unpackRead(readStream)
	end,
	pack = function(self,writeStream)
		self.headSection:pack(writeStream)
		self:packWrite(writeStream)
	end,
	_getSize = function(self)
		return self.headSection:getSize()
	end,
	getSize = function(self)
		return self:_getSize()
	end,
}]]

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
		local length
		local result
		if dataType.type == "string" then
			result = readString(self.cachedStr,additionLen or (self.length-self.readingPos),self.readingPos)
			length = additionLen
		elseif dataType.type == "bytes" then
			result = readBytes(self.cachedStr,additionLen or (self.length-self.readingPos),self.readingPos)
			length = additionLen
		elseif dataType.type == "number" then
			result = readNumber(self.cachedStr,dataType,self.readingPos)
			length = dataType[2]
		end
		self.readingPos = self.readingPos+length
		return result
	end,
}

class "WriteStream" {
	buffer = {},
	write = function(self,data,dataType,additionLen)
		if dataType.type == "string" then
			self.buffer[#self.buffer+1] = writeString(data,additionLen or #data)
		elseif dataType.type == "bytes" then
			self.buffer[#self.buffer+1] = writeBytes(data,additionLen or #data)
		elseif dataType.type == "number" then
			self.buffer[#self.buffer+1] = writeNumber(data,dataType)
		end
	end,
	save = function(self)
		return table.concat(self.buffer,"")
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