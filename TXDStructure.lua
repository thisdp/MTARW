
--Enums
EnumFilterMode = {
	NEAREST = 1,
	LINEAR = 2,
	MIPNEAREST = 3,	--one mipmap
	MIPLINEAR = 4,
	LINEARMIPNEAREST = 5,	--mipmap interpolated
	LINEARMIPLINEAR = 6,
}
EnumAddressing = {
	WRAP = 1,
	MIRROR = 2,
	CLAMP = 3,
	BORDER = 4,
}
EnumDeviceID = {
	UNKNOWN = 0,
	D3D8 = 1,
	D3D9 = 2,
	GCN = 3,
	NULL = 4,
	OPENGL = 5,
	PS2 = 6,
	SOFTRAS = 7,
	XBOX = 8,
	PSP = 9,
}
EnumFormat = {
	DEFAULT = 0,
	C1555 = 0x0100,
	C565 = 0x0200,
	C4444 = 0x0300,
	LUM8 = 0x0400,
	C8888 = 0x0500,
	C888 = 0x0600,
	D16 = 0x0700,
	D24 = 0x0800,
	D32 = 0x0900,
	C555 = 0x0A00,
	AUTOMIPMAP = 0x1000,
	PAL8 = 0x2000,
	PAL4 = 0x4000,
	MIPMAP = 0x8000,
}
EnumD3DFormat = {
	L8 = 50,
	A8L8 = 51,
	A1R5G5B5 = 25,
	A8B8G8R8 = 32,
	R5G6B5 = 23,
	A4R4G4B4 = 26,
	X8R8G8B8 = 22,
	X1R5G5B5 = 24,
    A8R8G8B8 = 21,
	DXT1 = 0x31545844,
	--DXT2 = 0x32545844,
	DXT3 = 0x33545844,
	--DXT4 = 0x34545844,
	DXT5 = 0x35545844,
},

class "TXDIO" {
	textureDictionary = false,
	readStream = false,
	writeStream = false,
	load = function(self,pathOrRaw)
		if fileExists(pathOrRaw) then
			local f = fileOpen(pathOrRaw)
			if f then
				pathOrRaw = fileRead(f,fileGetSize(f))
				fileClose(f)
			end
		end
		self.readStream = ReadStream(pathOrRaw)
		self.textureDictionary = TextureDictionary()
		self.textureDictionary:read(self.readStream)
	end,
	save = function(self,fileName)
		if fileExists(fileName) then fileDelete(fileName) end
		self.writeStream = WriteStream()
		self.textureDictionary:write(self.writeStream)
		local f = fileCreate(fileName)
		fileWrite(f,self.writeStream:save())
		fileClose(f)
	end,
	
	--Custom Functions
	listTextures = function(self)
		local nameList = {}
		local txdChildren = self.textureDictionary.textureNatives
		for i=1,#txdChildren do
			local texNative = txdChildren[i]	--Texture Native
			nameList[i] = texNative.struct.name
		end
		return nameList
	end,
	getTextureNativeDataByIndex = function(self,index)
		local txdChildren = self.textureDictionary.textureNatives
		if txdChildren[index] then
			return txdChildren[index].struct
		end
	end,
	getTextureNativeDataByName = function(self,name)
		local txdChildren = self.textureDictionary.textureNatives
		local textureDataList = {}
		for i=1,#txdChildren do
			local texNative = txdChildren[i]	--Texture Native
			if texNative.struct.name == name then
				table.insert(textureDataList,texNative)
			end
		end
		return unpack(textureDataList)
	end,
	removeTextureDataByName = function(self,name)
		--todo
	end,
	removeTextureDataByIndex = function(self,index)
		return self.textureDictionary:removeByID(index)
	end,
	addTexture = function(self,textureName)
		--todo
	end,
	getTexture = function(self,textureID)
		local txdChildren = self.textureDictionary.textureNatives
		if not txdChildren[textureID] then return false end
		local texNative = txdChildren[textureID]
		if texNative.struct.d3dformat == EnumD3DFormat.DXT1 or texNative.struct.d3dformat == EnumD3DFormat.DXT3 or texNative.struct.d3dformat == EnumD3DFormat.DXT5 then --DXT
			local dds = DDSTexture()
			dds:convertFromTXD(texNative)
			local writeStream = WriteStream()
			dds:write(writeStream)
			return writeStream:save()
		else --Plain
			local bmp = BMPTexture()
			bmp:convertFromTXD(texNative)
			local writeStream = WriteStream()
			bmp:write(writeStream)
			return writeStream:save()
		end
	end,
}

class "TextureDictionaryStruct" {
	extend = "Struct",
	textureNativeCount = false,
	deviceID = false,
	methodContinue = {
		read = function(self,readStream)
			self.textureNativeCount = readStream:read(uint16)	--2Bytes
			self.deviceID = readStream:read(uint16)	--2Bytes
		end,
		write = function(self,writeStream)
			writeStream:write(self.textureNativeCount,uint16)
			writeStream:write(self.deviceID,uint16)
		end,
		getSize = function(self)
			return 4
		end,
	}
}

class "TextureDictionary" {	typeID = 0x16,
	extend = "Section",
	struct = false,
	textureNatives = {},
	extension = false,
	methodContinue = {
		read = function(self,readStream)
			self.struct = TextureDictionaryStruct()
			self.struct:read(readStream)
			for i=1,self.struct.textureNativeCount do
				self.textureNatives[i] = TextureNative()
				self.textureNatives[i]:read(readStream)	--Texture Native
			end
			self.extension = Extension()
			self.extension:read(readStream)
		end,
		write = function(self,writeStream)
			self.struct:write(writeStream)
			for i=1,self.struct.textureNativeCount do
				self.textureNatives[i]:write(writeStream)
			end
			self.extension:write(readStream)
		end,
		getSize = function(self)
			local size = self.struct:getSize()+self.extension:getSize()
			for i=1,self.struct.textureNativeCount do
				size = size+self.textureNatives[i]:getSize()
			end
			return size
		end,
	},
	removeByID = function(self,index)
		if self.textureNatives[index] then
			table.remove(self.textureNatives,index)
			self.struct.textureNativeCount = self.struct.textureNativeCount-1
			--Recalculate Size
			self.size = self:getSize()
		end
	end,
	removeByName = function(self,name)
	
	end,
}

class "TextureNativeStruct" {
	extend = "Struct",
	platform = false,
	filterAddressing = false,	--4Bytes
	name = false,	--32Bytes
	mask = false,	--32Bytes
	format = false,	--4Bytes
	d3dformat = false,	--4Bytes
	width = false,	--2Bytes
	height = false,	--2Bytes
	depth = false,	--1Bytes
	mipmapLevels = false,	--1Bytes
	type = false,	--1Bytes
	flags = false,	--1Bytes
	textures = {},	--(4+texSize)*Number Bytes
	methodContinue = {
		read = function(self,readStream)
			self.platform = readStream:read(uint32)
			if self.platform == EnumPlatform.PLATFORM_D3D9 then
				self.filterAddressing = readStream:read(uint32);
				self.name = readStream:read(char,32);
				self.mask = readStream:read(char,32);
				self.format = readStream:read(int32)
				self.d3dformat = readStream:read(int32)
				self.width = readStream:read(uint16)
				self.height = readStream:read(uint16)
				self.depth = readStream:read(uint8)
				self.mipmapLevels = readStream:read(uint8)
				self.type = readStream:read(uint8)
				self.rasterFormat = bitOr(self.format,self.type,0x80)
				self.flags = readStream:read(uint8)
				--HAS_ALPHA           (1<<0)
				--IS_CUBE             (1<<1)
				--USE_AUTOMIPMAPGEN   (1<<2)
				--IS_COMPRESSED       (1<<3)
				if bitAnd(self.flags,8) then--is compressed
					if bitAnd(self.flags,2) then 
						--todo: err: Can't have cube maps yet
					end
				elseif bitAnd(self.flags,2) then
					--todo: err: Can't have cube maps yet
				end
				if bitAnd(self.rasterFormat,0x4000) ~= 0 then
					self.palette = readStream:read(bytes,4*32)
				elseif bitAnd(self.rasterFormat,0x2000) ~= 0 then
					self.palette = readStream:read(bytes,4*256)
				end
				local size,data
				for i=1,self.mipmapLevels do
					size = readStream:read(uint32)
					if i <= self.mipmapLevels then
						--data = raster->lock(i, Raster::LOCKWRITE|Raster::LOCKNOFETCH);
						data = readStream:read(bytes,size)
						--raster->unlock(i);
					else
						data = readStream:read(bytes,size)
					end
					self.textures[i] = data
				end
			end
		end,
		write = function(self,writeStream)
			if self.platform == EnumPlatform.PLATFORM_D3D9 then
				writeStream:write(self.filterAddressing,uint32)
				writeStream:write(self.name,char,32)
				writeStream:write(self.mask,char,32)
				writeStream:write(self.format,int32)
				writeStream:write(self.d3dformat,int32)
				writeStream:write(self.width,uint16)
				writeStream:write(self.height,uint16)
				writeStream:write(self.depth,uint8)
				writeStream:write(self.mipmapLevels,uint8)
				writeStream:write(self.type,uint8)
				writeStream:write(self.flags,uint8)
				--if not isExported then --This doesn't belong to dds
					if bitAnd(self.rasterFormat,0x4000) == 1 then
						writeStream:write(self.palette,bytes,4*32)
					elseif bitAnd(self.rasterFormat,0x2000) == 1 then
						writeStream:write(self.palette,bytes,4*256)
					end
				--end
				for i=1,#self.textures do
					writeStream:write(#self.textures[i],uint32)
					writeStream:write(self.textures[i],bytes,#self.textures[i])
				end
			end
		end,
		getSize = function(self)
			local size = 88
			for i=1,#self.textures do
				size = size+(4+#self.textures[i])
			end
			return size
		end,
	}
}

class "TextureNative" {	typeID = 0x15,
	extend = "Section",
	struct = false,
	extension = false,
	methodContinue = {
		read = function(self,readStream)
			self.struct = TextureNativeStruct()
			self.struct:read(readStream)
			self.extension = Extension()
			self.extension:read(readStream)
		end,
		write = function(self,writeStream)
			self.struct:write(writeStream)
			self.extension:write(readStream)
		end,
		getSize = function(self)
			return self.struct:getSize()+self.extension:getSize()
		end,
	}
}

EnumDDPF = {
	ALPHAPIXELS = 0x00000001, -- surface has alpha channel
	ALPHA = 0x00000002, -- alpha only
	D3DFORMAT = 0x00000004, -- D3DFormat available
	RGB = 0x00000040, -- RGB(A) bitmap
}
class "DDSPixelFormat" {
	blockSize = 0x00000020, --4Bytes  (32)
	flags = EnumDDPF.D3DFORMAT, --4Bytes (DDPF)
	d3dformat = EnumD3DFormat.DXT1, --4Bytes
	RGBBitCount = 0, --4Bytes
	RBitMask = 0, --4Bytes
	GBitMask = 0, --4Bytes
	BBitMask = 0, --4Bytes
	RGBAlphaBitMask = 0, --4Bytes
	read = function(self,readStream)
		self.blockSize = readStream:read(uint32)
		self.flags = readStream:read(uint32)
		self.d3dformat = readStream:read(uint32)
		self.RGBBitCount = readStream:read(uint32)
		self.RBitMask = readStream:read(uint32)
		self.GBitMask = readStream:read(uint32)
		self.BBitMask = readStream:read(uint32)
		self.RGBAlphaBitMask = readStream:read(uint32)
	end,
	write = function(self,writeStream)
		writeStream:write(self.blockSize,uint32)
		writeStream:write(self.flags,uint32)
		writeStream:write(self.d3dformat,uint32)
		writeStream:write(self.RGBBitCount,uint32)
		writeStream:write(self.RBitMask,uint32)
		writeStream:write(self.GBitMask,uint32)
		writeStream:write(self.BBitMask,uint32)
		writeStream:write(self.RGBAlphaBitMask,uint32)
	end,
}

--DIRECTDRAWSURFACE CAPABILITY FLAGS
EnumDDSCaps1 = {
	ALPHA	= 0x00000002, -- alpha only surface
	COMPLEX	= 0x00000008, -- complex surface structure
	TEXTURE	= 0x00001000, -- used as texture (should always be set)
	MIPMAP	= 0x00400000, -- Mipmap present
}

EnumDDSCaps2 = {
	NONE = 0x00000000,
	CUBEMAP = 0x00000200,
	CUBEMAP_POSITIVEX = 0x00000400,
	CUBEMAP_NEGATIVEX = 0x00000800,
	CUBEMAP_POSITIVEY = 0x00001000,
	CUBEMAP_NEGATIVEY = 0x00002000,
	CUBEMAP_POSITIVEZ = 0x00004000,
	CUBEMAP_NEGATIVEZ = 0x00008000,
	VOLUME = 0x00200000,
}

class "DDSCaps" {
	caps1 = EnumDDSCaps1.TEXTURE, --4Bytes (DDSCaps1)
	caps2 = EnumDDSCaps2.NONE, --4Bytes (DDSCaps2)
	reserved = string.rep("\0",4*2), --4*2Bytes
	read = function(self,readStream)
		self.caps1 = readStream:read(uint32)
		self.caps2 = readStream:read(uint32)
		self.reserved = readStream:read(bytes,8)
	end,
	write = function(self,writeStream)
		writeStream:write(self.caps1,uint32)
		writeStream:write(self.caps2,uint32)
		writeStream:write(self.reserved,bytes,8)
	end,
}

class "DDSHeader" {
	magic = 0x20534444, --4Bytes (DDS )
	blockSize = 0x0000007C,  --4Bytes (124)
	flags = 0x00001007, --4Bytes
	height = false,  --4Bytes
	width = false,  --4Bytes
	pitchOrLinearSize = 0x00002000,  --4Bytes
	depth = 0x00000000,  --4Bytes (Volume Texture)
	mipmapLevels = false,  --4Bytes
	reserved1 = string.rep("\0",4*11),  --4*11Bytes
	--Pixel Format
	pixelFormat = DDSPixelFormat(), --pixelFormat
	caps = DDSCaps(), --caps
	reserved2 = 0,  --4Bytes
	read = function(self,readStream)
		self.magic = readStream:read(uint32)
		self.blockSize = readStream:read(uint32)
		self.flags = readStream:read(uint32)
		self.height = readStream:read(uint32)
		self.width = readStream:read(uint32)
		self.pitchOrLinearSize = readStream:read(uint32)
		self.depth = readStream:read(uint32)
		self.mipmapLevels = readStream:read(uint32)
		self.reserved1 = readStream:read(bytes,4*11)
		self.pixelFormat:read(readStream)
		self.caps:read(readStream)
		self.reserved2 = readStream:read(uint32)
	end,
	write = function(self,writeStream)
		writeStream:write(self.magic,uint32)
		writeStream:write(self.blockSize,uint32)
		writeStream:write(self.flags,uint32)
		writeStream:write(self.height,uint32)
		writeStream:write(self.width,uint32)
		writeStream:write(self.pitchOrLinearSize,uint32)
		writeStream:write(self.depth,uint32)
		writeStream:write(self.mipmapLevels,uint32)
		writeStream:write(self.reserved1,bytes,4*11)
		self.pixelFormat:write(writeStream)
		self.caps:write(writeStream)
		writeStream:write(self.reserved2,uint32)
	end,
}

class "DDSTexture" {
	ddsHeader = false,
	ddsTextureData = false,
	read = function(self,readStream)
		self.ddsHeader = DDSHeader()
		self.ddsHeader:read(readStream)
		self.ddsTextureData = readStream:read(bytes)
	end,
	write = function(self,writeStream)
		writeStream = writeStream or WriteStream()
		self.ddsHeader:write(writeStream)
		writeStream:write(self.ddsTextureData,bytes)
		return writeStream
	end,
	convertFromTXD = function(self,textureNative)
		self.ddsHeader = DDSHeader()
		self.ddsHeader.height = textureNative.struct.height
		self.ddsHeader.width = textureNative.struct.width
		self.ddsHeader.mipmapLevels = textureNative.struct.mipmapLevels
		self.ddsHeader.pixelFormat.d3dformat = textureNative.struct.d3dformat
		local d3dFmt = self.ddsHeader.pixelFormat.d3dformat
		if not (d3dFmt == EnumD3DFormat.DXT1 or d3dFmt == EnumD3DFormat.DXT3 or d3dFmt == EnumD3DFormat.DXT5) then return false end
		local writeStream = WriteStream()
		if textureNative.struct.mipmapLevels ~= 1 then
			self.ddsHeader.caps.caps1 = bitOr(self.ddsHeader.caps.caps1,EnumDDSCaps1.MIPMAP,EnumDDSCaps1.COMPLEX)
		end
		for i=1,textureNative.struct.mipmapLevels do
			--writeStream:write(#textureNative.struct.textures[i],uint32)
			writeStream:write(textureNative.struct.textures[i],bytes)
		end
		self.ddsTextureData = writeStream:save()
		return true
	end,
	saveFile = function(self,fileName)
		local ddsData = self:write()
		local file = fileCreate(fileName)
		fileWrite(file,ddsData:save())
		fileClose(file)
	end,
}

class "BMPHeader" {
	type = 0x4D42,
	size = 0,
	reserved1 = 0, 
	reserved2 = 0, 
	offBits = 0,
	read = function(self,readStream)
		self.type = readStream:read(uint16)
		self.size = readStream:read(uint32)
		self.reserved1 = readStream:read(uint16)
		self.reserved2 = readStream:read(uint16)
		self.offBits = readStream:read(uint32)
	end,
	write = function(self,writeStream)
		writeStream:write(self.type,uint16)
		writeStream:write(self.size,uint32)
		writeStream:write(self.reserved1,uint16)
		writeStream:write(self.reserved2,uint16)
		writeStream:write(self.offBits,uint32)
	end,
}

class "BMPInfoHeader" {
	size = 0x28,
	width =  0,
	height = 0, 
	planes = 0, 
	bitCount = 0,
	compression = 0,
	sizeImage = 0,
	xPelsPerMeter = 0,
	yPelsPerMeter = 0,
	clrUsed = 0,
	clrImportant = 0,
	read = function(self,readStream)
		self.size = readStream:read(uint32)
		self.width = readStream:read(uint32)
		self.height = readStream:read(uint32)
		self.planes = readStream:read(uint16)
		self.bitCount = readStream:read(uint16)
		self.compression = readStream:read(uint32)
		self.sizeImage = readStream:read(uint32)
		self.xPelsPerMeter = readStream:read(uint32)
		self.yPelsPerMeter = readStream:read(uint32)
		self.clrUsed = readStream:read(uint32)
		self.clrImportant = readStream:read(uint32)
	end,
	write = function(self,writeStream)
		writeStream:write(self.size,uint32)
		writeStream:write(self.width,uint32)
		writeStream:write(self.height,uint32)
		writeStream:write(self.planes,uint16)
		writeStream:write(self.bitCount,uint16)
		writeStream:write(self.compression,uint32)
		writeStream:write(self.sizeImage,uint32)
		writeStream:write(self.xPelsPerMeter,uint32)
		writeStream:write(self.yPelsPerMeter,uint32)
		writeStream:write(self.clrUsed,uint32)
		writeStream:write(self.clrImportant,uint32)
	end,
}

class "BMPTexture" {
	bmpHeader = BMPHeader(),
	bmpInfoHeader = BMPInfoHeader(),
	bmpData = false,
	read = function(self,readStream)
		self.bmpHeader:read(readStream)
		self.bmpInfoHeader:read(readStream)
		self.bmpData = readStream:read(bytes)
	end,
	write = function(self,writeStream)
		writeStream = writeStream or WriteStream()
		self.bmpHeader:write(writeStream)
		self.bmpInfoHeader:write(writeStream)
		writeStream:write(self.bmpData,bytes)
		return writeStream
	end,
	convertFromTXD = function(self,textureNative)
		self.bmpHeader = BMPHeader()
		self.bmpHeader.size = #textureNative.struct.textures[1]+0x00000036
		self.bmpHeader.offBits = 0x00000036 --No Palette
		self.bmpInfoHeader.height = textureNative.struct.height
		self.bmpInfoHeader.width = textureNative.struct.width
		self.bmpInfoHeader.planes = 1
		self.bmpInfoHeader.bitCount = 32
		self.bmpInfoHeader.compression = 0
		self.bmpInfoHeader.sizeImage = #textureNative.struct.textures[1]
		self.bmpInfoHeader.xPelsPerMeter = 3780
		self.bmpInfoHeader.yPelsPerMeter = 3780
		self.bmpInfoHeader.clrUsed = 0
		self.bmpInfoHeader.clrImportant = 0
		self.bmpData = textureNative.struct.textures[1]
		return true
	end,
	saveFile = function(self,fileName)
		local bmpData = self:write()
		local file = fileCreate(fileName)
		fileWrite(file,bmpData:save())
		fileClose(file)
	end,
}

-------
local txd = TXDIO()
txd:load("infernus.txd")
iprint(txd.textureDictionary)