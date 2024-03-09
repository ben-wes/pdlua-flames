local flames = pd.Class:new():register("flames")

function flames:initialize(sel, args)
  self.inlets = {DATA, DATA}
  -- define methods that are handled for defaults, messages and creation args
  -- defaults are required for all methods with arguments
  local methods =
  {
    { name = "threevalues", default = {1, 2, 3} },
    { name = "onevalue",    default = {0}       },
    { name = "novalue"}
  }
  self:init_pd_methods(methods, args)
  return true
end

-- defined methods get called with 'pd_' prefix
function flames:pd_threevalues(x)
  pd.post('values are '..table.concat(x, " "))
end

function flames:pd_onevalue(x)
  pd.post('one value is '..x[1])
end

function flames:pd_novalue()
  pd.post('no value here')
end

function flames:in_1(sel, atoms)
  self:handle_pd_message(sel, atoms)
end



-------------------------------------------------------------------------------

-- initializing methods and state
--
-- creates self.pd_args for saving state
-- and self.pd_method_table for look-ups:
-- 1. get corresponding function is defined
-- 2. get state index for saving method states
-- 3. get method's argument count
function flames:init_pd_methods(methods, args)
  self.pd_method_table = {}
  self.pd_args = {}
  local valueIndex = 1 -- index for pd_args
  for _, v in ipairs(methods) do
    local method_name = "pd_" .. v.name
    -- initialize method table entry if a corresponding method exists
    if self[method_name] and type(self[method_name]) == "function" then
      self.pd_method_table[v.name] = {
        func = self[method_name]
      }
      -- process initial defaults
      if v.default then
        -- initialize entry for storing index and arg count
        self.pd_method_table[v.name] = self.pd_method_table[v.name] or {}
        self.pd_method_table[v.name].index = valueIndex
        self.pd_method_table[v.name].arg_count = #v.default
        -- populate pd_args and increment valueIndex for each default value
        for _, value in ipairs(v.default) do
          self.pd_args[valueIndex] = value
          valueIndex = valueIndex + 1
        end
      end
    else
      self:error('no function \''..method_name..'\' defined')
    end
  end

  -- handle creation flags
  local flags = {}
  local collectKey = nil
  for _, arg in ipairs(args) do
    if type(arg) ~= "number" and string.sub(arg, 1, 1) == "-" then
    -- start collecting values for a new key if key detected
      collectKey = string.sub(arg, 2)
      flags[collectKey] = {}
    elseif collectKey then
    -- if currently collecting values for a key, add this arg to key's table
      table.insert(flags[collectKey], arg)
    end
  end
  for k, v in pairs(flags) do
    self:handle_pd_message(k, v)
  end
end

-- handle messages and update state
function flames:handle_pd_message(msg, atoms)
  if self.pd_method_table[msg] then
    local startIndex = self.pd_method_table[msg].index
    local valueCount = self.pd_method_table[msg].arg_count
    local values = {}
    if startIndex and valueCount then
      for i, atom in ipairs(atoms) do
        if i > valueCount then break end
        self.pd_args[startIndex + i-1] = atom
        table.insert(values, atom)
      end
    end
    -- run method with clipped atoms
    local method = self.pd_method_table[msg].func
    if method then method(self, values) end
    -- update object state
    self:set_args(self.pd_args)
  else
    self:error('no method for `'..msg..'\'')
  end
end