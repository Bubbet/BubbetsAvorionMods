package.path = package.path .. ";data/scripts/lib/?.lua"
include("utility")

local disk = {}

local function exportstring( s )
   return string.format("%q", s)
end

--// The Save Function
function disk.save(  tbl,filename )
   local charS,charE = "   ","\n"
   local file,err = io.open( filename, "wb" )
   if err then return err end

   -- initiate variables for save procedure
   local tables,lookup = { tbl },{ [tbl] = 1 }
   file:write( "-- when a value looks similar to this ['table1']={2} ie {number} then its referencing another table below noted with comments."..charE ) -- Added by me to describe whats happening.
   file:write( "-- remember to check the default config, there might be more information about what each variable does there it'll always be located in your steamapps/workshop/content/445220/(MOD_ID_FROM_WORKSHOP_PAGE)/data/scripts/config/config.lua"..charE ) -- Added by me to describe whats happening.
   file:write( "return {"..charE )

   for idx,t in ipairs( tables ) do
      file:write( "-- Table: {"..idx.."}"..charE )
      file:write( "{"..charE )
      local thandled = {}

      for i,v in ipairs( t ) do
         thandled[i] = true
         local stype = type( v )
         -- only handle value
         if stype == "table" then
            if not lookup[v] then
               print('____type', stype)
               printTable(v)
               print('____done')
               table.insert( tables, v )
               lookup[v] = #tables
            end
            file:write( charS.."{"..lookup[v].."},"..charE )
         elseif stype == "string" then
            file:write(  charS..exportstring( v )..","..charE )
         elseif stype == "number" then
            file:write(  charS..tostring( v )..","..charE )
         end
      end

      for i,v in pairs( t ) do
         -- escape handled values
         if (not thandled[i]) then

            local str = ""
            local stype = type( i )
            -- handle index
            if stype == "table" then
               if not lookup[i] then
                  table.insert( tables,i )
                  lookup[i] = #tables
               end
               str = charS.."[{"..lookup[i].."}]="
            elseif stype == "string" then
               str = charS.."["..exportstring( i ).."]="
            elseif stype == "number" then
               str = charS.."["..tostring( i ).."]="
            elseif stype == "function" then
               str = charS.."["..tostring( i ).."]="
            end

            if str ~= "" then
               stype = type( v )
               -- handle value
               if stype == "table" then
                  if not lookup[v] then
                     table.insert( tables,v )
                     lookup[v] = #tables
                  end
                  file:write( str.."{"..lookup[v].."},"..charE )
               elseif stype == "string" then
                  file:write( str..exportstring( v )..","..charE )
               elseif stype == "number" then
                  file:write( str..tostring( v )..","..charE )
               elseif stype == "function" then
                  local meta = getmetatable(tbl)
                  file:write( str..meta[i]..","..charE )
               end
            end
         end
      end
      file:write( "},"..charE )
   end
   file:write( "}" )
   file:close()
end


function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

function getfunctions(path, m)
   local ifile = io.open(path, 'r')
   local sfile = ifile:read('*all')
   local meta = getmetatable(m) or {}
   for k, v in pairs(m) do
      if type(v) == 'table' then
         for k1, v1 in pairs(getfunctions(path, v)) do
            meta[k1] = v1 -- Rough recursion fix
         end
      end
      if type(v) == 'function' then
         local _, s = string.find(sfile, k..'%W')
         local _, e = string.find(sfile, "end,", s)
         local subs = string.sub(sfile, s, e)
         meta[k] = string.match(subs, 'function.*end')
      end
   end
   ifile:close()
   return meta
end

--// The Load Function
function disk.load( sfile ) -- TODO use this to load local configs in config loader so it can take advantage of function exporting
   local tables -- Avorion didnt parse corret path so needed to replace with this
   if onClient() then
      if file_exists(sfile) then
         tables = dofile(sfile)
      else
         return _,"File does not exist: " .. sfile
      end
   else
      local ftables,err = loadfile( sfile )
      if err then return _,err end
      tables = ftables()
   end
   --local ftables,err = loadfile( sfile )
   --if err then return _,err end
   --local tables = ftables()
   for idx = 1,#tables do
      local tolinki = {}
      for i,v in pairs( tables[idx] ) do
         if type( v ) == "table" then
            tables[idx][i] = tables[v[1]]
         end
         if type( i ) == "table" and tables[i[1]] then
            table.insert( tolinki,{ i,tables[i[1]] } )
         end
      end
      -- link indices
      for _,v in ipairs( tolinki ) do
         tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
      end
   end
   local r = tables[1]
   setmetatable(r, getfunctions(sfile, r))
   return r
end

return disk