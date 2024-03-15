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
--   * self.pd_env for object name (used in error log) and more config
--   * self.pd_methods for look-ups of:
--     1. corresponding function if defined
--     2. state index for saving method states
--     3. method's argument count
--     4. current values
function pdlua_flames:init_pd_methods(pdclass, name, methods, atoms)
  pdclass.handle_pd_message = pdlua_flames.handle_pd_message
  pdclass.pd_env = pdclass.pd_env or {}
  pdclass.pd_env.name = name
  pdclass.pd_methods = {}
  pdclass.pd_args = {}

  local kwargs, args = self:parse_atoms(atoms)
  local argIndex = 1
  for _, method in ipairs(methods) do
    pdclass.pd_methods[method.name] = {}
    -- add method if a corresponding method exists
    local pd_method_name = 'pd_' .. method.name
    if pdclass[pd_method_name] and type(pdclass[pd_method_name]) == 'function' then
      pdclass.pd_methods[method.name].func = pdclass[pd_method_name]
    elseif not pdclass.pd_env.ignorewarnings then
      pdclass:error(name..': no function \'' .. pd_method_name .. '\' defined')
    end
    -- process initial defaults
    if method.defaults then
      -- initialize entry for storing index and arg count and values
      pdclass.pd_methods[method.name].index = argIndex
      pdclass.pd_methods[method.name].arg_count = #method.defaults
      pdclass.pd_methods[method.name].val = method.defaults
      -- populate pd_args with defaults or preset values
      local argValues = {}
      for _, value in ipairs(method.defaults) do
        local addArg = args[argIndex] or value
        pdclass.pd_args[argIndex] = addArg
        table.insert(argValues, addArg)
        argIndex = argIndex + 1
      end
      pdclass:handle_pd_message(method.name, argValues)
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
    if type(atom) ~= 'number' and string.sub(atom, 1, 1) == '-' then
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
    -- call function an save result (if returned)
    local returnValues = self.pd_methods[sel].func and self.pd_methods[sel].func(self, atoms)
    local values = {}
    -- clip incoming values to arg_count
    if startIndex and valueCount then
      for i, atom in ipairs(returnValues or atoms) do
        if i > valueCount then break end
        table.insert(values, atom)
        self.pd_args[startIndex + i-1] = atom
      end
    end
    self.pd_methods[sel].val = values
    -- update object state
    self:set_args(self.pd_args)
  else
    local baseMessage = self.pd_env.name .. ': no method for \'' .. sel .. '\''
    local inletMessage = n and ' on inlet ' .. string.format('%d', n) or ''
    self:error(baseMessage .. inletMessage)
  end
end

return pdlua_flames
