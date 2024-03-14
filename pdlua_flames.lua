local pdlua_flames = {}

-------------------------------------------------------------------------------
--                                       ██  
--                             ▓▓      ██    
--                                 ████▒▒██  
--                               ████▓▓████  
--                             ██▓▓▓▓▒▒██    
--                             ██▓▓▓▓▓▓██    
--                           ████▒▒▓▓▓▓████  
--                           ██▒▒▓▓░░▓▓▒▒▓▓██
--                           ██████▓▓░░▓▓░░██
--                             ██░░░░▒▒░░████
--                             ██░░  ░░░░██  
--                               ░░    ░░
--
-- initializing methods and state (with defaults or creation arguments)
-- creates:
--   * self.pd_args for saving state
--   * self.pd_name for the object name (used in error log)
--   * self.pd_methods for look-ups of:
--     1. corresponding function if defined
--     2. state index for saving method states
--     3. method's argument count
--     4. current values
function pdlua_flames:init_pd_methods(pdclass, name, methods, atoms)
  pdclass.handle_pd_message = pdlua_flames.handle_pd_message
  pdclass.pd_name = name
  pdclass.pd_methods = {}
  pdclass.pd_args = {}

  local kwargs, args = self:parse_atoms(atoms)
  local argIndex = 1
  for _, method in ipairs(methods) do
    pdclass.pd_methods[method.name] = {}
    -- process initial defaults
    if method.defaults then
      if method.offset then argIndex = argIndex + method.offset end
      -- initialize entry for storing index and arg count and values
      pdclass.pd_methods[method.name].index = argIndex
      pdclass.pd_methods[method.name].arg_count = #method.defaults
      pdclass.pd_methods[method.name].values = method.defaults
      -- populate pd_args with defaults
      for _, value in ipairs(method.defaults) do
        pdclass.pd_args[argIndex] = args[argIndex] or value
        argIndex = argIndex + 1
      end
    end
    -- add method if a corresponding method exists
    local pd_method_name = "pd_" .. method.name
    if pdclass[pd_method_name] and type(pdclass[pd_method_name]) == "function" then
      pdclass.pd_methods[method.name].func = pdclass[pd_method_name]
    else
      pdclass:error(name..': no function \'' .. pd_method_name .. '\' defined')
    end
  end
  for sel, atoms in pairs(kwargs) do
    pdclass:handle_pd_message(sel, atoms)
  end
end

function pdlua_flames:parse_atoms(atoms)
  local kwargs = {}
  local args = {}
  local collectKey = nil
  for _, atom in ipairs(atoms) do
    if type(atom) ~= "number" and string.sub(atom, 1, 1) == "-" then
      -- start collecting values for a new key if key detected
      collectKey = string.sub(atom, 2)
      kwargs[collectKey] = {}
    elseif collectKey then
      -- if collecting values for a key, add atom to current key's table
      table.insert(kwargs[collectKey], atom)
    else
      -- otherwise treat as a positional argument
      table.insert(args, atom)
    end
  end
  return kwargs, args
end

-- handle messages and update state
-- function gets mixed into object's class for use as self:handle_pd_messages
function pdlua_flames:handle_pd_message(sel, atoms, n)
  if self.pd_methods[sel] then
    local startIndex = self.pd_methods[sel].index
    local valueCount = self.pd_methods[sel].arg_count
    local values = {}
    if startIndex and valueCount then
      for i, atom in ipairs(atoms) do
        if i > valueCount then break end
        self.pd_args[startIndex + i-1] = atom
        table.insert(values, atom)
      end
    end
    -- write clipped values to method table
    self.pd_methods[sel].values = values
    -- run method
    if self.pd_methods[sel].func then
      self.pd_methods[sel].func(self, values)
    end
    -- update object state
    self:set_args(self.pd_args)
  else
    local baseMessage = self.pd_name .. ': no method for \'' .. sel .. '\''
    local inletMessage = n and ' on inlet ' .. string.format("%d", n) or ''
    self:error(baseMessage .. inletMessage)
  end
end

return pdlua_flames