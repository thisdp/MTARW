class "COLIO" {	
	collision = nil,
	readStream = nil,
	writeStream = nil,
	load = function(self,pathOrRaw)
		if fileExists(pathOrRaw) then
			local f = fileOpen(pathOrRaw)
			if f then
				pathOrRaw = fileRead(f,fileGetSize(f))
				fileClose(f)
			end
		end
		self.readStream = ReadStream(pathOrRaw)
		self.collision = Collision()
		self.collision:read(self.readStream)
	end,
	save = function(self,fileName)
		if fileExists(fileName) then fileDelete(fileName) end
		self.writeStream = WriteStream()
		self.collision:write(self.writeStream)
		local f = fileCreate(fileName)
		fileWrite(f,self.writeStream:save())
		fileClose(f)
	end,
	getSize = function(self)
		
	end,
}

class "Collision" {	--Only support COL1/2/3
	version = nil,	--FourCC ( COLL/COL2/COL3 )
	size = nil,
	modelName = nil,
	modelID = nil,
	bound = nil,
	vertexCount = nil,
	sphereCount = nil,
	boxCount = nil,
	faceGroupCount = nil,
	faceCount = nil,
	lineCount = nil,	--Unused
	trianglePlaneCount = nil,	--Unused
	flags = nil,
	offsetSphere = nil,
	offsetBox = nil,
	offsetLine = nil,	--Unused
	offsetFaceGroup = nil,
	offsetVertex = nil,
	offsetFace = nil,
	offsetTrianglePlane = nil,	--Unused
	--Casted From flags
	useConeInsteadOfLine = nil,
	notEmpty = nil,
	hasFaceGroup = nil,
	hasShadow = nil,
	--
	--Collision Version >= 3
	shadowFaceCount = nil,
	shadowVertexCount = nil,
	offsetShadowVertex = nil,
	offsetShadowFace = nil,
	--
	spheres = nil,
	boxes = nil,
	vertices = nil,
	faces = nil,
	faceGroups = nil,
	shadowFaces = nil,
	shadowVertices = nil,
	read = function(self,readStream)
		self.version = readStream:read(char,4)
		self.size = readStream:read(uint32)
		self.modelName = readStream:read(char,22)
		self.modelID = readStream:read(uint16)		--If not match, model name will be used
		self.bound = TBounds()
		self.bound:read(readStream,self.version)
		if self.version == "COL2" or self.version == "COL3" then
			self.sphereCount = readStream:read(uint16)
			self.boxCount = readStream:read(uint16)
			self.faceCount = readStream:read(uint16)
			self.lineCount = readStream:read(uint8)	--Unused
			self.trianglePlaneCount = readStream:read(uint8)	--Unused
			self.flags = readStream:read(uint32)
			--Casted From flags
			self.useConeInsteadOfLine = bExtract(self.flags,0) == 1
			self.notEmpty = bExtract(self.flags,1) == 1
			self.hasFaceGroup = bExtract(self.flags,3) == 1
			self.hasShadow = bExtract(self.flags,4) == 1
			--
			self.offsetSphere = readStream:read(uint32)
			self.offsetBox = readStream:read(uint32)
			self.offsetLine = readStream:read(uint32)	--Unused
			self.offsetVertex = readStream:read(uint32)
			self.offsetFace = readStream:read(uint32)
			self.offsetTrianglePlane = readStream:read(uint32)	--Unused
			if self.version == "COL3" then
				self.shadowFaceCount = readStream:read(uint32)
				self.offsetShadowVertex = readStream:read(uint32)
				self.offsetShadowFace = readStream:read(uint32)
			end
			
			--Read Spheres
			readStream.readingPos = self.offsetSphere+4+1
			self.spheres = {}
			for i=1,self.sphereCount do
				self.spheres[i] = TSphere()
				self.spheres[i]:read(readStream,self.version)
			end
			--Read Boxes
			readStream.readingPos = self.offsetBox+4+1
			self.boxes = {}
			for i=1,self.boxCount do
				self.boxes[i] = TBox()
				self.boxes[i]:read(readStream)
			end
			--Read Faces
			readStream.readingPos = self.offsetFace+4+1
			self.faces = {}
			for i=1,self.faceCount do
				self.faces[i] = TFace()
				self.faces[i]:read(readStream,self.version)
			end
			if self.hasFaceGroup then
				--Read Face Groups
				readStream.readingPos = self.offsetFace+1	--Face Group Count
				self.faceGroupCount = readStream:read(uint32)
				offsetFaceGroup = readStream.readingPos-4-self.faceGroupCount*28
				readStream.readingPos = offsetFaceGroup
				self.faceGroups = {}
				for i=1,self.faceGroupCount do
					self.faceGroups[i] = FaceGroup()
					self.faceGroups[i]:read(readStream,self.version)
				end
			end
			--Read Vertices
			self.vertexCount = ((self.hasFaceGroup and offsetFaceGroup or (self.offsetFace+4))-(self.offsetVertex+4))/6
			self.vertexCount = self.vertexCount-self.vertexCount%1
			self.vertices = {}
			readStream.readingPos = self.offsetVertex+4+1
			for i=1,self.vertexCount do
				self.vertices[i] = TVertex()
				self.vertices[i]:read(readStream,self.version)
			end
			
			if self.hasShadow then
				--Read Shadow Faces
				readStream.readingPos = self.offsetShadowFace+4+1
				self.shadowFaces = {}
				for i=1,self.shadowFaceCount do
					self.shadowFaces[i] = TFace()
					self.shadowFaces[i]:read(readStream,self.version)
				end
				--Read Shadow Vertices
				self.shadowVertexCount = ((self.offsetShadowFace+4)-(self.offsetShadowVertex+4))/6
				self.shadowVertexCount = self.shadowVertexCount-self.shadowVertexCount%1
				self.shadowVertices = {}
				readStream.readingPos = self.offsetShadowVertex+4+1
				for i=1,self.shadowVertexCount do
					self.shadowVertices[i] = TVertex()
					self.shadowVertices[i]:read(readStream,self.version)
				end
			end
		elseif self.version == "COLL" then
			self.sphereCount = readStream:read(uint32)
			self.spheres = {}
			for i=1,self.sphereCount do
				self.spheres[i] = TSphere()
				self.spheres[i]:read(readStream)
			end
			readStream:read(uint32)	--Unused 0
			self.boxCount = readStream:read(uint32)
			self.boxes = {}
			for i=1,self.boxCount do
				self.boxes[i] = TBox()
				self.boxes[i]:read(readStream)
			end
			self.vertexCount = readStream:read(uint32)
			self.vertices = {}
			for i=1,self.vertexCount do
				self.vertices[i] = TVertex()
				self.vertices[i]:read(readStream)
			end
			self.faceCount = readStream:read(uint32)
			self.faces = {}
			for i=1,self.faceCount do
				self.faces[i] = TFace()
				self.faces[i]:read(readStream)
			end
		end
	end,
	write = function(self,writeStream)
		writeStream:write(self.version,char,4)
		local pSize = writeStream:write(self.size,uint32)
		writeStream:write(self.modelName,char,22)
		writeStream:write(self.modelID,uint16)
		self.bound:write(writeStream,self.version)
		if self.version == "COL2" or self.version == "COL3" then
			writeStream:write(self.sphereCount,uint16)
			writeStream:write(self.boxCount,uint16)
			writeStream:write(self.faceCount,uint16)
			writeStream:write(self.lineCount,uint8)	--Unused
			writeStream:write(self.trianglePlaneCount,uint8)	--Unused
			writeStream:write(self.flags,uint32)
			--Maybe rewrite
			local pOffsetSphere,pOffsetBox,pOffsetLine,pOffsetVertex,pOffsetFace,pOffsetTrianglePlane
			pOffsetSphere = writeStream:write(0,uint32)
			pOffsetBox = writeStream:write(0,uint32)
			pOffsetLine = writeStream:write(0,uint32)	--Unused
			pOffsetVertex = writeStream:write(0,uint32)
			pOffsetFace = writeStream:write(0,uint32)
			pOffsetTrianglePlane = writeStream:write(0,uint32)	--Unused
			local pOffsetShadowFace,pOffsetShadowVertex
			if self.version == "COL3" then
				writeStream:write(self.shadowFaceCount,uint32)
				pOffsetShadowVertex = writeStream:write(0,uint32)
				pOffsetShadowFace = writeStream:write(0,uint32)
			end
			--Sphere Start
			--Write Spheres
			if self.sphereCount ~= 0 then
				self.offsetSphere = writeStream.writingPos-4-1
				writeStream:rewrite(pOffsetSphere,self.offsetSphere,uint32)
				for i=1,self.sphereCount do
					self.spheres[i]:write(writeStream,self.version)
				end
			end
			--Write Boxes
			if self.boxCount ~= 0 then
				self.offsetBox = writeStream.writingPos-4-1
				writeStream:rewrite(pOffsetBox,self.offsetBox,uint32)
				for i=1,self.boxCount do
					self.boxes[i]:write(writeStream)
				end
			end
			--Write Vertices
			if self.vertexCount ~= 0 then
				self.offsetVertex = writeStream.writingPos-4-1
				writeStream:rewrite(pOffsetVertex,self.offsetVertex,uint32)
				for i=1,self.vertexCount do
					self.vertices[i]:write(writeStream,self.version)
				end
				if (writeStream.writingPos-self.offsetVertex)%4 ~= 0 then	--For 4Byte Alignment
					writeStream:write(0,uint16)
				end
			end
			if self.hasFaceGroup then
				--Write Face Groups
				for i=1,self.faceGroupCount do
					self.faceGroups[i]:write(writeStream,self.version)
				end
				writeStream:write(self.faceGroupCount,uint32)
			end
			--Write Faces
			if self.faceCount ~= 0 then
				self.offsetFace = writeStream.writingPos-4-1
				writeStream:rewrite(pOffsetFace,self.offsetFace,uint32)
				for i=1,self.faceCount do
					self.faces[i]:write(writeStream,self.version)
				end
			end
			if self.version == "COL3" and self.hasShadow then
				--Write Shadow Vertices
				if self.shadowVertexCount ~= 0 then
					self.offsetShadowVertex = writeStream.writingPos-4-1
					writeStream:rewrite(pOffsetShadowVertex,self.offsetShadowVertex,uint32)
					for i=1,self.shadowVertexCount do
						self.shadowVertices[i]:write(writeStream,self.version)
					end
					if (writeStream.writingPos-self.offsetShadowVertex)%4 ~= 0 then	--For 4Byte Alignment
						writeStream:write(0,uint16)
					end
				end
				--Write Shadow Faces
				if self.shadowFaceCount ~= 0 then
					self.offsetShadowFace = writeStream.writingPos-4-1
					writeStream:rewrite(pOffsetShadowFace,self.offsetShadowFace,uint32)
					for i=1,self.shadowFaceCount do
						self.shadowFaces[i]:write(writeStream,self.version)
					end
				end
			end
		elseif self.version == "COLL" then
			writeStream:write(self.sphereCount,uint32)
			for i=1,self.sphereCount do
				self.spheres[i]:write(writeStream)
			end
			writeStream:write(0,uint32)	--Unused 0
			writeStream:write(self.boxCount,uint32)
			for i=1,self.boxCount do
				self.boxes[i]:write(writeStream)
			end
			writeStream:write(self.vertexCount,uint32)
			for i=1,self.vertexCount do
				self.vertices[i]:write(writeStream)
			end
			writeStream:write(self.faceCount,uint32)
			for i=1,self.faceCount do
				self.faces[i]:write(writeStream)
			end
		end
		writeStream:rewrite(pSize,writeStream.writingPos-1,uint32)
	end,
	getSize = function(self)
		
	end,
}

class "TBounds" {
	radius = nil,
	center = nil,
	min = nil,
	max = nil,
	read = function(self,readStream,version)
		version = version or "COLL"
		if version == "COLL" then
			self.radius = readStream:read(float)
			self.center = {readStream:read(float),readStream:read(float),readStream:read(float)}
			self.min = {readStream:read(float),readStream:read(float),readStream:read(float)}
			self.max = {readStream:read(float),readStream:read(float),readStream:read(float)}
		else
			self.min = {readStream:read(float),readStream:read(float),readStream:read(float)}
			self.max = {readStream:read(float),readStream:read(float),readStream:read(float)}
			self.center = {readStream:read(float),readStream:read(float),readStream:read(float)}
			self.radius = readStream:read(float)
		end
	end,
	write = function(self,writeStream,version)
		version = version or "COLL"
		if version == "COLL" then
			writeStream:write(self.radius,float)
			writeStream:write(self.center[1],float)
			writeStream:write(self.center[2],float)
			writeStream:write(self.center[3],float)
			writeStream:write(self.min[1],float)
			writeStream:write(self.min[2],float)
			writeStream:write(self.min[3],float)
			writeStream:write(self.max[1],float)
			writeStream:write(self.max[2],float)
			writeStream:write(self.max[3],float)
		else
			writeStream:write(self.min[1],float)
			writeStream:write(self.min[2],float)
			writeStream:write(self.min[3],float)
			writeStream:write(self.max[1],float)
			writeStream:write(self.max[2],float)
			writeStream:write(self.max[3],float)
			writeStream:write(self.center[1],float)
			writeStream:write(self.center[2],float)
			writeStream:write(self.center[3],float)
			writeStream:write(self.radius,float)
		end
	end,
	getSize = function(self)
		return 4*10
	end,
}

class "TBox" {
	min = nil,
	max = nil,
	surface = nil,
	read = function(self,readStream)
		self.min = {readStream:read(float),readStream:read(float),readStream:read(float)}
		self.max = {readStream:read(float),readStream:read(float),readStream:read(float)}
		self.surface = TSurface()
		self.surface:read(readStream)
	end,
	write = function(self,writeStream)
		writeStream:write(self.min[1],float)
		writeStream:write(self.min[2],float)
		writeStream:write(self.min[3],float)
		writeStream:write(self.max[1],float)
		writeStream:write(self.max[2],float)
		writeStream:write(self.max[3],float)
		self.surface:write(writeStream)
	end,
	getSize = function()
		return self.surface:getSize()+24
	end,
}

class "TSurface" {
	material = nil,
	flags = nil,
	brightness = nil,
	light = nil,
	read = function(self,readStream)
		self.material = readStream:read(uint8)
		self.flags = readStream:read(uint8)
		self.brightness = readStream:read(uint8)
		self.light = readStream:read(uint8)
	end,
	write = function(self,writeStream)
		writeStream:write(self.material,uint8)
		writeStream:write(self.flags,uint8)
		writeStream:write(self.brightness,uint8)
		writeStream:write(self.light,uint8)
	end,
	getSize = function()
		return 4
	end,
}

class "TSphere" {
	radius = nil,
	center = nil,
	surface = nil,
	read = function(self,readStream,version)
		version = version or "COLL"
		if version == "COLL" then
			self.radius = readStream:read(float)
			self.center = {readStream:read(float),readStream:read(float),readStream:read(float)}
			self.surface = TSurface()
			self.surface:read(readStream)
		else
			self.center = {readStream:read(float),readStream:read(float),readStream:read(float)}
			self.radius = readStream:read(float)
			self.surface = TSurface()
			self.surface:read(readStream)
		end
	end,
	write = function(self,writeStream,version)
		version = version or "COLL"
		if version == "COLL" then
			writeStream:write(self.radius,float)
			writeStream:write(self.center[1],float)
			writeStream:write(self.center[2],float)
			writeStream:write(self.center[3],float)
			self.surface:write(writeStream)
		else
			writeStream:write(self.center[1],float)
			writeStream:write(self.center[2],float)
			writeStream:write(self.center[3],float)
			writeStream:write(self.radius,float)
			self.surface:write(writeStream)
		end
	end,
}

class "TVertex" {
	nil,
	nil,
	nil,
	read = function(self,readStream,version)
		version = version or "COLL"
		if version == "COLL" then
			self[1] = readStream:read(float)
			self[2] = readStream:read(float)
			self[3] = readStream:read(float)
		else
			self[1] = readStream:read(int16)
			self[2] = readStream:read(int16)
			self[3] = readStream:read(int16)
		end
	end,
	write = function(self,writeStream,version)
		version = version or "COLL"
		if version == "COLL" then
			writeStream:write(self[1],float)
			writeStream:write(self[2],float)
			writeStream:write(self[3],float)
		else
			writeStream:write(self[1],int16)
			writeStream:write(self[2],int16)
			writeStream:write(self[3],int16)
		end
	end,
}

class "TFace" {
	a = nil,
	b = nil,
	c = nil,
	--COLL
	surface = nil,
	--
	--COL2/3
	material = nil,
	light = nil,
	read = function(self,readStream,version)
		version = version or "COLL"
		if version == "COLL" then
			self.a = readStream:read(uint32)
			self.b = readStream:read(uint32)
			self.c = readStream:read(uint32)
			self.surface = TSurface()
			self.surface:read(readStream)
		else
			self.a = readStream:read(uint16)
			self.b = readStream:read(uint16)
			self.c = readStream:read(uint16)
			self.material = readStream:read(uint8)
			self.light = readStream:read(uint8)
		end
	end,
	write = function(self,writeStream,version)
		version = version or "COLL"
		if version == "COLL" then
			writeStream:write(self.a,uint32)
			writeStream:write(self.b,uint32)
			writeStream:write(self.c,uint32)
			if not self.surface then
				writeStream:write(self.material,uint8)
				writeStream:write(self.flags or 0,uint8)
				writeStream:write(self.brightness or 255,uint8)
				writeStream:write(self.light,uint8)
			else
				self.surface:write(writeStream)
			end
		else
			writeStream:write(self.a,uint16)
			writeStream:write(self.b,uint16)
			writeStream:write(self.c,uint16)
			if self.surface then
				writeStream:write(self.surface.material,uint8)
				writeStream:write(self.surface.light,uint8)
			else
				writeStream:write(self.material,uint8)
				writeStream:write(self.light,uint8)
			end
		end
	end,
	getSize = function(self,version)
		version = version or "COLL"
		if version == "COLL" then
			return 4*3+self.surface:getSize()
		else
			return 4*3+2
		end
	end
}

class "FaceGroup" {
	min = nil,
	max = nil,
	startFace = nil,
	endFace = nil,
	read = function(self,readStream,version)
		version = version or "COLL"
		if version ~= "COLL" then
			self.min = {readStream:read(float),readStream:read(float),readStream:read(float)}
			self.max = {readStream:read(float),readStream:read(float),readStream:read(float)}
			self.startFace = readStream:read(uint16)
			self.endFace = readStream:read(uint16)
		end
	end,
	write = function(self,writeStream,version)
		version = version or "COLL"
		if version ~= "COLL" then
			writeStream:write(self.min[1],float)
			writeStream:write(self.min[2],float)
			writeStream:write(self.min[3],float)
			writeStream:write(self.max[1],float)
			writeStream:write(self.max[2],float)
			writeStream:write(self.max[3],float)
			writeStream:write(self.startFace,uint16)
			writeStream:write(self.endFace,uint16)
		end
	end,
	getSize = function(self,version)
		version = version or "COLL"
		if version ~= "COLL" then
			return 4*6+2*2
		end
		return 0
	end,
}
