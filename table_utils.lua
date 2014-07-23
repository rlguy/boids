
function table.contains(tb, item)
  for k,v in pairs(tb) do
    if v == item then
      return true, k
    end
  end
  
  return false
end

function table.pop(tb)
  local item = tb[#tb]
  tb[#tb] = nil
  return item
end

function table.clear(tb)
  for i=#tb,1,-1 do
    tb[i] = n
  end
end

function table.clear_hash(tb)
  for k,_ in pairs(tb) do
    tb[k] = nil
  end
end

function table.copy(source, dest)
  for i=1,#source do
    dest[i] = source[i]
  end
end

-- For simple (key,value) tables
function table.deepcopy(source)
  local t = {}
  for key,value in pairs(source) do
    if tonumber(key) then
    
      local k = tonumber(key)
      if tonumber(value) then
        local v = tonumber(value)
        t[k] = v
      elseif type(value) == 'string' then
        t[k] = value
      elseif type(value) == 'table' then
        t[k] = table.deepcopy(value)
      end
      
    else
      if tonumber(value) then
        local v = tonumber(value)
        t[key] = v
      elseif type(value) == 'string' then
        t[key] = value
      elseif type(value) == 'table' then
        t[key] = table.deepcopy(value)
      end
    end
  end
  
  print(#t)
  return t
end

-- converts table to a string. If the table has nubmered indicies, it must not
-- contain holes
function table.tostring(source)
  local str = "{"
  
  -- numbered indicies first
  for idx,value in ipairs(source) do
    if type(value) == 'table' then
      str = str..table.tostring(value)..", "
    else
      str = str..tostring(value)..", "
    end
  end
  
  for key, value in pairs(source) do
    if not tonumber(key) then
      if type(value) == 'table' then
        str = str..key.." = "..table.tostring(value)..", "
      else
        str = str..key.." = "..tostring(value)..", "
      end
    end
  end
  
  if string.sub(str, #str-1, #str) == ", " then
    str = string.sub(str, 1, #str-2)
  end
  
  str = str.."}"
  
  return str
end

function table.write(source, filename)
  if type(source) ~= "table" then
    print("ERROR in table.write() - source must be a table")
    return
  end
  
  if type(filename) ~= "string" then
    print("ERROR in table.write() - filename must be a table")
    return
  end

  local str = "return "..table.tostring(source)
  local file, err = love.filesystem.newFile(filename)
  if err then
    print(err)
  end
  
  file:open("w")
  local success = file:write(str)
  file:close()
  
  if not success then
    print("ERROR in table.write() - error writing to file: "..success)
  end
end
