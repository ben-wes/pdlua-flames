local flames = pd.Class:new():register("flames")
local pd_mixin = {}

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
  for k, v in pairs(pd_mixin) do self[k] = v end
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

-- initializing methods and state (with defaults or given arguments)
--
-- creates self.pd_args for saving state
-- and self.pd_method_table for look-ups:
-- 1. get corresponding function is defined
-- 2. get state index for saving method states
-- 3. get method's argument count
function pd_mixin:init_pd_methods(methods, atoms)
  self.pd_method_table = {}
  self.pd_args = {}

  -- handle kwargs and args
  local kwargs = {}
  local args = {}
  local collectKey = nil
  for _, atom in ipairs(atoms) do
    if type(atom) ~= "number" and string.sub(atom, 1, 1) == "-" then
      -- start collecting values for a new key if key detected
      collectKey = string.sub(atom, 2)
      kwargs[collectKey] = {}
    elseif collectKey then
      -- if currently collecting values for a key, add this atom to that key's table
      table.insert(kwargs[collectKey], atom)
    else
      -- otherwise treat as a positional argument
      table.insert(args, atom)
    end
  end

  local valueIndex = 1 -- index for pd_args and atoms
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
        -- populate pd_args with defaults
        for _, value in ipairs(v.default) do
          self.pd_args[valueIndex] = atoms[valueIndex] or value
          valueIndex = valueIndex + 1
        end
      end
    else
      self:error('no function \''..method_name..'\' defined')
    end
  end
  for msg, values in pairs(kwargs) do
    self:handle_pd_message(msg, values)
  end
end

-- handle messages and update state
function pd_mixin:handle_pd_message(msg, atoms)
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
    self:error('missing method definition for `'..msg..'\'')
  end
end