--classlib.lua
local getmetatable,setmetatable = getmetatable,setmetatable
local tonumber,tostring = tonumber,tostring
-------Utils
local strToIntCache = {
	["vector2"]=2,
	["vector3"]=3,
	["vector4"]=4,
}
oopUtil = {
	classReg = {},
	classMetaReg = {},
	instanceReg = setmetatable({},{__mode="kv"}),
	eventHandler = {},
	transfromEventName = function(eventName,isReverse)
		return isReverse and (eventName:sub(3,3):lower()..eventName:sub(4)) or ("on"..eventName:sub(1,1):upper()..eventName:sub(2))
	end,
	getVectorType = function(vec)
		if type(vec) == "userdata" then
			local typeName = getUserdataType(vec)
			if typeName == "vector" then
				return strToIntCache[typeName]
			end
		end
		return false
	end,
	deepCopyWithMeta = function(obj)
		local function Func(obj)
			if type(obj) ~= "table" then return obj end
			local NewTable = {}
			for k,v in pairs(obj) do
				NewTable[Func(k)] = Func(v)
			end
			return setmetatable(NewTable,getmetatable(obj))
		end
		return Func(obj)
	end,
	splitKeyValue = function(theTable)
		local keyTable = {}
		local valueTable = {}
		for key,value in pairs(theTable) do
			keyTable[#keyTable+1] = key
			valueTable[#valueTable+1] = value
		end
		return keyTable,valueTable
	end;
	deepCopy = function(obj)
		local function Func(obj)
			if type(obj) ~= "table" then return obj end
			local NewTable = {}
			for k,v in pairs(obj) do
				NewTable[Func(k)] = Func(v)
			end
			return NewTable
		end
		return Func(obj)
	end,
	shallowCopy = function(obj)
		local InTable = {}
		for k,v in pairs(obj) do
			InTable[k] = v
		end
		return InTable
	end,
	assimilate = function(t1,t2,except)
		if not t1 or not t2 then return end
		local exceptTable = {}
		if type(except) == "table" then
			for i=1,#except do
				exceptTable[ except[i] ] = true
			end
		end
		for k,v in pairs(t2) do
			if not exceptTable[k] then
				t1[k] = v
			end
		end
	end,
	spreadFunctionsForClass = function(class,classTemplate)
		oopUtil.assimilate(class,classTemplate,{"expose","constructor","default"})
		oopUtil.assimilate(class.default,classTemplate)
	end,
}

function class(name)
	return function(classTable)
		oopUtil.classReg[name] = classTable	--register class with class name
		oopUtil.classMetaReg[name] = {__index = {}}	--register class metatable with class name
		local meta = {
			__call = function(classTemplate,...)
				local newInstance = {}
				setmetatable(newInstance,oopUtil.classMetaReg[name])
				if classTemplate.constructor then
					classTemplate.constructor(newInstance,...)
				else
					local copyData = ...
					if type(copyData) ~= "table" then return newInstance end
					for k,v in pairs(copyData) do
						newInstance[k] = v
					end
				end
				return newInstance
			end,
		}
		if classTable.extend then
			if type(classTable.extend) ~= "table" then
				local extendClass = oopUtil.classReg[classTable.extend]
				for extKey,extFunction in pairs(extendClass) do
					if classTable[extKey] == nil then classTable[extKey] = extFunction end	--Don't overwrite child's function when copying parent's functions
				end
			else
				for key,extend in ipairs(classTable.extend) do
					local extendClass = oopUtil.classReg[extend]
					for extKey,extFunction in pairs(extendClass) do
						if classTable[extKey] == nil then classTable[extKey] = extFunction end	--Don't overwrite child's function when copying parent's functions
					end
				end
			end
		end
		if classTable.inject then
			for theType,space in pairs(classTable.inject) do
				local injectedData = oopUtil.classReg[theType]
				if not injectedData then injectedData = {} end
				for name,fnc in pairs(space or {}) do
					injectedData[name] = fnc
				end
				for name,fnc in pairs(space or {}) do
					injectedData[name] = fnc
				end
			end
		end
		if classTable.methodContinue then
			classTable.methodContinueList = classTable.methodContinueList or {}
			for fncName,method in pairs(classTable.methodContinue) do
				if not classTable.methodContinueList[fncName] then
					classTable.methodContinueList[fncName] = {classTable[fncName]}
					classTable.methodContinueList[fncName][#classTable.methodContinueList[fncName]+1] = method
					if fncName == "read" or fncName == "write" then
						classTable[fncName] = function(self,...)
							local fncs = classTable.methodContinueList[fncName]
							for i=1,#fncs do
								if not fncs[i] then
									local db = debug.getinfo(2)
									print(db.source..":"..db.currentline..": Bad continue at @"..name)
								end
								fncs[i](self,...)
							end
							return true
						end
					elseif fncName == "getSize" then
						classTable[fncName] = function(self,...)
							local fncs = classTable.methodContinueList[fncName]
							local size = 0
							for i=1,#fncs do
								if not fncs[i] then
									local db = debug.getinfo(2)
									print(db.source..":"..db.currentline..": Bad continue at @"..name)
								end
								local dSize = fncs[i](self,...)
								if not dSize then
									local db = debug.getinfo(2)
									print(db.source..":"..db.currentline..": Bad size at @"..name)
								end
								size = size+dSize
							end
							return size
						end
					end
				else
					local continueList = classTable.methodContinueList[fncName]
					continueList[#continueList+1] = method
				end
			end
			classTable.methodContinue = nil
		end
		meta.__index = {class=name}
		setmetatable(classTable,meta)
		oopUtil.spreadFunctionsForClass(oopUtil.classMetaReg[name].__index,classTable)
		oopUtil.classMetaReg[name].__index.class = name
		oopUtil.classMetaReg[name].__index.instance = true
		if not classTable.expose then
			_G[name] = classTable
		elseif oopUtil.classMetaReg[classTable.expose] then
			oopUtil.classMetaReg[classTable.expose].__index[name] = function(self,...) return classTable(...) end
		end
	end
end

function recastClass(inst,newClass)
	setmetatable(inst,oopUtil.classMetaReg[newClass.class])
end
oopUtil.class = class

class "Section" {
	type = 		false,
	size = 		false,
	version = 	false,
	reader =	false,
	read = function(self,readStream)
		if self.version then return end	--Already read
		if not readStream then
			local db = debug.getinfo(3)
			print(db.source..":"..db.currentline..": Bad readStream at @"..self.class)
		end
		self.type = readStream:read(uint32)
		self.size = readStream:read(uint32)
		self.version = readStream:read(uint32)
		if self.typeID then
			if self.typeID ~= self.type then
				local db = debug.getinfo(3)
				print(db.source..":"..db.currentline..": Bad typeID at @"..self.class..", expected "..self.typeID..", got "..self.type)
			end
		end
	end,
	write = function(self,writeStream)
		if not writeStream then
			local db = debug.getinfo(3)
			print(db.source..":"..db.currentline..": Bad writeStream at @"..self.class)
		end
		if not tonumber(self.type) or not self.size or not self.version then
			local db = debug.getinfo(3)
			print(db.source..":"..db.currentline..": Bad data at @"..self.class)
		end
		writeStream:write(self.type,uint32)
		writeStream:write(self.size,uint32)
		writeStream:write(self.version,uint32)
	end,
	getSize = function(self,excludeSection)
		if excludeSection then
			return 0
		else
			return 12
		end
	end,
}

class "Struct" { typeID = 0x01,
	extend = "Section",
	init = function(self,version)
		self.size = 0
		self.version = version
		self.type = Struct.typeID
	end,
}

class "Extension" { typeID = 0x03,
	extend = "Section",
	init = function(self,version)
		self.size = 0
		self.version = version
		self.type = Extension.typeID
	end,
}