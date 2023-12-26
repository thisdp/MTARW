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
}
--RW Version
EnumRWTXDVersion = {
	GTASA = {
		Platform = {
			PC = EnumDeviceID.D3D9,
			XBOX = EnumDeviceID.XBOX,
			PS2 = EnumDeviceID.PS2,
		}
	},
	GTAVC = {
		Platform = {
			PC = EnumDeviceID.D3D8,
			XBOX = EnumDeviceID.XBOX,
			PS2 = EnumDeviceID.PS2,
		}
	},
	GTA3 = {
		Platform = {
			PC = EnumDeviceID.D3D8,
			XBOX = EnumDeviceID.XBOX,
		}
	}
}

function rwioGetTXDVersion(gtaVer,platform)
	return EnumRWTXDVersion[gtaVer][platform]
end

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

class "TextureNativeExtension" {
	extend = "Extension",
	data = {},
	init = function(self,version)
		self.size = self:getSize(true)
		self.version = version
		self.type = AtomicExtension.typeID
		return self
	end,
	methodContinue = {
		read = function(self,readStream)
			if self.size > 0 then
				self.data = readStream:read(char, self.size)
			end
		end,
		write = function(self,writeStream)
			if self.size > 0 then
				writeStream:write(self.data)
			end
		end,
		getSize = function(self)
			return #self.data
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
			self.extension = TextureNativeExtension()
			self.extension:read(readStream)
		end,
		write = function(self,writeStream)
			self.struct:write(writeStream)
			for i=1,self.struct.textureNativeCount do
				self.textureNatives[i]:write(writeStream)
			end
			self.extension:write(writeStream)
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

	version = false,
    filterFlags = false,
    textureName = false,
    maskName = false,
	maskFlags = false,
	textureFormat = false,
	width = false,
	height = false,
	depth = false,
	mipMapCount = false,
	texCodeType = false,
	flags = false,
	palette = false,
	dataSize = false,
	data = false,
	mipmaps = false,
	mipmapSizes = false,

	methodContinue = {
		read = function(self,readStream)
			self.version = readStream:read(uint32)
            self.filterFlags = readStream:read(uint32);
            self.name = readStream:read(char,32);
            self.mask = readStream:read(char,32);
			self.maskFlags = readStream:read(uint32);

			self.textureFormat = readStream:read(uint32);
			self.width = readStream:read(uint16);
			self.height = readStream:read(uint16);
			self.depth = readStream:read(uint8);
			self.mipMapCount = readStream:read(uint8);
			self.texCodeType = readStream:read(uint8);
			self.flags = readStream:read(uint8);

			self.palette = readStream:read(char, self.depth == 7 and 256 * 4 or 0);

			self.dataSize = readStream:read(uint32);
			self.data = readStream:read(char, self.dataSize);
			
			self.mipmaps = {}
			self.mipmapSizes = {}

			for i = 1, self.mipMapCount - 1 do
				local size = readStream:read(uint32)
				local data = readStream:read(bytes,size)
				self.mipmaps[i] = data
				self.mipmapSizes[i] = size
			end
        end,
		write = function(self,writeStream)
			writeStream:write(self.version, uint32)
			writeStream:write(self.filterFlags, uint32)
			writeStream:write(self.name, char, 32)
			writeStream:write(self.mask, char, 32)
			writeStream:write(self.maskFlags, uint32)
			
			writeStream:write(self.textureFormat, uint32)
			writeStream:write(self.width, uint16)
			writeStream:write(self.height, uint16)
			writeStream:write(self.depth, uint8)
			writeStream:write(self.mipMapCount, uint8)
			writeStream:write(self.texCodeType, uint8)
			writeStream:write(self.flags, uint8)

			writeStream:write(self.palette, char, self.depth == 7 and 256 * 4 or 0)

			writeStream:write(self.dataSize, uint32)
			writeStream:write(self.data, char, self.dataSize)

			for i = 1, self.mipMapCount - 1 do
				local data = self.mipmaps[i]
				local size = self.mipmapSizes[i]
				writeStream:write(size, uint32)
				writeStream:write(data, bytes, size)
			end
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
			self.extension = TextureNativeExtension()
			self.extension:read(readStream)
		end,
		write = function(self,writeStream)
			self.struct:write(writeStream)
			self.extension:write(writeStream)
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