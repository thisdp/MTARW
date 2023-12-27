-- this file is beacuse mta's dxGetTexturePixels with DDS and mipmaps
-- is broken, so we have to do it manually
-- by default it returns one valid mipmap and the rest are just black

function getMipMapSize(width, height, d3dFormat)
	if d3dFormat == EnumD3DFormat.DXT1 then
		return math.max(1, math.floor((width+3)/4)) * math.max(1, math.floor((height+3)/4)) * 8
	elseif d3dFormat == EnumD3DFormat.DXT3 or d3dFormat == EnumD3DFormat.DXT5 then
		return math.max(1, math.floor((width+3)/4)) * math.max(1, math.floor((height+3)/4)) * 16
	else
		return width * height * 3
	end
end

function getDdsPixels(texture, mipmapLevel)
    local width, height = dxGetMaterialSize(texture)
    local width = math.max(1, math.floor(width / (2^(mipmapLevel-1))))
    local height = math.max(1, math.floor(height / (2^(mipmapLevel-1))))

    local rt = dxCreateRenderTarget(width, height)
    dxSetRenderTarget(rt)
    dxDrawImage(0, 0, width, height, texture)
    dxSetRenderTarget()
    
    local pixels = dxGetTexturePixels(rt, 'dds', 'dxt1', true)
    local readStream = ReadStream(pixels)
    local size = getMipMapSize(width, height, EnumD3DFormat.DXT1)
    readStream.readingPos = 129
    local mipmap = DDSMipmap()
    mipmap.size = size
    mipmap:read(readStream)
    
    return mipmap.data
end

function getDdsWithMipmapsManually(texture)
    local width, height = dxGetMaterialSize(texture)
    
    local writeStream = WriteStream()
    local header = DDSHeader()
    header.width = width
    header.height = height
    header.mipmapLevels = 9
    header:write(writeStream)
    
    for i = 1, 9 do
        local data = getDdsPixels(texture, i)
        writeStream:write(data, bytes, #data)
    end

    return writeStream:save()
end