
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- collider object (manages collisions)

  -- *** todo: reduce number of table initializations 

--[[----------------------------------------------------------------------]]--
--##########################################################################--
local collider = {}
collider.table = COLLIDER
collider.debug = true
collider.width = nil             -- width/height in pixels of the collider grid
collider.height = nil
collider.cols = nil              -- columns/rows of cells in grid
collider.rows = nil
collider.cells = nil             -- contains all cells

collider.objects = nil           -- contains all objects, indexed by id
collider.updated = nil           -- contains id's of objects requiring update
collider.updated_by_hash = nil

collider.temp_cell_table = nil
collider.temp_added_table = nil

-- camera view range
collider.cells_in_view = {}

local collider_mt = { __index = collider }
--function collider:new(width, height, camera)
function collider:new(level, x, y, width, height, cell_width, cell_height)
  local collider = setmetatable({}, collider_mt)
  collider.temp_cell_table = {}
  collider.temp_added_table = {}
  
  local cw = cell_width or CELL_WIDTH
  local ch = cell_height or CELL_HEIGHT
  
	-- computer cell dimensions based on global cell width / height
	local cols, rows = math.ceil(width / cw), math.ceil(height / ch)
	cw, ch = width / cols, height / rows
	
	local bbox = bbox:new(x, y, width, height)
	
	-- construct grid
	local cells = {}
	for j=1,rows do
		local row = {}
		for i=1,cols do
			local cell = {}
			cell.contents = {}
			cell.x = x + (i - 1) * cw
			cell.y = y + (j - 1) * ch
			cell.count = 0
			
			row[#row+1] = cell
		end
		cells[#cells+1] = row
	end
	
	collider.x = x
	collider.y = y
	collider.width = width
	collider.height = height
	collider.bbox = bbox
	collider.cell_width = cw
	collider.cell_height = ch
	collider.inv_cell_width = 1 / cw
	collider.inv_cell_height = 1 / ch
	collider.cols = cols
	collider.rows = rows
	collider.cells = cells
	collider.objects = {}
	collider.updated = {}
	collider.updated_by_hash = {}
	collider.camera = level:get_camera()
	
	return collider
end
  
------------------------------------------------------------------------------
function collider:update(dt)
  -- calculate cells in view
  local cam_pos = self.camera:get_pos()
  local width, height = self.camera:get_size()
  local x1, y1 = cam_pos.x, cam_pos.y
  local min_i, min_j = self:get_cell_index(x1, y1)
  local max_i, max_j = self:get_cell_index(x1 + width, y1 + height)
  min_i, min_j = math.max(1, min_i), math.max(1, min_j)
  max_i, max_j = math.min(max_i, self.cols), math.min(max_j, self.rows)
  
  local cells_in_view = {}
  local idx = 1
  for j=min_j,max_j do
  	for i=min_i,max_i do
  		cells_in_view[idx] = self.cells[j][i]
  		idx = idx + 1
  	end
  end
  self.cells_in_view = cells_in_view
  
	-- update objects
	local updated = self.updated
	for i=1,#updated do
		local obj = self.objects[updated[i]]
		if     obj and obj.table == MAP_POINT then
			self:_update_point(obj)
		elseif obj and obj.table == BBOX then
			self:_update_bbox(obj)
		end
	end
	self.updated = {}
	self.updated_by_hash = {}

end

------------------------------------------------------------------------------
-- insert a MAP_POINT or BBOX object into the collider grid
-- returns an id value for the object. Objects position/size can be update
-- by calling collider:update_object(id). Update will occur next time collider
-- updates
function collider:add_object(obj, parent)
  if self.objects[obj] then
    return -- already added
  end

  if not obj.cdata then
    obj.cdata = {}
    obj.cdata.added_temp_table = {}
  end

	local id
	if     obj.table == MAP_POINT then
		id = self:_insert_point(obj)
	elseif obj.table == BBOX then
		id = self:_insert_bbox(obj)
	end
	
	obj.cdata[self].parent = parent
	return id
end

function collider:_insert_point(point)
	local x, y = point:get_x(), point:get_y()
	local i, j = self:get_cell_index(x, y)
	local cell = self.cells[j][i]
	local offx = x - cell.x
	local offy = y - cell.y
	
	local cdata = point.cdata[self]
	if not cdata then
	  cdata = {}
	  point.cdata[self] = cdata
	end
	
	cdata.x, cdata.y = x, y                 -- pixel coordinates
	cdata.i, cdata.j = i, j                 -- cell indices
	cdata.offx, cdata.offy = offx, offy			-- pixel offset from top left of cell
	
	cell.contents[point] = point
	cell.count = cell.count + 1
	self.objects[point] = point
	
	return point
end

function collider:_insert_bbox(bbox)
	local width, height = bbox:get_width(), bbox:get_height()
	local p1x, p1y = bbox:get_x(), bbox:get_y()
	local p2x, p2y = p1x + width, p1y + height
	
	local i1, j1 = self:get_cell_index(p1x, p1y)
	local i2, j2 = self:get_cell_index(p2x, p2y)
	i1 = math.max(1, i1)
	j1 = math.max(1, j1)
	i2 = math.min(self.cols, i2)
	j2 = math.min(self.rows, j2)
	local cell1 = self.cells[j1][i1]
	local cell2 = self.cells[j2][i2]
	
	local cdata = bbox.cdata[self] or {}
	cdata.width = width
	cdata.height = height
	cdata.x1 = p1x
	cdata.y1 = p1y
	cdata.x2 = p2x
	cdata.y2 = p2y
	cdata.p1_offx = p1x - cell1.x
	cdata.p1_offy = p1y - cell1.y
	cdata.p2_offx = p2x - cell2.x
	cdata.p2_offy = p2y - cell2.y
	
	if cdata.cells then
	  for i=#cdata.cells,1,-1 do
	    cdata.cells[i] = nil
	  end
	else
	  cdata.cells = {}
	end
	
	bbox.cdata[self] = cdata
	
	-- put bbox into cell contents
	if cell1 == cell2 then              -- case where bbox fits in a single cell
		cdata.cells[#cdata.cells + 1] = cell1
		cell1.contents[bbox] = bbox
		cell1.count = cell1.count + 1
	else                                -- bbox in multiple cells
		local cells = cdata.cells
		for j=j1,j2 do
			for i=i1,i2 do
				local cell = self.cells[j][i]
				cells[#cells + 1] = cell
				cell.contents[bbox] = bbox
				cell.count = cell.count + 1
			end
		end
		
	end
	self.objects[bbox] = bbox
	
	return bbox
end

--------------------------------------------------------------------------------
function collider:remove_object(id)
	local object = self.objects[id]
	if object == nil then
		return
	end
	
	if     object.table == MAP_POINT then
		self:_remove_point(object)
	elseif object.table == BBOX then
		self:_remove_bbox(object)
	end
end

function collider:_remove_point(point)
	local cell = self.cells[point.cdata[self].j][point.cdata[self].i]
	local id = point
	
	-- remove from cell
	cell.contents[point] = nil
	cell.count = cell.count - 1
	
	-- remove from objects
	self.objects[id] = nil
	--point.cdata[self] = nil
end

function collider:_remove_bbox(bbox)

	local id = bbox
	local cells = bbox.cdata[self].cells
	
	-- remove from cells
	for i=1,#cells do
		local cell = cells[i]
		cell.contents[id] = nil
		cell.count = cell.count - 1
	end
	
	-- remove from object list
	self.objects[id] = nil
end

------------------------------------------------------------------------------
-- update objects that have moved/changed in size
function collider:update_object(id)
  if self.updated_by_hash[id] then
    return  -- already marked for update this frame
  end  

	self.updated[#self.updated+1] = id
	self.updated_by_hash[id] = id
end

function collider:_update_point(point)
	local cdata = point.cdata[self]
	local x, y = cdata.x, cdata.y
	local newx, newy = point:get_x(), point:get_y()
	local offx, offy = cdata.offx + newx - x, cdata.offy + newy - y
	
	cdata.x = newx
	cdata.y = newy
	cdata.offx = offx
	cdata.offy = offy
	
	-- change cell
	if offx > self.cell_width or offy > self.cell_height or offx < 0 or offy < 0 then
		local i, j = self:get_cell_index(x, y)
		
		local old_cell = self.cells[cdata.j][cdata.i]
		local new_cell = self.cells[j][i]
		local id = point
		
		-- remove from old cell
		old_cell.contents[id] = nil
		old_cell.count = old_cell.count - 1
		
		-- insert into new cell
		new_cell.contents[id] = id
		new_cell.count = new_cell.count + 1
		
		-- set new cdata
		cdata.i = i 
		cdata.j = j
		cdata.offx = newx - new_cell.x
		cdata.offy = newy - new_cell.y
	end
	
end

function collider:_update_bbox(bbox)
	local cdata = bbox.cdata[self]
	local width, height = bbox:get_width(), bbox:get_height()
	local x1, y1, x2, y2 = cdata.x1, cdata.y1, cdata.x2, cdata.y2
	local new_x1, new_y1 = bbox:get_x(), bbox:get_y()
	local new_x2, new_y2 = new_x1 + width, new_y1 + height
	
	local p1_offx = cdata.p1_offx + new_x1 - x1
	local p1_offy = cdata.p1_offy + new_y1 - y1
	local p2_offx = cdata.p2_offx + new_x2 - x2
	local p2_offy = cdata.p2_offy + new_y2 - y2
	
	cdata.width = width
	cdata.height = height
	cdata.x1 = new_x1
	cdata.y1 = new_y1
	cdata.x2 = new_x2
	cdata.y2 = new_y2
	cdata.p1_offx = p1_offx
	cdata.p1_offy = p1_offy
	cdata.p2_offx = p2_offx
	cdata.p2_offy = p2_offy

	-- change cell
	if p1_offx > self.cell_width or p1_offy > self.cell_height or 
	   p1_offx < 0 or p1_offy < 0  or
	   p2_offx > self.cell_width or p2_offy > self.cell_height or 
	   p2_offx < 0 or p2_offy < 0  then

		-- remove from old cells
		local cells = bbox.cdata[self].cells
		local id = bbox
		for i=1,#cells do
		  local cell = cells[i]
			cell.contents[id] = nil
			cell.count = cell.count - 1
		end
	   
		-- find new cells
		local i1, j1 = self:get_cell_index(new_x1, new_y1)
		local i2, j2 = self:get_cell_index(new_x2, new_y2)
		i1 = math.max(1, i1)
    j1 = math.max(1, j1)
    i2 = math.min(self.cols, i2)
    j2 = math.min(self.rows, j2)
		local cell1 = self.cells[j1][i1]
		local cell2 = self.cells[j2][i2]
		
		-- put bbox into cell contents
		local cells = cdata.cells or {}
		for i=#cells,1,-1 do
		  cells[i] = nil
		end
		
		if cell1 == cell2 then              -- case where bbox fits in a single cell
			cells[#cells + 1] = cell1
			cell1.contents[bbox] = bbox
			cell1.count = cell1.count + 1
		else                                -- bbox in multiple cells
			for j=j1,j2 do
				for i=i1,i2 do
					local cell = self.cells[j][i]
					cells[#cells + 1] = cell
					cell.contents[bbox] = bbox
					cell.count = cell.count + 1
				end
			end
		end
		
		-- new offsets
		cdata.p1_offx = new_x1 - cell1.x
		cdata.p1_offy = new_y1 - cell1.y
		cdata.p2_offx = new_x2 - cell2.x
		cdata.p2_offy = new_y2 - cell2.y
	end
	
end

------------------------------------------------------------------------------
function collider:get_collisions(id, storage)
	local bbox = self.objects[id]
	if bbox.table == MAP_POINT then
		return self:_get_point_collisions(bbox)
	end
	
	local MAP_POINT = MAP_POINT
	local idx = 1
	local objects = storage
	local added = bbox.cdata.added_temp_table
	for k,_ in pairs(added) do
	  added[k] = nil
	end
	
	local cells = bbox.cdata[self].cells
	for i=1,#cells do
		local cell = cells[i]
		for _,v in pairs(cell.contents) do
			if v ~= id then
				local obj = self.objects[v]
				
				if obj.table == MAP_POINT and bbox:contains_point(obj.cdata[self]) then
					objects[idx] = obj.cdata[self].parent
					idx = idx + 1
				elseif obj.table == BBOX and bbox ~= obj and bbox:intersects(obj) then
					if  not added[obj] then
						objects[idx] = obj.cdata[self].parent
						idx = idx + 1
						added[obj] = true
					end
				end
			end
		end
	end
	
	return objects
end

function collider:_get_point_collisions(point)
  local BBOX = BBOX
  local idx = 1
  local objects = {}
  local cdata = point.cdata[self]
  local cell = self.cells[cdata.j][cdata.i]
  
  for _,v in pairs(cell.contents) do
    if v.table == BBOX and v:contains_point(point.cdata[self]) then
      objects[idx] = v
      idx = idx + 1
    end
  end
  
  return objects
end

function collider:get_objects_at_position(p, storage)
  local BBOX = BBOX
  
  local cell = self:get_cell(p.x, p.y)
  local idx = 1
  for _,v in pairs(cell.contents) do
    local object = self.objects[v]
    if object.table == BBOX and object:contains_point(p) then
      storage[idx] = object.cdata[self].parent
      idx = idx + 1
    end
  end
  
  return storage
end

function collider:get_objects_at_bbox(bbox, storage)
  local p1x, p1y = bbox.x, bbox.y
	local p2x, p2y = p1x + bbox.width, p1y + bbox.height
	
	local i1, j1 = self:get_cell_index(p1x, p1y)
	local i2, j2 = self:get_cell_index(p2x, p2y)
	i1 = math.max(1, i1)
	j1 = math.max(1, j1)
	i2 = math.min(self.cols, i2)
	j2 = math.min(self.rows, j2)
	
	-- rare bug
	if not self.cells[j1] or not self.cells[j2] or not self.cells[j1][i1] or
	   not self.cells[j2][i2] then
	   print(bbox.x, bbox.y, j1, i1, j2, i2, self.cols, self.rows)
	end
	------------
	
	local cell1 = self.cells[j1][i1]
	local cell2 = self.cells[j2][i2]
	
	-- get cells under bbox
	local cells = self.temp_cell_table
	table.clear(cells)
	if cell1 == cell2 then
	  cells[1] = cell1
	else
	  for j=j1,j2 do
      for i=i1,i2 do
        local cell = self.cells[j][i]
        cells[#cells + 1] = cell
      end
    end
	end
	
	-- get objects
	local objects = storage
	local added = self.temp_added_table
	table.clear_hash(added)
	
	local idx = #objects + 1
	for i=1,#cells do
	  local cell = cells[i]
	  for _,v in pairs(cell.contents) do
      local obj = self.objects[v]
      
      if obj.table == MAP_POINT and bbox:contains_point(obj.cdata[self]) then
        objects[idx] = obj.cdata[self].parent
        idx = idx + 1
      elseif obj.table == BBOX and bbox ~= obj and bbox:intersects(obj) then
        if  not added[obj] then
          objects[idx] = obj.cdata[self].parent
          idx = idx + 1
          added[obj] = true
        end
      end

		end
	end
	
	return objects
	
end

------------------------------------------------------------------------------
-- returns self.cells col, row index of cell containing world point x, y
function collider:get_cell_index(x, y)
	local i = math.floor((x - self.x) * self.inv_cell_width) + 1
	local j = math.floor((y - self.y) * self.inv_cell_height) + 1
	
	if x - self.x == self.width then
	  i = i - 1
	end
	if y - self.y == self.height then
	  j = j - 1
	end
	
	if i < 1 then i = 1 end
	if j < 1 then j = 1 end
	if i > self.cols then i = self.cols end
	if j > self.rows then j = self.rows end
	
	return i, j
end

-- returns cell containing world point x, y
function collider:get_cell(x, y)
	local i, j = self:get_cell_index(x, y)
	return self.cells[j][i]
end

------------------------------------------------------------------------------
function collider:draw()

	-- visual debugs
	if not self.debug then return end
	-- draw contents of cells on screen
	lg.setColor(0, 255, 0, 60)
	lg.setLineWidth(2)
	for i=1,#self.cells_in_view do
		-- draw grid
		local cell = self.cells_in_view[i]
		local x, y = cell.x, cell.y
		local w, h = self.cell_width, self.cell_height
		lg.setColor(0, 0, 0, 120)
		lg.rectangle('line', x+1.5, y+1.5, w-3, h-3)
		
		-- count how many objects in cell
		local count = cell.count
		lg.setColor(50, 50, 50, 255)
		if count > 0 then
		  lg.setColor(255, 255, 0, 255)
		end
		lg.print(count, x + 5, y + 5)
		
		-- draw objects in cell
		local MAP_POINT = MAP_POINT
		local BBOX = BBOX
		lg.setPointSize(7)
		for i,id in pairs(cell.contents) do
			local obj = self.objects[id]
			if obj and obj.table == MAP_POINT then
			  lg.setColor(255, 255, 255, 255)
			  lg.circle("fill", obj.cdata[self].x, obj.cdata[self].y, 3)
			elseif obj and obj.table == BBOX then
			  lg.setColor(255, 255, 255, 255)
				lg.setLineWidth(3)
				local x, y = obj.cdata[self].x1, obj.cdata[self].y1
				local w, h = obj.cdata[self].width, obj.cdata[self].height
				lg.rectangle('line', x, y, w, h)
			end
		end
		
		lg.setColor(0, 0, 255, 255)
		self.bbox:draw()
	end
end


return collider

























