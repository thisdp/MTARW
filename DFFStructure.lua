EnumRWVersion = {
	GTAVC = 0x0C02FFFF,
	GTASA = 0x1803FFFF
}
EnumBlendMode = {
    NOBLEND      = 0x00,
    ZERO         = 0x01,
    ONE          = 0x02,
    SRCCOLOR     = 0x03,
    INVSRCCOLOR  = 0x04,
    SRCALPHA     = 0x05,
    INVSRCALPHA  = 0x06,
    DESTALPHA    = 0x07,
    INVDESTALPHA = 0x08,
    DESTCOLOR    = 0x09,
    INVDESTCOLOR = 0x0A,
    SRCALPHASAT  = 0x0B,
}
EnumFilterMode = {
	None				= 0x00,	-- Filtering is disabled
	Nearest				= 0x01,	-- Point sampled
	Linear				= 0x02,	-- Bilinear
	MipNearest			= 0x03,	-- Point sampled per pixel mip map
	MipLinear			= 0x04,	-- Bilinear per pixel mipmap
	LinearMipNearest	= 0x05,	-- MipMap interp point sampled
	LinearMipLinear		= 0x06,	-- Trilinear
}

EnumMaterialEffect = {
	None				= 0x00,	-- No Effect
	BumpMap				= 0x01, -- Bump Map
	EnvMap				= 0x02, -- Environment Map (Reflections)
	BumpEnvMap			= 0x03, -- Bump Map/Environment Map
	Dual				= 0x04, -- Dual Textures
	UVTransform			= 0x05, -- UV-Tranformation
	DualUVTransform		= 0x06, -- Dual Textures/UV-Transformation
}

EnumLightType = {
	Directional = 0x01,		-- Directional light source
	Ambient = 0x02,			-- Ambient light source
	Point = 0x80,			-- Point light source
	Spot = 0x81,			-- Spotlight
	SpotSoft = 0x82,		-- Spotlight, soft edges
}

EnumLightFlag = {
	Scene = 0x01,	--Lights all the atomics of the object.
	World = 0x02,	--Lights the entire world.
}

Enum2DFX = {
	Light = 0x00,
	ParticleEffect = 0x01,
	PedAttractor = 0x03,
	SunGlare = 0x04,
	EnterExit = 0x06,
	StreetSign = 0x07,
	TriggerPoint = 0x08,
	CovePoint = 0x09,
	Escalator = 0x0A
}

class "UVAnimDict" {	typeID = 0x2B,
	extend = "Section",
	struct = false,
	methodContinue = {
		read = function(self,readStream)
			self.struct = UVAnimDictStruct()
			self.struct.parent = self
			self.struct:read(readStream)
		end,
		write = function(self,writeStream)
			self.struct:write(writeStream)
		end,
		getSize = function(self)
			local size = self.struct:getSize()
			self.size = size
			return size
		end,
		convert = function(self,targetVersion)
			self.struct:convert(targetVersion)
		end,
	}
}

class "UVAnimDictStruct" {
	extend = "Struct",
	animationCount = false,
	animations = false,
	methodContinue = {
		read = function(self,readStream)
			self.animationCount = readStream:read(uint32)
			self.animations = {}
			for i=1,self.animationCount do
				self.animations[i] = UVAnim()
				self.animations[i].parent = self
				self.animations[i]:read(readStream)
			end
		end,
		write = function(self,writeStream)
			writeStream:write(#self.animations,uint32)
			for i=1,#self.animations do
				self.animations[i]:write(writeStream)
			end
		end,
		getSize = function(self)
			local size = 4
			for i=1,#self.animations do
				size = size+self.animations[i]:getSize()
			end
			self.size = size
			return size
		end,
		convert = function(self,targetVersion)
			for i=1,#self.animations do
				self.animations[i]:convert(targetVersion)
			end
		end,
	}
}

class "UVAnim" {	typeID = 0x1B,
	extend = "Section",
	header = false,
	animType = false,
	frameCount = false,
	flags = false,
	duration = false,
	unused = false,
	name = false,
	nodeToUVChannel = false,
	data = false,
	methodContinue = {
		read = function(self,readStream)
			self.header = readStream:read(uint32)	--0x0100
			self.animType = readStream:read(uint32)
			self.frameCount = readStream:read(uint32)
			self.flags = readStream:read(uint32)
			self.duration = readStream:read(float)
			self.unused = readStream:read(uint32)
			self.name = readStream:read(char,32)
			self.nodeToUVChannel = {}
			for i=1,8 do
				self.nodeToUVChannel[i] = readStream:read(float)
			end
			self.data = {}
			for i=1,self.frameCount do
				self.data[i] = {}
				self.data[i].time = readStream:read(float)
				self.data[i].scale = {readStream:read(float),readStream:read(float),readStream:read(float)}
				self.data[i].position = {readStream:read(float),readStream:read(float),readStream:read(float)}
				self.data[i].previousFrame = readStream:read(int32)
			end
		end,
		write = function(self,writeStream)
			writeStream:write(self.header,uint32)
			writeStream:write(self.animType,uint32)
			writeStream:write(self.frameCount,uint32)
			writeStream:write(self.flags,uint32)
			writeStream:write(self.duration,float)
			writeStream:write(self.unused,uint32)
			writeStream:write(self.name,char,32)
			for i=1,8 do
				writeStream:write(self.nodeToUVChannel[i],float)
			end
			for i=1,self.frameCount do
				writeStream:write(self.data[i].time,float)
				writeStream:write(self.data[i].scale[1],float)
				writeStream:write(self.data[i].scale[2],float)
				writeStream:write(self.data[i].scale[3],float)
				writeStream:write(self.data[i].position[1],float)
				writeStream:write(self.data[i].position[2],float)
				writeStream:write(self.data[i].position[3],float)
				writeStream:write(self.data[i].previousFrame,int32)
			end
		end,
		getSize = function(self)
			local size = 4*6+32+4*8+4*8*self.frameCount
			self.size = size
			return size
		end,
	}
}

class "ClumpStruct" {
	extend = "Struct",
	atomicCount = false,
	lightCount = false,
	cameraCount = false,
	init = function(self,version)
		self.atomicCount = 0
		self.lightCount = 0
		self.cameraCount = 0
		self.size = self:getSize(true)
		self.version = version
		self.type = ClumpStruct.typeID
		return self
	end,
	methodContinue = {
		read = function(self,readStream)
			self.atomicCount = readStream:read(int32)
			self.lightCount = readStream:read(int32)
			self.cameraCount = readStream:read(int32)
		end,
		write = function(self,writeStream)
			writeStream:write(self.atomicCount,int32)
			writeStream:write(self.lightCount,int32)
			writeStream:write(self.cameraCount,int32)
		end,
		getSize = function(self)
			local size = 12
			self.size = size
			return size
		end,
	}
}

class "Clump" {	typeID = 0x10,
	extend = "Section",
	struct = false,
	frameList = false,
	geometryList = false,
	atomics = false,
	indexStructs = false,
	lights = false,
	extension = false,
	init = function(self,version)
		self.struct = ClumpStruct():init(version)
		self.struct.parent = self
		self.frameList = FrameList():init(version)
		self.frameList.parent = self
		self.geometryList = GeometryList():init(version)
		self.geometryList.parent = self
		self.extension = Extension():init(version)
		self.extension.parent = self
		self.atomics = {}
		self.indexStructs = {}
		self.lights = {}
		self.size = self:getSize(true)
		self.version = version
		self.type = Clump.typeID
		return self
	end,
	createAtomic = function(self)
		local atomic = Atomic():init(self.version)
		self.atomic.parent = self
		self.struct.atomicCount = self.struct.atomicCount+1
		self.atomics[self.struct.atomicCount] = atomic
		self.size = self:getSize(true)
		return atomic
	end,
	addComponent = function(self)
		self:createAtomic()
		self.frameList:createFrame()
		self.geometryList:createGeometry()
		self.size = self:getSize(true)
	end,
	methodContinue = {
		read = function(self,readStream)
			self.struct = ClumpStruct()
			self.struct.parent = self
			self.struct:read(readStream)
			--Read Frame List
			self.frameList = FrameList()
			self.frameList.parent = self
			self.frameList:read(readStream)
			--Read Geometry List
			self.geometryList = GeometryList()
			self.geometryList.parent = self
			self.geometryList:read(readStream)
			--Read Atomics
			self.atomics = {}
			for i=1,self.struct.atomicCount do
				--print("Reading Atomic",i,readStream.readingPos)
				self.atomics[i] = Atomic()
				self.atomics[i].parent = self
				self.atomics[i]:read(readStream)
			end
			local nextSection
			repeat
				nextSection = Section()
				nextSection.parent = self
				nextSection:read(readStream)
				if nextSection.type == Struct.typeID then
					recastClass(nextSection,IndexStruct)
					nextSection:read(readStream)
					if not self.indexStructs then self.indexStructs = {} end
					self.indexStructs[#self.indexStructs+1] = nextSection
				elseif nextSection.type == Light.typeID then
					recastClass(nextSection,Light)
					nextSection:read(readStream)
					if not self.lights then self.lights = {} end
					self.lights[#self.lights+1] = nextSection
				end
			until nextSection.type == ClumpExtension.typeID
			--Read Extension
			recastClass(nextSection,ClumpExtension)
			self.extension = nextSection
			self.extension:read(readStream)
		end,
		write = function(self,writeStream)
			self.struct.atomicCount = #self.atomics
			self.struct:write(writeStream)
			--Write Frame List
			self.frameList:write(writeStream)
			--Write Geometry List
			self.geometryList:write(writeStream)
			--Write Atomics
			for i=1,#self.atomics do
				--print("Write Atomic",i)
				self.atomics[i]:write(writeStream)
			end
			--Write Lights
			if self.indexStructs then
				iprint(self.indexStructs)
				for i=1,#self.indexStructs do
					if self.lights[i] then
						self.indexStructs[i]:write(writeStream)
						self.lights[i]:write(writeStream)
					end
				end
			end
			--Write Extension
			self.extension:write(writeStream)
		end,
		getSize = function(self)
			local size = self.struct:getSize()+self.frameList:getSize()+self.geometryList:getSize()
			for i=1,#self.atomics do
				size = size+self.atomics[i]:getSize()
			end
			size = size+self.extension:getSize()
			self.size = size
			return size
		end,
		convert = function(self,targetVersion)
			self.struct:convert(targetVersion)
			self.frameList:convert(targetVersion)
			self.geometryList:convert(targetVersion)
			for i=1,#self.atomics do
				self.atomics[i]:convert(targetVersion)
			end
			if self.indexStructs then
				for i=1,#self.indexStructs do
					if self.lights[i] then
						self.indexStructs[i]:convert(targetVersion)
						self.lights[i]:convert(targetVersion)
					end
				end
			end
			self.extension:convert(targetVersion)
			self:getSize()
		end,
	}
}

class "IndexStruct" {
	extend = "Struct",
	index = false,
	methodContinue = {
		read = function(self,readStream)
			self.index = readStream:read(uint32)
		end,
		write = function(self,writeStream)
			writeStream:write(self.index,uint32)
		end,
		getSize = function(self)
			local size = 4
			self.size = size
			return size
		end
	}
}

class "LightStruct" {
	extend = "Struct",
	frameIndex = false,
	radius = false,
	red = false,
	green = false,
	blue = false,
	direction = false,
	flags = false,
	lightType = false,
	methodContinue = {
		read = function(self,readStream)
			self.radius = readStream:read(float)
			self.red = readStream:read(float)
			self.green = readStream:read(float)
			self.blue = readStream:read(float)
			self.direction = readStream:read(float)
			self.flags = readStream:read(uint16)
			self.lightType = readStream:read(uint16)
		end,
		write = function(self,writeStream)
			writeStream:write(self.radius,float)
			writeStream:write(self.red,float)
			writeStream:write(self.green,float)
			writeStream:write(self.blue,float)
			writeStream:write(self.direction,float)
			writeStream:write(self.flags,uint16)
			writeStream:write(self.lightType,uint16)
		end,
		getSize = function(self)
			local size = 24
			self.size = size
			return size
		end,
	}
}

class "Light" {	typeID = 0x12,
	extend = "Section",
	struct = false,
	extension = false,
	methodContinue = {
		read = function(self,readStream)
			self.struct = LightStruct()
			self.struct.parent = self
			self.struct:read(readStream)
			self.extension = Extension()
			self.extension.parent = self
			self.extension:read(readStream)
		end,
		write = function(self,writeStream)
			self.struct:write(writeStream)
			self.extension:write(writeStream)
		end,
		getSize = function(self)
			local size = self.struct:getSize()+self.extension:getSize()
			self.size = size
			return size
		end,
		convert = function(self,targetVersion)
			self.struct:convert(targetVersion)
			self.extension:convert(targetVersion)
		end,
	}
}

class "ClumpExtension" {
	extend = "Extension",
	collisionSection = false,
	init = function(self,version)
		self.size = self:getSize(true)
		self.version = version
		self.type = ClumpExtension.typeID
		return self
	end,
	methodContinue = {
		read = function(self,readStream)
			if self.size > 0 then
				self.collisionSection = COLSection()
				self.collisionSection.parent = self
				self.collisionSection:read(readStream)
			end
		end,
		write = function(self,writeStream)
			if self.collisionSection then
				self.collisionSection:write(writeStream)
			end
		end,
		getSize = function(self)
			local size = 0
			if self.collisionSection then
				size = size+self.collisionSection:getSize()
			end
			self.size = size
			return size
		end,
		convert = function(self,targetVersion)
			if self.collisionSection then
				self.collisionSection:convert(targetVersion)
			end
		end,
	}
}

class "FrameListStruct" {
	extend = "Struct",
	frameCount = false,
	frameInfo = false,
	init = function(self,version)
		self.frameCount = 0
		self.frameInfo = {}
		self.size = self:getSize(true)
		self.version = version
		self.type = FrameListStruct.typeID
		return self
	end,
	createFrameInfo = function(self)
		self.frameInfo[#self.frameInfo+1] = {
			rotationMatrix = {	--By Default
				{1,0,0},
				{0,1,0},
				{0,0,1},
			},
			positionVector = {0,0,0},
			parentFrame = 0,	--Compatible to lua array
			matrixFlags = 0x00020003,
		}
		self.size = self:getSize(true)
		return #self.frameInfo
	end,
	setFrameInfoParentFrame = function(self,frameInfoID,parentFrameID)
		if not self.frameInfo[frameInfoID] then error("Bad argument @setFrameInfoParentFrame, frame info index out of range, total "..#self.frameInfo.." got "..frameInfoID) end
		self.frameInfo[frameInfoID].parentFrame = parentFrameID
		return self
	end,
	setFrameInfoPosition = function(self,frameInfoID,x,y,z)
		if not self.frameInfo[frameInfoID] then error("Bad argument @setFrameInfoPosition, frame info index out of range, total "..#self.frameInfo.." got "..frameInfoID) end
		self.frameInfo[frameInfoID].positionVector[1] = x
		self.frameInfo[frameInfoID].positionVector[2] = y
		self.frameInfo[frameInfoID].positionVector[3] = z
		return self
	end,
	getFrameInfoPosition = function(self,frameInfoID)
		if not self.frameInfo[frameInfoID] then error("Bad argument @getFrameInfoParentFrame, frame info index out of range, total "..#self.frameInfo.." got "..frameInfoID) end
		local posVector = self.frameInfo[frameInfoID]
		return posVector[1],posVector[2],posVector[3]
	end,
	setFrameInfoRotation = function(self,frameInfoID,rx,ry,rz)
		if not self.frameInfo[frameInfoID] then error("Bad argument @setFrameInfoRotation, frame info index out of range, total "..#self.frameInfo.." got "..frameInfoID) end
		self.frameInfo[frameInfoID].rotationMatrix = eulerToRotationMatrix(rx,ry,rz)
		return self
	end,
	getFrameInfoRotation = function(self,frameInfoID)
		if not self.frameInfo[frameInfoID] then error("Bad argument @getFrameInfoRotation, frame info index out of range, total "..#self.frameInfo.." got "..frameInfoID) end
        local rotMatrix = self.frameInfo[frameInfoID].rotationMatrix
		return rotationMatrixToEuler(rotMatrix)
	end,
	methodContinue = {
		read = function(self,readStream)
			self.frameCount = readStream:read(uint32)
			if not self.frameInfo then self.frameInfo = {} end
			for i=1,self.frameCount do
				self.frameInfo[i] = {
					rotationMatrix = {
						{readStream:read(float),readStream:read(float),readStream:read(float)},
						{readStream:read(float),readStream:read(float),readStream:read(float)},
						{readStream:read(float),readStream:read(float),readStream:read(float)},
					},
					positionVector = {
						readStream:read(float),readStream:read(float),readStream:read(float),
					},
					parentFrame = readStream:read(uint32)+1,	--Compatible to lua array
					matrixFlags = readStream:read(uint32),
				}
			end
		end,
		write = function(self,writeStream)
			writeStream:write(self.frameCount,uint32)
			for i=1,self.frameCount do
				local fInfo = self.frameInfo[i]
				for x=1,3 do for y=1,3 do
					writeStream:write(fInfo.rotationMatrix[x][y],float)
				end end
				writeStream:write(fInfo.positionVector[1],float)
				writeStream:write(fInfo.positionVector[2],float)
				writeStream:write(fInfo.positionVector[3],float)
				writeStream:write(fInfo.parentFrame-1,uint32)	--Compatible to lua array
				writeStream:write(fInfo.matrixFlags,uint32)
			end
		end,
		getSize = function(self)
			local size = 4+(9*4+3*4+4+4)*#self.frameInfo
			self.size = size
			return size
		end,
	}
}

class "FrameList" {	typeID = 0x0E,
	extend = "Section",
	struct = false,
	frames = false,
	init = function(self,version)
		self.struct = FrameListStruct():init(version)
		self.struct.parent = self
		self.frames = {}
		self.size = self:getSize(true)
		self.version = version
		self.type = FrameList.typeID
		return self
	end,
	createFrame = function(self,name)
		local FrameListExtension = FrameListExtension():init(self.version)
		FrameListExtension.parent = self
		FrameListExtension.frame:setName(name or "unnamed")
		FrameListExtension:update()
		self.struct:createFrameInfo()
		self.struct.frameCount = self.struct.frameCount+1
		self.frames[self.struct.frameCount] = FrameListExtension
		self.size = self:getSize(true)
		return FrameListExtension
	end,
	methodContinue = {
		read = function(self,readStream)
			--Read Struct
			self.struct = FrameListStruct()
			self.struct.parent = self
			self.struct:read(readStream)
			--Read Frames
			self.frames = {}
			for i=1,self.struct.frameCount do
				self.frames[i] = FrameListExtension()
				self.frames[i].parent = self
				self.frames[i]:read(readStream)
			end
		end,
		write = function(self,writeStream)
			self.struct.frameCount = #self.frames
			self.struct:write(writeStream)
			for i=1,#self.frames do
				self.frames[i]:write(writeStream)
			end
		end,
		getSize = function(self)
			local size = self.struct:getSize()
			for i=1,#self.frames do
				size = size+self.frames[i]:getSize()
			end
			self.size = size
			return size
		end,
		convert = function(self,targetVersion)
			self.struct:convert(targetVersion)
			for i=1,#self.frames do
				self.frames[i]:convert(targetVersion)
			end
		end,
	}
}

class "FrameListExtension" {
	extend = "Extension",
	frame = false,
	HAnimPLG = false,
	init = function(self,version)
		self.frame = Frame():init(version)
		self.frame.parent = self
		self.size = self:getSize(true)
		self.version = version
		self.type = FrameListExtension.typeID
		return self
	end,
	methodContinue = {
		read = function(self,readStream)
			if self.size ~= 0 then
				local section = Section()
				section.parent = self
				section:read(readStream)
				if section.type == HAnimPLG.typeID then
					recastClass(section,HAnimPLG)
					self.HAnimPLG = section
					self.HAnimPLG:read(readStream)
					section = Section()
					section.parent = self
				end
				recastClass(section,Frame)
				self.frame = section
				self.frame:read(readStream)
			end
		end,
		write = function(self,writeStream)
			if self.HAnimPLG then
				self.HAnimPLG:write(writeStream)
			end
			if self.frame then
				self.frame:write(writeStream)
			end
		end,
		getSize = function(self)
			local size = self.frame:getSize()
			self.size = size
			return size
		end,
		convert = function(self,targetVersion)
			if self.HAnimPLG then
				self.HAnimPLG:convert(targetVersion)
			end
			if self.frame then
				self.frame:convert(targetVersion)
			end
		end,
	},
}

class "Frame" {	typeID = 0x253F2FE,
	extend = "Section",
	name = false,
	init = function(self,version)
		self.name = ""
		self.size = self:getSize(true)
		self.version = version
		self.type = Frame.typeID
		return self
	end,
	setName = function(self,name)
		self.name = name
		self.size = self:getSize(true)
		return self
	end,
	methodContinue = {
		read = function(self,readStream)
			self.name = readStream:read(char,self.size)
		end,
		write = function(self,writeStream)
			writeStream:write(self.name,char,self.size)
		end,
		getSize = function(self)
			local size = #self.name
			self.size = size
			return size
		end,
	},
}

class "GeometryListStruct" {
	extend = "Struct",
	init = function(self,version)
		self.geometryCount = 0
		self.size = self:getSize(true)
		self.version = version
		self.type = GeometryListStruct.typeID
		return self
	end,
	methodContinue = {
		read = function(self,readStream)
			self.geometryCount = readStream:read(uint32)
		end,
		write = function(self,writeStream)
			writeStream:write(self.geometryCount,uint32)
		end,
		getSize = function(self)
			local size = 4
			self.size = size
			return size
		end,
	}
}

class "GeometryList" {	typeID = 0x1A,
	extend = "Section",
	struct = false,
	geometries = false,
	init = function(self,version)
		self.struct = GeometryListStruct():init(version)
		self.struct.parent = self
		self.geometries = {}
		self.size = self:getSize(true)
		self.version = version
		self.type = GeometryList.typeID
		return self
	end,
	createGeometry = function(self)
		local geometry = Geometry():init(self.version)
		geometry.parent = self
		self.struct.geometryCount = self.struct.geometryCount+1
		self.geometries[self.struct.geometryCount] = geometry
		self.size = self:getSize(true)
		return geometry
	end,
	methodContinue = {
		read = function(self,readStream)
			self.struct = GeometryListStruct()
			self.struct.parent = self
			self.struct:read(readStream)
			self.geometries = {}
			--Read Geometries
			for i=1,self.struct.geometryCount do
				--print("Reading Geometry",i)
				self.geometries[i] = Geometry()
				self.geometries[i].parent = self
				self.geometries[i]:read(readStream)
			end
		end,
		write = function(self,writeStream)
			self.struct.geometryCount = #self.geometries
			self.struct:write(writeStream)
			for i=1,#self.geometries do
				self.geometries[i]:write(writeStream)
			end
		end,
		getSize = function(self)
			local size = self.struct:getSize()
			for i=1,#self.geometries do
				size = size+self.geometries[i]:getSize()
			end
			self.size = size
			return size
		end,
		convert = function(self,targetVersion)
			self.struct:convert(targetVersion)
			for i=1,#self.geometries do
				self.geometries[i]:convert(targetVersion)
			end
		end,
	}
}

class "GeometryStruct" {
	extend = "Struct",
	trangleCount = false,
	vertexCount = false,
	morphTargetCount = false,
	--version < EnumRWVersion.GTASA
	ambient = false,
	specular = false,
	diffuse = false,
	--Data
	vertexColors = false,
	texCoords = false,
	faces = false,
	vertices = false,
	normals = false,
	boundingSphere = false,
	hasVertices = false,
	hasNormals = false,
	--Casted From flags
	bTristrip = false,
	bPosition = false,
	bTextured = false,
	bVertexColor = false,
	bNormal = false,
	bLight = false,
	bModulateMaterialColor = false,
	bTextured2 = false,
	bNative = false,
	TextureCount = false,
	--
	init = function(self,version)
		self.faceCount = 0
		self.vertexCount = 0
		self.morphTargetCount = 1
		self.boundingSphere = {0,0,0,0}
		self.hasVertices = false
		self.hasNormals = false
		self.size = self:getSize(true)
		self.version = version
		self.type = GeometryStruct.typeID
		return self
	end,
	methodContinue = {
		read = function(self,readStream)
			local flags = readStream:read(uint16)
			--Extract Flags
			self.bTristrip = bExtract(flags,0) == 1
			self.bPosition = bExtract(flags,1) == 1
			self.bTextured = bExtract(flags,2) == 1
			self.bVertexColor = bExtract(flags,3) == 1
			self.bNormal = bExtract(flags,4) == 1
			self.bLight = bExtract(flags,5) == 1
			self.bModulateMaterialColor = bExtract(flags,6) == 1
			self.bTextured2 = bExtract(flags,7) == 1
			self.TextureCount = readStream:read(uint8)
			self.bNative = (readStream:read(uint8)%2) == 1
			--Read face count
			self.faceCount = readStream:read(uint32)
			self.vertexCount = readStream:read(uint32)
			self.morphTargetCount = readStream:read(uint32)
			--
			if self.version < EnumRWVersion.GTASA then
				self.ambient = readStream:read(float)
				self.specular = readStream:read(float)
				self.diffuse = readStream:read(float)
			end
			
			if not self.bNative then
				if self.bVertexColor then
					--R,G,B,A
					self.vertexColors = {}
					for vertices=1, self.vertexCount do
						self.vertexColors[vertices] = {readStream:read(uint8),readStream:read(uint8),readStream:read(uint8),readStream:read(uint8)}
					end
				end
				self.texCoords = {}
				for i=1,(self.TextureCount ~= 0 and self.TextureCount or ((self.bTextured and 1 or 0)+(self.bTextured2 and 1 or 0)) ) do
					--U,V
					self.texCoords[i] = {}
					for vertices=1, self.vertexCount do
						self.texCoords[i][vertices] = {readStream:read(float),readStream:read(float)}
					end
				end
				self.faces = {}
				for i=1,self.faceCount do
					--Vertex2, Vertex1, MaterialID, Vertex3
					self.faces[i] = {readStream:read(uint16),readStream:read(uint16),readStream:read(uint16),readStream:read(uint16)}
				end
			end
			--for i=1,self.morphTargetCount do	--morphTargetCount must be 1
			--X,Y,Z,Radius
			self.boundingSphere = {readStream:read(float),readStream:read(float),readStream:read(float),readStream:read(float)}
			self.hasVertices = readStream:read(uint32) ~= 0
			self.hasNormals = readStream:read(uint32) ~= 0
			if self.hasVertices then
				self.vertices = {}
				for vertex=1,self.vertexCount do
					self.vertices[vertex] = {readStream:read(float),readStream:read(float),readStream:read(float)}
				end
			end
			if self.hasNormals then
				self.normals = {}
				for vertex=1,self.vertexCount do
					self.normals[vertex] = {readStream:read(float),readStream:read(float),readStream:read(float)}
				end
			end
			--end
		end,
		write = function(self,writeStream)
			local flags = bAssemble(
				self.bTristrip,
				self.bPosition,
				self.bTextured,
				self.bVertexColor,
				self.bNormal,
				self.bLight,
				self.bModulateMaterialColor,
				self.bTextured2
			)+(self.bNative and 1 or 0)*2^24+self.TextureCount*2^16
			writeStream:write(flags,uint32)
			writeStream:write(self.faceCount,uint32)
			writeStream:write(self.vertexCount,uint32)
			writeStream:write(self.morphTargetCount,uint32)
			if self.version < EnumRWVersion.GTASA then
				writeStream:write(self.ambient,float)
				writeStream:write(self.specular,float)
				writeStream:write(self.diffuse,float)
			end
			if not self.bNative then
				if self.bVertexColor then
					--R,G,B,A
					for vertices=1, self.vertexCount do
						writeStream:write(self.vertexColors[vertices][1],uint8)
						writeStream:write(self.vertexColors[vertices][2],uint8)
						writeStream:write(self.vertexColors[vertices][3],uint8)
						writeStream:write(self.vertexColors[vertices][4],uint8)
					end
				end
				for i=1,(self.TextureCount ~= 0 and self.TextureCount or ((self.bTextured and 1 or 0)+(self.bTextured2 and 1 or 0)) ) do
					--U,V
					for vertices=1, self.vertexCount do
						writeStream:write(self.texCoords[i][vertices][1],float)
						writeStream:write(self.texCoords[i][vertices][2],float)
					end
				end
				for i=1,self.faceCount do
					--Vertex2, Vertex1, MaterialID, Vertex3
					writeStream:write(self.faces[i][1],uint16)
					writeStream:write(self.faces[i][2],uint16)
					writeStream:write(self.faces[i][3],uint16)
					writeStream:write(self.faces[i][4],uint16)
				end
			end
			for i=1,self.morphTargetCount do	--morphTargetCount should be 1
				--X,Y,Z,Radius
				writeStream:write(self.boundingSphere[1],float)
				writeStream:write(self.boundingSphere[2],float)
				writeStream:write(self.boundingSphere[3],float)
				writeStream:write(self.boundingSphere[4],float)
				writeStream:write(self.hasVertices and 1 or 0,uint32)
				writeStream:write(self.hasNormals and 1 or 0,uint32)
				if self.hasVertices then
					for vertex=1,self.vertexCount do
						writeStream:write(self.vertices[vertex][1],float)
						writeStream:write(self.vertices[vertex][2],float)
						writeStream:write(self.vertices[vertex][3],float)
					end
				end
				if self.hasNormals then
					for vertex=1,self.vertexCount do
						writeStream:write(self.normals[vertex][1],float)
						writeStream:write(self.normals[vertex][2],float)
						writeStream:write(self.normals[vertex][3],float)
					end
				end
			end
		end,
		getSize = function(self)
			local size = 4*4
			if self.version < EnumRWVersion.GTASA then
				size = size+4*3
			end
			if not self.bNative then
				if self.bVertexColor then
					size = size+self.vertexCount*4
				end
				size = size+self.vertexCount*4*2*(self.TextureCount ~= 0 and self.TextureCount or ((self.bTextured and 1 or 0)+(self.bTextured2 and 1 or 0)))+self.faceCount*2*4
			end
			for i=1,self.morphTargetCount do
				size = size+4*6
				if self.hasVertices then
					size = size+self.vertexCount*4*3
				end
				if self.hasNormals then
					size = size+self.vertexCount*4*3
				end
			end
			self.size = size
			return size
		end,
	}
}

class "Geometry" {	typeID = 0x0F,
	extend = "Section",
	struct = false,
	materialList = false,
	extension = false,
	init = function(self,version)
		self.struct = GeometryStruct():init(version)
		self.struct.parent = self
		self.materialList = MaterialList():init(version)
		self.materialList.parent = self
		self.extension = GeometryExtension():init(version)
		self.extension.parent = self
		self.size = self:getSize(true)
		self.version = version
		self.type = Geometry.typeID
		return self
	end,
	methodContinue = {
		read = function(self,readStream)
			self.struct = GeometryStruct()
			self.struct.parent = self
			self.struct:read(readStream)
			--Read Material List
			self.materialList = MaterialList()
			self.materialList.parent = self
			self.materialList:read(readStream)
			--Read Extension
			self.extension = GeometryExtension()
			self.extension.parent = self
			self.extension:read(readStream)
		end,
		write = function(self,writeStream)
			self.struct:write(writeStream)
			self.materialList:write(writeStream)
			self.extension:write(writeStream)
		end,
		getSize = function(self)
			local size = self.struct:getSize()+self.materialList:getSize()+self.extension:getSize()
			self.size = size
			return size
		end,
		convert = function(self,targetVersion)
			self.struct:convert(targetVersion)
			self.materialList:convert(targetVersion)
			self.extension:convert(targetVersion)
		end,
	},
	mergeGeometry = function(self,target,clone)
		--Compare flag (maybe will be implemented soon)
		if not self.struct.bTristrip == target.struct.bTristrip then return false end
		if not self.struct.bPosition == target.struct.bPosition then return false end
		if not self.struct.bTextured == target.struct.bTextured then return false end
		if not self.struct.bVertexColor == target.struct.bVertexColor then return false end
		if not self.struct.bNormal == target.struct.bNormal then return false end
		if not self.struct.bLight == target.struct.bLight then return false end
		if not self.struct.bModulateMaterialColor == target.struct.bModulateMaterialColor then return false end
		if not self.struct.bTextured2 == target.struct.bTextured2 then return false end
		if not self.struct.bNative == target.struct.bNative then return false end
		if not self.struct.hasNormals == target.struct.hasNormals then return false end
		if clone then	--Clone a new geometry table?
			local oldSelf = self
			self = oopUtil.deepCopy(self,self.parent)
		end
		
		--Merge Struct
		--Add face/vertex count
		local targetVertices = target.struct.vertices or {}
		local selfVertices = self.struct.vertices or {}
		local targetVertexCount = #targetVertices
		local selfVertexCount = #selfVertices
		local targetFaceIndex,selfFaceIndex
		
		if not self.struct.bNative then
			if self.struct.bVertexColor then
				local targetVertexColors = target.struct.vertexColors
				local selfVertexColors = self.struct.vertexColors
				local selfVertexColorIndex = #selfVertexColors
				for i=1,#targetVertices do	--Copy vertex colors
					selfVertexColors[selfVertexColorIndex+i] = {targetVertexColors[i][1],targetVertexColors[i][2],targetVertexColors[i][3],targetVertexColors[i][4]}
				end
			end
			for i=1,(self.struct.TextureCount ~= 0 and self.struct.TextureCount or ((self.struct.bTextured and 1 or 0)+(self.struct.bTextured2 and 1 or 0)) ) do
				--U,V
				local selfTexCoords = self.struct.texCoords[i]
				local targetTexCoords = target.struct.texCoords[i]
				local selfTexCoordIndex = #selfTexCoords
				for vertices = 1,#targetVertices do	--Copy texture coordinates
					selfTexCoords[selfTexCoordIndex+vertices] = {targetTexCoords[vertices][1],targetTexCoords[vertices][2]}
				end
			end
			
			local targetFaces = target.struct.faces
			local selfFaces = self.struct.faces
			selfFaceIndex = #self.struct.faces
			for i=1,#targetFaces do	--Copy faces
				selfFaces[i+selfFaceIndex] = {targetFaces[i][1]+selfVertexCount,targetFaces[i][2]+selfVertexCount,targetFaces[i][3],targetFaces[i][4]+selfVertexCount}
			end
		end
		--for i=1,self.morphTargetCount do	--morphTargetCount must be 1
		--X,Y,Z,Radius
		--self.boundingSphere
		self.struct.hasVertices = self.struct.hasVertices or target.struct.hasVertices
		--self.struct.hasNormals = self.struct.hasNormals or target.struct.hasNormals
		if self.struct.hasVertices then
			self.struct.vertices = self.struct.vertices or {}
			local selfVertices = self.struct.vertices
			for vertex=1,targetVertexCount do
				selfVertices[vertex+selfVertexCount] = {targetVertices[vertex][1],targetVertices[vertex][2],targetVertices[vertex][3]}
			end
		end
		if self.struct.hasNormals then
			self.struct.normals = self.struct.normals or {}
			local selfNormals,targetNormals = self.struct.normals,target.struct.normals
			for vertex=1,targetVertexCount do
				selfNormals[vertex+selfVertexCount] = {targetNormals[vertex][1],targetNormals[vertex][2],targetNormals[vertex][3]}
			end
		end
		self.struct.faceCount = #self.struct.faces
		self.struct.vertexCount = #self.struct.vertices
		--end
		
		--Merge Material
		local matListToMerge = target.materialList
		local selfMatListIndex = matListToMerge.struct.materialCount
		for i=1,matListToMerge.struct.materialCount do
			self.materialList.struct.materialIndices[i+self.materialList.struct.materialCount] = matListToMerge.struct.materialIndices[i]
			self.materialList.materials[i+self.materialList.struct.materialCount] = matListToMerge.materials[i]
		end
		self.materialList.struct.materialCount = #self.materialList.struct.materialIndices
		--Merge Extension
		local selfExtension = self.extension
		local targetExtension = target.extension
		if selfExtension.binMeshPLG and targetExtension.binMeshPLG then
			if selfExtension.binMeshPLG.faceType == targetExtension.binMeshPLG.faceType then --FaceType should be the same
				local selfBinMesh = selfExtension.binMeshPLG
				local targetBinMesh = targetExtension.binMeshPLG
				
				for i=1,targetBinMesh.materialSplitCount do
					--Faces, MaterialIndex, FaceList
					local matIndex = selfBinMesh.materialSplitCount+i
					selfBinMesh.materialSplits[matIndex] = {targetBinMesh.materialSplits[i][1],selfMatListIndex+targetBinMesh.materialSplits[i][2],{}}
					for faceIndex=1,targetBinMesh.materialSplits[i][1] do
						selfBinMesh.materialSplits[matIndex][3][faceIndex] = targetBinMesh.materialSplits[i][3][faceIndex]+selfFaceIndex	--Face Index
					end
				end
				selfBinMesh.materialSplitCount = selfBinMesh.materialSplitCount+targetBinMesh.materialSplitCount
				selfBinMesh.vertexCount = selfBinMesh.vertexCount+targetBinMesh.vertexCount
			end
		end
		
		if selfExtension.nightVertexColor and targetExtension.nightVertexColor then
			if selfExtension.nightVertexColor.hasColor == targetExtension.nightVertexColor.hasColor then	--Currently, Only merge when both have night vertex color
				local targetNVC = targetExtension.nightVertexColor.colors
				local selfNVC = selfExtension.nightVertexColor.colors
				local selfNVCCount = #selfNVC
				for i=1,#targetNVC do
					selfNVC[i+selfNVCCount] = {targetNVC[i][1],targetNVC[i][2],targetNVC[i][3],targetNVC[i][4]}
				end
				iprint(#selfExtension.nightVertexColor.colors)
			end
		end
	end,
}

class "GeometryExtension" {
	extend = "Extension",
	binMeshPLG = false,
	breakable = false,
	nightVertexColor = false,
	effect2D = false,
	skinPLG = false,
	morphPLG = false,
	init = function(self,version)
		self.size = self:getSize(true)
		self.version = version
		self.type = GeometryExtension.typeID
		return self
	end,
	methodContinue = {
		read = function(self,readStream)
			local nextSection
			local readSize = 0
			repeat
				nextSection = Section()
				nextSection.parent = self
				nextSection:read(readStream)
				if nextSection.type == BinMeshPLG.typeID then
					recastClass(nextSection,BinMeshPLG)
					self.binMeshPLG = nextSection
				elseif nextSection.type == Breakable.typeID then
					recastClass(nextSection,Breakable)
					self.breakable = nextSection
				elseif nextSection.type == NightVertexColor.typeID then
					recastClass(nextSection,NightVertexColor)
					self.nightVertexColor = nextSection
				elseif nextSection.type == Effect2D.typeID then
					recastClass(nextSection,Effect2D)
					self.effect2D = nextSection
				elseif nextSection.type == SkinPLG.typeID then
					recastClass(nextSection,SkinPLG)
					self.skinPLG = nextSection
				elseif nextSection.type == MorphPLG.typeID then
					recastClass(nextSection,MorphPLG)
					self.morphPLG = nextSection
				else
					error("Unsupported Geometry Plugin "..nextSection.type)
				end
				nextSection.parent = self
				nextSection:read(readStream)
				readSize = readSize+nextSection.size+12
			until readSize >= self.size
		end,
		write = function(self,writeStream)
			if self.binMeshPLG then self.binMeshPLG:write(writeStream) end
			if self.skinPLG then self.skinPLG:write(writeStream) end
			if self.morphPLG then self.morphPLG:write(writeStream) end
			if self.breakable then self.breakable:write(writeStream) end
			if self.nightVertexColor then self.nightVertexColor:write(writeStream) end
			if self.effect2D then self.effect2D:write(writeStream) end
		end,
		getSize = function(self)
			local size = 0
			if self.binMeshPLG then size = size+self.binMeshPLG:getSize() end
			if self.morphPLG then size = size+self.morphPLG:getSize() end
			if self.breakable then size = size+self.breakable:getSize() end
			if self.nightVertexColor then size = size+self.nightVertexColor:getSize() end
			if self.effect2D then size = size+self.effect2D:getSize() end
			self.size = size
			return size
		end,
		convert = function(self,targetVersion)
			if self.binMeshPLG then self.binMeshPLG:convert(targetVersion) end
			if self.morphPLG then self.morphPLG:convert(targetVersion) end
			if self.skinPLG then self.skinPLG:convert(targetVersion) end
			if self.breakable then self.breakable:convert(targetVersion) end
			if self.nightVertexColor then self.nightVertexColor:convert(targetVersion) end
			if self.effect2D then self.effect2D:convert(targetVersion) end
		end,
	}
}

class "NightVertexColor" {	typeID = 0x253F2F9,
	extend = "Section",
	hasColor = false,
	colors = false,
	methodContinue = {
		read = function(self,readStream)
			self.hasColor = readStream:read(uint32)
			self.colors = {}
			for i=1,(self.size-4)/4 do
				self.colors[i] = {readStream:read(uint8),readStream:read(uint8),readStream:read(uint8),readStream:read(uint8)}
			end
		end,
		write = function(self,writeStream)
			writeStream:write(self.hasColor,uint32)
			for i=1,#self.colors do
				writeStream:write(self.colors[i][1],uint8)
				writeStream:write(self.colors[i][2],uint8)
				writeStream:write(self.colors[i][3],uint8)
				writeStream:write(self.colors[i][4],uint8)
			end
			
		end,
		getSize = function(self)
			local size = 4*#self.colors+4
			self.size = size
			iprint(#self.colors,self.size)
			return size
		end,
	}
}

class "MaterialListStruct" {
	extend = "Struct",
	materialCount = false,
	materialIndices = false,
	init = function(self,version)
		self.materialCount = 0
		self.materialIndices = {}
		self.size = self:getSize(true)
		self.version = version
		self.type = MaterialListStruct.typeID
		return self
	end,
	methodContinue = {
		read = function(self,readStream)
			self.materialCount = readStream:read(uint32)
			self.materialIndices = {}
			for i=1,self.materialCount do
				--For material, -1; For a pointer of existing material, other index value.
				self.materialIndices[i] = readStream:read(int32)
			end
		end,
		write = function(self,writeStream)
			writeStream:write(self.materialCount,uint32)
			for i=1,self.materialCount do
				writeStream:write(self.materialIndices[i],int32)
			end
		end,
		getSize = function(self)
			local size = 4+4*self.materialCount
			self.size = size
			return size
		end,
	}
}

class "MaterialList" {	typeID = 0x08,
	extend = "Section",
	struct = false,
	materials = false,
	init = function(self,version)
		self.struct = MaterialListStruct():init(version)
		self.struct.parent = self
		self.materials = {}
		self.size = self:getSize(true)
		self.version = version
		self.type = MaterialList.typeID
		return self
	end,
	methodContinue = {
		read = function(self,readStream)
			--Read Material List Struct
			self.struct = MaterialListStruct()
			self.struct.parent = self
			self.struct:read(readStream)
			--Read Materials
			self.materials = {}
			for matIndex=1,self.struct.materialCount do
				--print("Reading Material",matIndex,readStream.readingPos)
				self.materials[matIndex] = Material()
				self.materials[matIndex].parent = self
				self.materials[matIndex]:read(readStream)
			end
		end,
		write = function(self,writeStream)
			self.struct.materialCount = #self.materials
			self.struct:write(writeStream)
			for matIndex=1,#self.materials do
				self.materials[matIndex]:write(writeStream)
			end
		end,
		getSize = function(self)
			local size = self.struct:getSize()
			for matIndex=1,#self.materials do
				size = size+self.materials[matIndex]:getSize()
			end
			self.size = size
			return size
		end,
		convert = function(self,targetVersion)
			self.struct:convert(targetVersion)
			for matIndex=1,#self.materials do
				self.materials[matIndex]:convert(targetVersion)
			end
		end,
	},
	findMaterialByTexName = function(self,texName)
		for i=1,#self.materials do
			if self.materials[i].texture then
				if self.materials[i].texture.textureName.string == texName then
					return i
				end
			end
		end
		return false
	end,
	findMaterialByMaskName = function(self,maskName)
		for i=1,#self.materials do
			if self.materials[i].texture then
				if self.materials[i].texture.maskName.string == maskName then
					return i
				end
			end
		end
		return false
	end,
	findMaterialByColor = function(self,r,g,b,a)
		for i=1,#self.materials do
			local color = self.materials[i].struct.color
			if color[1] == r and color[2] == g and color[3] == b and color[4] == a then
				return i
			end
		end
		return false
	end,
}

class "MaterialStruct" {
	extend = "Struct",
	flags = false,
	color = false,
	unused = false,
	isTextured = false,
	ambient = false,
	specular = false,
	diffuse = false,
	init = function(self,version)
		self.flags = 0
		self.color = {255,255,255,255}
		self.unused = 0
		self.isTextured = 0
		self.ambient = 1
		self.specular = 1
		self.diffuse = 1
		self.size = self:getSize(true)
		self.version = version
		self.type = MaterialStruct.typeID
		return self
	end,
	methodContinue = {
		read = function(self,readStream)
			self.flags = readStream:read(uint32)
			self.color = {readStream:read(uint8),readStream:read(uint8),readStream:read(uint8),readStream:read(uint8)}
			self.unused = readStream:read(uint32)
			self.isTextured = readStream:read(uint32) == 1
			self.ambient = readStream:read(float)
			self.specular = readStream:read(float)
			self.diffuse = readStream:read(float)
		end,
		write = function(self,writeStream)
			writeStream:write(self.flags,uint32)
			writeStream:write(self.color[1],uint8)
			writeStream:write(self.color[2],uint8)
			writeStream:write(self.color[3],uint8)
			writeStream:write(self.color[4],uint8)
			writeStream:write(self.unused,uint32)
			writeStream:write(self.isTextured and 1 or 0,uint32)
			writeStream:write(self.ambient,float)
			writeStream:write(self.specular,float)
			writeStream:write(self.diffuse,float)
		end,
		getSize = function(self)
			local size = 28 -- 4+1*4+4+4+4*3
			self.size = size
			return size
		end,
	}
}

class "MaterialExtension" {
	extend = "Extension",
	materialEffect = false,
	reflectionMaterial = false,
	specularMaterial = false,
	uvAnimation = false,
	init = function(self,version)
		self.size = self:getSize(true)
		self.version = version
		self.type = MaterialExtension.typeID
		return self
	end,
	methodContinue = {
		read = function(self,readStream)
			--Custom Section: Reflection Material
			local readSize = 0
			while self.size > readSize do
				local section = Section()
				section.parent = self
				section:read(readStream)
				if section.type == ReflectionMaterial.typeID then
					recastClass(section,ReflectionMaterial)
					self.reflectionMaterial = section
					section:read(readStream)
				elseif section.type == SpecularMaterial.typeID then
					recastClass(section,SpecularMaterial)
					self.specularMaterial = section
					section:read(readStream)
				elseif section.type == MaterialEffectPLG.typeID then
					recastClass(section,MaterialEffectPLG)
					self.materialEffect = section
					section:read(readStream)
				elseif section.type == UVAnimPLG.typeID then
					recastClass(section,UVAnimPLG)
					self.uvAnimation = section
					section:read(readStream)
				end
				readSize = readSize+section.size+12
			end
		end,
		write = function(self,writeStream)
			if self.reflectionMaterial then
				self.reflectionMaterial:write(writeStream)
			end
			if self.specularMaterial then
				self.specularMaterial:write(writeStream)
			end
			if self.materialEffect then
				self.materialEffect:write(writeStream)
			end
		end,
		getSize = function(self)
			local size = 0
			if self.reflectionMaterial then
				size = size+self.reflectionMaterial:getSize()
			end
			if self.specularMaterial then
				size = size+self.specularMaterial:getSize()
			end
			if self.materialEffect then
				size = size+self.materialEffect:getSize()
			end
			self.size = size
			return size
		end,
		convert = function(self,targetVersion)
			if self.reflectionMaterial then
				self.reflectionMaterial:convert(targetVersion)
			end
			if self.specularMaterial then
				self.specularMaterial:convert(targetVersion)
			end
			if self.materialEffect then
				self.materialEffect:convert(targetVersion)
			end
		end,
	}
}

class "Material" {	typeID = 0x07,
	extend = "Section",
	struct = false,
	texture = false,
	extension = false,
	init = function(self,ver)
		self.struct = MaterialStruct():init(version)
		self.struct.parent = self
		self.extension = MaterialExtension():init(version)
		self.extension.parent = self
		self.size = self:getSize(true)
		self.version = version
		self.type = Material.typeID
	end,
	methodContinue = {
		read = function(self,readStream)
			--Read Material Struct
			self.struct = MaterialStruct()
			self.struct.parent = self
			self.struct:read(readStream)
			if self.struct.isTextured then
				--Read Texture
				self.texture = Texture()
				self.texture.parent = self
				self.texture:read(readStream)
			end
			--Read Extension
			self.extension = MaterialExtension()
			self.extension.parent = self
			self.extension:read(readStream)
		end,
		write = function(self,writeStream)
			self.struct:write(writeStream)
			if self.struct.isTextured then
				self.texture:write(writeStream)
			end
			self.extension:write(writeStream)
		end,
		getSize = function(self)
			local size = self.struct:getSize()+(self.struct.isTextured and self.texture:getSize() or 0)+self.extension:getSize()
			self.size = size
			return size
		end,
		convert = function(self,targetVersion)
			self.struct:convert(targetVersion)
			if self.struct.isTextured then
				self.texture:convert(targetVersion)
			end
			self.extension:convert(targetVersion)
		end,
	}
}

class "ReflectionMaterial" {	typeID = 0x0253F2FC,
	extend = "Section",
	envMapScaleX = false,
	envMapScaleY = false,
	envMapOffsetX = false,
	envMapOffsetY = false,
	reflectionIntensity = false,
	envTexturePtr = false,
	methodContinue = {
		read = function(self,readStream)
			self.envMapScaleX = readStream:read(float)
			self.envMapScaleY = readStream:read(float)
			self.envMapOffsetX = readStream:read(float)
			self.envMapOffsetY = readStream:read(float)
			self.reflectionIntensity = readStream:read(float)
			self.envTexturePtr = readStream:read(uint32)
		end,
		write = function(self,writeStream)
			writeStream:write(self.envMapScaleX,float)
			writeStream:write(self.envMapScaleY,float)
			writeStream:write(self.envMapOffsetX,float)
			writeStream:write(self.envMapOffsetY,float)
			writeStream:write(self.reflectionIntensity,float)
			writeStream:write(self.envTexturePtr,uint32)
		end,
		getSize = function(self)
			local size = 24
			self.size = size
			return size
		end,
	}
}

class "SpecularMaterial" {	typeID = 0x0253F2F6,
	extend = "Section",
	specularLevel = false,
	textureName = false,
	methodContinue = {
		read = function(self,readStream)
			self.specularLevel = readStream:read(float)
			self.textureName = readStream:read(char,24)
		end,
		write = function(self,writeStream)
			writeStream:write(self.specularLevel,float)
			writeStream:write(self.textureName,char,24)
		end,
		getSize = function(self)
			local size = 28
			self.size = size
			return size
		end,
	}
}

class "TextureStruct" {
	extend = "Struct",
	flags = false,
	--Casted From Flags (Read Only)
	filter = false,
	UAddressing = false,
	VAddressing = false,
	hasMipmaps = false,
	--
	init = function(self,ver)
		self.flags = 0
		self.size = self:getSize(true)
		self.version = version
		self.type = TextureStruct.typeID
	end,
	methodContinue = {
		read = function(self,readStream)
			self.flags = readStream:read(uint32)
			--Casted From Flags (Read Only)
			self.filter = bExtract(self.flags,24,8)
			self.UAddressing = bExtract(self.flags,24,4)
			self.VAddressing = bExtract(self.flags,20,4)
			self.hasMipmaps = bExtract(self.flags,19) == 1
			--
		end,
		write = function(self,writeStream)
			writeStream:write(self.flags,uint32)
		end,
		getSize = function(self)
			local size = 4
			self.size = size
			return size
		end,
	}
}

class "Texture" {	typeID = 0x06,
	extend = "Section",
	struct = false,
	textureName = false,
	maskName = false,
	extension = false,
	init = function(self,ver)
		self.struct = TextureStruct():init(version)
		self.struct.parent = self
		self.textureName = String():init(version)
		self.textureName.parent = self
		self.maskName = String():init(version)
		self.maskName.parent = self
		self.extension = Extension():init(version)
		self.extension.parent = self
		self.size = self:getSize(true)
		self.version = version
		self.type = Texture.typeID
	end,
	methodContinue = {
		read = function(self,readStream)
			--Read Texture Struct
			self.struct = TextureStruct()
			self.struct.parent = self
			self.struct:read(readStream)
			--Read Texture Name
			self.textureName = String()
			self.textureName.parent = self
			self.textureName:read(readStream)
			--Read Mask Name
			self.maskName = String()
			self.maskName.parent = self
			self.maskName:read(readStream)
			--Read Extension
			self.extension = Extension()
			self.extension.parent = self
			self.extension:read(readStream)
		end,
		write = function(self,writeStream)
			self.struct:write(writeStream)
			self.textureName:write(writeStream)
			self.maskName:write(writeStream)
			self.extension:write(writeStream)
		end,
		getSize = function(self)
			local size = self.struct:getSize()+self.textureName:getSize()+self.maskName:getSize()+self.extension:getSize()
			self.size = size
			return size
		end,
		convert = function(self,targetVersion)
			self.struct:convert(targetVersion)
			self.textureName:convert(targetVersion)
			self.maskName:convert(targetVersion)
			self.extension:convert(targetVersion)
		end,
	}
}

class "String" {	typeID = 0x02,
	extend = "Section",
	string = false,
	init = function(self,ver)
		self.string = ""
		self.size = self:getSize(true)
		self.version = version
		self.type = String.typeID
	end,
	methodContinue = {
		read = function(self,readStream)
			self.string = readStream:read(char,self.size)
		end,
		write = function(self,writeStream)
			local diff = self.size-#self.string --Diff
			writeStream:write(self.string,bytes,#self.string)
			writeStream:write(string.rep("\0",diff),bytes,diff)
		end,
		getSize = function(self)
			return self.size
		end,
	}
}

class "MorphPLG" {	typeID = 0x105,
	extend = "Section",
	unused = false,
	init = function(self,ver)
		self.unused = 0
		self.size = self:getSize(true)
		self.version = version
		self.type = MorphPLG.typeID
	end,
	methodContinue = {
		read = function(self,readStream)
			self.unused = readStream:read(uint32)
		end,
		write = function(self,writeStream)
			writeStream:write(self.unused,uint32)
		end,
		getSize = function(self)
			local size = 4
			self.size = size
			return size
		end,
	}
}

class "BinMeshPLG" {	typeID = 0x50E,
	extend = "Section",
	faceType = false,
	materialSplitCount = false,
	vertexCount = false,
	materialSplits = false,
	methodContinue = {
		read = function(self,readStream)
			self.faceType = readStream:read(uint32)
			self.materialSplitCount = readStream:read(uint32)
			self.vertexCount = readStream:read(uint32)
			self.materialSplits = {}
			for i=1,self.materialSplitCount do
				--Faces, MaterialIndex, FaceList
				self.materialSplits[i] = {readStream:read(uint32),readStream:read(uint32),{}}
				for faceIndex=1, self.materialSplits[i][1] do
					self.materialSplits[i][3][faceIndex] = readStream:read(uint32)	--Face Index
				end
			end
		end,
		write = function(self,writeStream)
			writeStream:write(self.faceType,uint32)
			self.materialSplitCount = #self.materialSplits
			writeStream:write(self.materialSplitCount,uint32)
			local vertexCount = 0
			for i=1,self.materialSplitCount do
				vertexCount = vertexCount+#self.materialSplits[i][3]
			end
			self.vertexCount = vertexCount
			writeStream:write(self.vertexCount,uint32)
			for i=1,self.materialSplitCount do
				--Faces, MaterialIndex
				self.materialSplits[i][1] = #self.materialSplits[i][3]
				writeStream:write(self.materialSplits[i][1],uint32)
				writeStream:write(self.materialSplits[i][2],uint32)
				for faceIndex=1,self.materialSplits[i][1] do
					writeStream:write(self.materialSplits[i][3][faceIndex],uint32)	--Face Index
				end
			end
		end,
		getSize = function(self)
			local size = 4*3
			for i=1,self.materialSplitCount do
				size = size+8+self.materialSplits[i][1]*4
			end
			self.size = size
			return size
		end,
	}
}

class "Breakable" {	typeID = 0x0253F2FD,
	extend = "Section",
	flags = false,
	positionRule = false,
	vertexCount = false,
	offsetVerteices = false,		--Unused
	offsetCoords = false,			--Unused
	offsetVetrexColor = false,		--Unused
	faceCount = false,
	offsetVertexIndices = false,	--Unused
	offsetMaterialIndices = false,	--Unused
	materialCount = false,
	offsetTextures = false,			--Unused
	offsetTextureNames = false,		--Unused
	offsetTextureMasks = false,		--Unused
	offsetAmbientColors = false,	--Unused
	
	vertices = false,
	faces = false,
	texCoords = false,
	vertexColors = false,
	faceMaterials = false,
	materialTextureNames = false,
	materialTextureMasks = false,
	materialAmbientColor = false,

	methodContinue = {
		read = function(self,readStream)
			self.flags = readStream:read(uint32)
			if self.flags ~= 0 then
				self.positionRule = readStream:read(uint32)
				self.vertexCount = readStream:read(uint32)
				self.offsetVerteices = readStream:read(uint32)			--Unused
				self.offsetCoords = readStream:read(uint32)				--Unused
				self.offsetVetrexLight = readStream:read(uint32)		--Unused
				self.faceCount = readStream:read(uint32)
				self.offsetVertexIndices = readStream:read(uint32)		--Unused
				self.offsetMaterialIndices = readStream:read(uint32)	--Unused
				self.materialCount = readStream:read(uint32)
				self.offsetTextures = readStream:read(uint32)			--Unused
				self.offsetTextureNames = readStream:read(uint32)		--Unused
				self.offsetTextureMasks = readStream:read(uint32)		--Unused
				self.offsetAmbientColors = readStream:read(uint32)		--Unused
				
				self.vertices = {}
				for i=1,self.vertexCount do
					--x,y,z
					self.vertices[i] = {readStream:read(float),readStream:read(float),readStream:read(float)}
				end
				self.texCoords = {}
				for i=1,self.vertexCount do
					--u,v
					self.texCoords[i] = {readStream:read(float),readStream:read(float)}
				end
				self.vertexColors = {}
				for i=1,self.vertexCount do
					--r,g,b,a
					self.vertexColors[i] = {readStream:read(uint8),readStream:read(uint8),readStream:read(uint8),readStream:read(uint8)}
				end
				self.faces = {}
				for i=1,self.faceCount do
					self.faces[i] = {readStream:read(uint16),readStream:read(uint16),readStream:read(uint16)}
				end
				self.tiangleMaterials = {}
				for i=1,self.faceCount do
					self.tiangleMaterials[i] = readStream:read(uint16)
				end
				self.materialTextureNames = {}
				for i=1,self.materialCount do
					self.materialTextureNames[i] = readStream:read(char,32)
				end
				self.materialTextureMasks = {}
				for i=1,self.materialCount do
					self.materialTextureMasks[i] = readStream:read(char,32)
				end
				self.ambientColor = {}
				for i=1,self.materialCount do
					self.ambientColor[i] = {readStream:read(float),readStream:read(float),readStream:read(float)}
				end
			end
		end,
		write = function(self,writeStream)
			writeStream:write(self.flags,uint32)
			if self.flags ~= 0 then
				writeStream:write(self.positionRule,uint32)
				writeStream:write(self.vertexCount,uint32)
				writeStream:write(self.offsetVerteices,uint32)
				writeStream:write(self.offsetCoords,uint32)
				writeStream:write(self.offsetVetrexLight,uint32)
				writeStream:write(self.faceCount,uint32)
				writeStream:write(self.offsetVertexIndices,uint32)
				writeStream:write(self.offsetMaterialIndices,uint32)
				writeStream:write(self.materialCount,uint32)
				writeStream:write(self.offsetTextures,uint32)
				writeStream:write(self.offsetTextureNames,uint32)
				writeStream:write(self.offsetTextureMasks,uint32)
				writeStream:write(self.offsetAmbientColors,uint32)
				
				for i=1,self.vertexCount do
					--x,y,z
					writeStream:write(self.vertices[i][1],float)
					writeStream:write(self.vertices[i][2],float)
					writeStream:write(self.vertices[i][3],float)
				end
				for i=1,self.vertexCount do
					--u,v
					writeStream:write(self.texCoords[i][1],float)
					writeStream:write(self.texCoords[i][2],float)
				end
				for i=1,self.vertexCount do
					--r,g,b,a
					writeStream:write(self.vertexColors[i][1],uint8)
					writeStream:write(self.vertexColors[i][2],uint8)
					writeStream:write(self.vertexColors[i][3],uint8)
					writeStream:write(self.vertexColors[i][4],uint8)
				end
				for i=1,self.faceCount do
					writeStream:write(self.faces[i][1],uint16)
					writeStream:write(self.faces[i][2],uint16)
					writeStream:write(self.faces[i][3],uint16)
				end
				for i=1,self.faceCount do
					writeStream:write(self.tiangleMaterials[i],uint16)
				end
				for i=1,self.materialCount do
					writeStream:write(self.materialTextureNames[i],char,32)
				end
				for i=1,self.materialCount do
					writeStream:write(self.materialTextureMasks[i],char,32)
				end
				for i=1,self.materialCount do	--Normalized to [0,1]
					writeStream:write(self.ambientColor[i][1],float)
					writeStream:write(self.ambientColor[i][2],float)
					writeStream:write(self.ambientColor[i][3],float)
				end
			end
		end,
		getSize = function(self)
			local size = 0
			if self.flags == 0 then
				size = 4
			else
				size = 14*4+self.vertexCount*8*4+self.materialCount*32*2+self.materialCount*3*4
			end
			self.size = size
			return size
		end,
	}
}

class "AtomicStruct" {
	extend = "Struct",
	frameIndex = false,			-- Index of the frame within the clump's frame list.
	geometryIndex = false,		-- Index of the geometry within the clump's frame list.
	flags = false,				-- Flags
	unused = false,				-- Unused
	--Casted From flags
	atomicCollisionTest = false,	--Unused
	atomicRender = false,			--The atomic is rendered if it is in the view frustum. It's set to TRUE for all models by default.
	--
	init = function(self,version)
		self.frameIndex = 0
		self.geometryIndex = 0
		self.flags = 5
		self.unused = 0
		self.size = self:getSize(true)
		self.version = version
		self.type = AtomicStruct.typeID
		return self
	end,
	methodContinue = {
		read = function(self,readStream)
			self.frameIndex = readStream:read(uint32)
			self.geometryIndex = readStream:read(uint32)
			self.flags = readStream:read(uint32)
			self.unused = readStream:read(uint32)
		end,
		write = function(self,writeStream)
			writeStream:write(self.frameIndex,uint32)
			writeStream:write(self.geometryIndex,uint32)
			writeStream:write(self.flags,uint32)
			writeStream:write(self.unused,uint32)
		end,
		getSize = function(self)
			local size = 16
			self.size = size
			return size
		end,
	}
}

class "AtomicExtension" {
	extend = "Extension",
	pipline = false,
	materialEffect = false,
	init = function(self,version)
		self.size = self:getSize(true)
		self.version = version
		self.type = AtomicExtension.typeID
		return self
	end,
	methodContinue = {
		read = function(self,readStream)
			local nextSection
			local readSize = 0
			if self.size ~= 0 then
				repeat
					nextSection = Section()
					nextSection.parent = self
					nextSection:read(readStream)
					if nextSection.type == Pipline.typeID then
						recastClass(nextSection,Pipline)
						self.pipline = nextSection
					elseif nextSection.type == MaterialEffectPLG.typeID then
						recastClass(nextSection,MaterialEffectPLG)
						self.materialEffect = nextSection
					else
						error("Unsupported Automic Plugin "..nextSection.type)
					end
					nextSection.parent = self
					nextSection:read(readStream)
					readSize = readSize+nextSection.size+12
				until readSize >= self.size
			end
		end,
		write = function(self,writeStream)
			if self.pipline then
				self.pipline:write(writeStream)
			end
			if self.materialEffect then
				self.materialEffect:write(writeStream)
			end
		end,
		getSize = function(self)
			local size = 0
			if self.pipline then
				size = size+self.pipline:getSize()
			end
			if self.materialEffect then
				size = size+self.materialEffect:getSize()
			end
			self.size = size
			return size
		end,
		convert = function(self,targetVersion)
			if self.pipline then
				self.pipline:convert(targetVersion)
			end
			if self.materialEffect then
				self.materialEffect:convert(targetVersion)
			end
		end,
	}
}

class "Atomic" {	typeID = 0x14,
	extend = "Section",
	struct = false,
	extension = false,
	init = function(self,version)
		self.struct = AtomicStruct():init(version)
		self.struct.parent = self
		self.extension = AtomicExtension():init(version)
		self.extension.parent = self
		self.size = self:getSize(true)
		self.version = version
		self.type = Atomic.typeID
		return self
	end,
	methodContinue = {
		read = function(self,readStream)
			self.struct = AtomicStruct()
			self.struct.parent = self
			self.struct:read(readStream)
			self.extension = AtomicExtension()
			self.extension.parent = self
			self.extension:read(readStream)
		end,
		write = function(self,writeStream)
			self.struct:write(writeStream)
			self.extension:write(writeStream)
		end,
		getSize = function(self)
			local size = self.struct:getSize()+self.extension:getSize()
			self.size = size
			return size
		end,
		convert = function(self,targetVersion)
			self.struct:convert(targetVersion)
			self.extension:convert(targetVersion)
		end,
	}
}

class "Pipline" {	typeID = 0x1F,	--Right To Render
	extend = "Section",
	pluginIdentifier = false,
	extraData = false,
	methodContinue = {
		read = function(self,readStream)
			self.pluginIdentifier = readStream:read(uint32)
			self.extraData = readStream:read(uint32)
		end,
		write = function(self,writeStream)
			writeStream:write(self.pluginIdentifier,uint32)
			writeStream:write(self.extraData,uint32)
		end,
		getSize = function(self)
			local size = 8
			self.size = size
			return size
		end,
	}
}

class "MaterialEffectPLG" {	typeID = 0x120,
	extend = "Section",
	effectType = false,
	
	--0x02
	texture = false,
	unused = false,
	reflectionCoefficient = false,
	useFrameBufferAlphaChannel = false,
	useEnvMap = false,
	endPadding = false,
	--0x05
	unused = false,
	endPadding = false,
	
	methodContinue = {
		read = function(self,readStream)
			self.effectType = readStream:read(uint32)
			if self.effectType == 0x00 or self.effectType == 0x01 then
				--Nothing
			elseif self.effectType == 0x02 then
				self.unused = readStream:read(uint32)
				self.reflectionCoefficient = readStream:read(float)
				self.useFrameBufferAlphaChannel = readStream:read(uint32) == 1
				self.useEnvMap = readStream:read(uint32) == 1
				if self.useEnvMap then
					self.texture = Texture()
					self.texture.parent = self
					self.texture:read(readStream)
				end
				self.endPadding = readStream:read(uint32)
			elseif self.effectType == 0x05 then
				self.unused = readStream:read(uint32)
				self.endPadding = readStream:read(uint32)
			else
				print("Bad effectType @MaterialEffectPLG, effect ID "..self.effectType.." is not implemented")
			end
		end,
		write = function(self,writeStream)
			writeStream:write(self.effectType,uint32)
			if self.effectType == 0x00 or self.effectType == 0x01 then
				--Nothing
			elseif self.effectType == 0x02 then
				writeStream:write(self.unused,uint32)
				writeStream:write(self.reflectionCoefficient,float)
				writeStream:write(self.useFrameBufferAlphaChannel and 1 or 0,uint32)
				writeStream:write(self.useEnvMap and 1 or 0,uint32)
				if self.useEnvMap then
					self.texture:write(writeStream)
				end
				writeStream:write(self.endPadding,uint32)
			elseif self.effectType == 0x05 then
				writeStream:write(self.unused,uint32)
				writeStream:write(self.endPadding,uint32)
			else
				print("Bad effectType @MaterialEffectPLG, effect ID "..self.effectType.." is not implemented")
			end
		end,
		getSize = function(self)
			local size = 4
			if self.effectType == 0x00 or self.effectType == 0x01 then
				--Nothing
			elseif self.effectType == 0x02 then
				size = size+4*5+(self.useEnvMap and self.texture:getSize() or 0)+4
			elseif self.effectType == 0x05 then
				size = size+8+4
			end
			self.size = size
			return size
		end,
		convert = function(self,targetVersion)
			if self.useEnvMap then
				self.texture:convert(targetVersion)
			end
		end,
	}
}

class "UVAnimPLGStruct" {
	extend = "Struct",
	unused = false,
	name = false,
	methodContinue = {
		read = function(self,readStream)
			self.unused = readStream:read(uint32)
			self.name = readStream:read(char,32)
		end,
		write = function(self,writeStream)
			writeStream:write(self.unused,uint32)
			writeStream:write(self.name,char,32)
		end,
		getSize = function(self)
			local size = 36
			self.size = size
			return size
		end,
	}
}

class "UVAnimPLG" {	typeID = 0x135,
	extend = "Section",
	struct = false,
	methodContinue = {
		read = function(self,readStream)
			self.struct = UVAnimPLGStruct()
			self.struct.parent = self
			self.struct:read(readStream)
		end,
		write = function(self,writeStream)
			self.struct:write(writeStream)
		end,
		getSize = function(self)
			local size = self.struct:getSize()
			self.size = size
			return size
		end,
		convert = function(self,targetVersion)
			self.struct:convert(targetVersion)
		end,
	}
}

class "HAnimPLG" {	typeID = 0x11E,
	extend = "Section",
	animVersion = 0x100,	--By Default
	nodeID = false,
	nodeCount = false,
	flags = false,
	keyFrameSize = 36,		--By Default
	nodes = false,
	methodContinue = {
		read = function(self,readStream)
			self.animVersion = readStream:read(uint32)
			self.nodeID = readStream:read(uint32)
			self.nodeCount = readStream:read(uint32)
			if self.nodeCount ~= 0 then	--Root Bone
				self.flags = readStream:read(uint32)
				self.keyFrameSize = readStream:read(uint32)
				self.nodes = {}
				for i=1,self.nodeCount do
					self.nodes[i] = {
						nodeID = readStream:read(uint32),		--Identify
						nodeIndex = readStream:read(uint32),	--Index in array
						flags = readStream:read(uint32),
					}
				end
			end
		end,
		write = function(self,writeStream)
			writeStream:write(self.animVersion,uint32)
			writeStream:write(self.nodeID,uint32)
			writeStream:write(self.nodeCount,uint32)
			if self.nodeCount ~= 0 then	--Root Bone
				writeStream:write(self.flags,uint32)
				writeStream:write(self.keyFrameSize,uint32)
				for i=1,self.nodeCount do
					writeStream:write(self.nodes[i].nodeID,uint32)
					writeStream:write(self.nodes[i].nodeIndex,uint32)
					writeStream:write(self.nodes[i].flags,uint32)
				end
			end
		end,
		getSize = function(self)
			local size = 3*4
			if self.nodeCount ~= 0 then	--Root Bone
				size = size+8+self.nodeCount*4
			end
			self.size = size
			return size
		end,
	}
}

class "SkinPLG" {	typeID = 0x116,
	extend = "Section",
	boneCount = false,
	usedBoneCount = false,
	maxVertexWeights = false,
	usedBoneIndice = false,
	boneVertices = false,
	boneVertexWeights = false,
	bones = false,
	methodContinue = {
		read = function(self,readStream)
			self.boneCount = readStream:read(uint8)
			self.usedBoneCount = readStream:read(uint8)
			self.maxVertexWeights = readStream:read(uint8)
			readStream:read(uint8)	--Padding
			self.usedBoneIndice = {}
			for i=1,self.usedBoneCount do
				self.usedBoneIndice[i] = readStream:read(uint8)
			end
			self.boneVertices = {}
			for i=1,self.parent.parent.struct.vertexCount do
				self.boneVertices[i] = {readStream:read(uint8),readStream:read(uint8),readStream:read(uint8),readStream:read(uint8)}
				
			end
			self.boneVertexWeights = {}
			for i=1,self.parent.parent.struct.vertexCount do
				self.boneVertexWeights[i] = {readStream:read(float),readStream:read(float),readStream:read(float),readStream:read(float)}
			
			end
			self.bones = {}
			for i=1,self.boneCount do
				if self.version ~= EnumRWVersion.GTASA then
					readStream:read(uint32)
				end
				self.bones[i] = {
					{readStream:read(float),readStream:read(float),readStream:read(float),readStream:read(float)},
					{readStream:read(float),readStream:read(float),readStream:read(float),readStream:read(float)},
					{readStream:read(float),readStream:read(float),readStream:read(float),readStream:read(float)},
					{readStream:read(float),readStream:read(float),readStream:read(float),readStream:read(float)},
				}
			end
			if self.version == EnumRWVersion.GTASA then
				readStream:read(uint32)	--unused
				readStream:read(uint32)	--unused
				readStream:read(uint32)	--unused
			end
		end,
		write = function(self,writeStream)
			writeStream:write(self.boneCount,uint8)
			writeStream:write(self.usedBoneCount,uint8)
			writeStream:write(self.maxVertexWeights,uint8)
			writeStream:write(0,uint8)	--Padding
			for i=1,self.usedBoneCount do
				writeStream:write(self.usedBoneIndice[i],uint8)
			end
			for i=1,self.parent.parent.struct.vertexCount do
				writeStream:write(self.boneVertices[i][1],uint8)
				writeStream:write(self.boneVertices[i][2],uint8)
				writeStream:write(self.boneVertices[i][3],uint8)
				writeStream:write(self.boneVertices[i][4],uint8)
				
			end
			for i=1,self.parent.parent.struct.vertexCount do
				writeStream:write(self.boneVertexWeights[i][1],float)
				writeStream:write(self.boneVertexWeights[i][2],float)
				writeStream:write(self.boneVertexWeights[i][3],float)
				writeStream:write(self.boneVertexWeights[i][4],float)
			end
			for i=1,self.boneCount do
				if self.version ~= EnumRWVersion.GTASA then
					writeStream:write(0xDEADDEAD,uint32)
				end
				local boneTransform = self.bones[i]
				writeStream:write(boneTransform[1][1],float)
				writeStream:write(boneTransform[1][2],float)
				writeStream:write(boneTransform[1][3],float)
				writeStream:write(boneTransform[1][4],float)
				writeStream:write(boneTransform[2][1],float)
				writeStream:write(boneTransform[2][2],float)
				writeStream:write(boneTransform[2][3],float)
				writeStream:write(boneTransform[2][4],float)
				writeStream:write(boneTransform[3][1],float)
				writeStream:write(boneTransform[3][2],float)
				writeStream:write(boneTransform[3][3],float)
				writeStream:write(boneTransform[3][4],float)
				writeStream:write(boneTransform[4][1],float)
				writeStream:write(boneTransform[4][2],float)
				writeStream:write(boneTransform[4][3],float)
				writeStream:write(boneTransform[4][4],float)
			end
			if self.version == EnumRWVersion.GTASA then
				writeStream:write(0,uint32)	--unused
				writeStream:write(0,uint32)	--unused
				writeStream:write(0,uint32)	--unused
			end
		end,
		getSize = function(self)
			local size = 4+self.usedBoneCount+self.parent.parent.struct.vertexCount*5
			if size.version == EnumRWVersion.GTASA then
				size = size+self.boneCount*16*4+3*4
			else
				size = size+self.boneCount*17*4
			end
			self.size = size
			return size
		end,
	}
}

class "COLSection" {	typeID = 0x253F2FA,
	extend = "Section",
	collisionRaw = false,
	methodContinue = {
		read = function(self,readStream)
			self.collisionRaw = readStream:read(bytes,self.size)
		end,
		write = function(self,writeStream)
			writeStream:write(self.collisionRaw,bytes,#self.collisionRaw)
		end,
		getSize = function(self)
			local size = #self.collisionRaw
			self.size = size
			return size
		end,
	}
}

class "DFFIO" {
	uvAnimDict = false,
	clumps = false,
	readStream = false,
	writeStream = false,
	version = false,
	load = function(self,pathOrRaw)
		if fileExists(pathOrRaw) then
			local f = fileOpen(pathOrRaw)
			if f then
				pathOrRaw = fileRead(f,fileGetSize(f))
				fileClose(f)
			end
		end
		self.readStream = ReadStream(pathOrRaw)
		self.clumps = {}
		while self.readStream.readingPos+12 < #pathOrRaw do
			local nextSection = Section()
			nextSection.parent = self
			nextSection:read(self.readStream)
			self.version = nextSection.version
			if nextSection.type == UVAnimDict.typeID then
				recastClass(nextSection,UVAnimDict)
				self.uvAnimDict = nextSection
				nextSection:read(self.readStream)
			elseif nextSection.type == Clump.typeID then
				recastClass(nextSection,Clump)
				self.clumps[#self.clumps+1] = nextSection
				nextSection:read(self.readStream)
			else
				break	--Read End
			end
		end
	end,
	createClump = function(self,version)
		self.clumps[#self.clumps+1] = Clump()
		self.clumps[#self.clumps+1].parent = self
		self.clumps[#self.clumps+1]:init(version or EnumRWVersion.GTASA)
	end,
	save = function(self,fileName)
		self.writeStream = WriteStream()
		self.writeStream.parent = self
		for i=1,#self.clumps do
			self.clumps[i]:write(self.writeStream)
		end
		local str = self.writeStream:save()
		if fileName then
			if fileExists(fileName) then fileDelete(fileName) end
			local f = fileCreate(fileName)
			fileWrite(f,str)
			fileClose(f)
			return true
		end
		return str
	end,
	convert = function(self,target)
		if not type(target) == "string" then error("Bad argument @convert at argument 1, expected a string got "..type(target)) end
		if not EnumRWVersion[target:upper()] then error("Bad argument @convert at argument 1, invalid type "..target) end
		for i=1,#self.clumps do
			self.clumps[i]:convert(EnumRWVersion[target:upper()])
		end
		return true
	end,
	update = function(self)
		for i=1,#self.clumps do
			self.clumps[i]:getSize()
		end
	end,
}
