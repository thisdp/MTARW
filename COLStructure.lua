
class "COLIO" {	
	collision = false,
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
		self.clump = Clump()
		self.clump:read(self.readStream)
	end,
	save = function(self,fileName)
		if fileExists(fileName) then fileDelete(fileName) end
		self.writeStream = WriteStream()
		self.textureDictionary:pack(self.writeStream)
		local f = fileCreate(fileName)
		fileWrite(f,self.writeStream:save())
		fileClose(f)
	end,
	getSize = function(self)
	
	end,
}

class "Collision" {

}