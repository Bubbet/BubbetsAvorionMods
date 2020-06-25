return function(node, height, width, offset)
	--node.rect.center
	width = width or node.rect.width
	height = height or node.rect.height

	-- define both for square
	-- define just height to use parents width
	-- define just width to use parents height

	local center = node.rect.center

	local size = vec2(width, height)

	offset = offset or vec2()
	local rect = Rect(center - size*0.5 + offset, center + size*0.5 + offset)
	return node:child(rect)
end
