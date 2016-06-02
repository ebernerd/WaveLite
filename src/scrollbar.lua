
local scrollbar = {}

function scrollbar.required( dw, dh, cw, ch, size )
	if dw < cw or dh < ch then
		return dw < cw - size, dh < ch - size
	end
	return false, false
end

function scrollbar.getScrollbarPositions( cw, ch, hv, vv, tw, th )
	return tw / cw * hv, th / ch * vv
end

function scrollbar.getScrollbarSizes( dw, dh, cw, ch, tw, th )
	return tw * math.min( math.max( dw / cw, 0.05 ), 1 ), th * math.min( math.max( dh / ch, 0.05 ), 1 )
end

function scrollbar.setScrollbarPositions( cw, ch, hv, vv, tw, wh, bw, bh )
	return
		math.max( 0, math.min( hv, tw - bw ) ) / tw * cw,
		math.max( 0, math.min( vv, th - bh ) ) / th * ch
end

return scrollbar
