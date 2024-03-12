local flames_demo = pd.Class:new():register("flames_demo")
local pd_flames = {}

function flames_demo:initialize(name, args)
  self.inlets = {DATA, DATA}
  -- define methods to be handled for defaults, messages and creation args
  -- defaults are required for all methods with arguments
  local methods =
  {
    { name = "threevalues", defaults = {1, 2, 3} },
    { name = "onevalue",    defaults = {0}       },
    { name = "novalue"                           },
    { name = "thisismissingafunction"            }
  }
  pd_flames:init_pd_methods(self, name, methods, args)
  return true
end

-- defined methods will be called with 'pd_' prefix
function flames_demo:pd_threevalues(x)
  pd.post('values are ' .. table.concat(x, " "))
end

function flames_demo:pd_onevalue(x)
  pd.post('one value is ' .. x[1])
end

function flames_demo:pd_novalue()
  pd.post('no value here')
end

-- messages are handled with handle_pd_message()
--
-- an optional inlet number can be given to provide
-- more detailed error messages (if no method exists)
function flames_demo:in_n(n, sel, atoms)
  self:handle_pd_message(sel, atoms, n)
end


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
--   * self.pd_method_table for look-ups of:
--     1. corresponding function if defined
--     2. state index for saving method states
--     3. method's argument count
function pd_flames:init_pd_methods(pdclass, name, methods, atoms)
  pdclass.handle_pd_message = pd_flames.handle_pd_message
  pdclass.pd_name = name
  pdclass.pd_method_table = {}
  pdclass.pd_args = {}

  local kwargs, args = self:parse_atoms(atoms)
  local argIndex = 1
  for _, method in ipairs(methods) do
    local pd_method_name = "pd_" .. method.name
    -- initialize method table entry if a corresponding method exists
    if pdclass[pd_method_name] and type(pdclass[pd_method_name]) == "function" then
      pdclass.pd_method_table[method.name] = { func = pdclass[pd_method_name] }
      -- process initial defaults
      if method.defaults then
        -- initialize entry for storing index and arg count
        local methodEntry = pdclass.pd_method_table[method.name]
        pdclass.pd_method_table[method.name] = methodEntry or {}
        pdclass.pd_method_table[method.name].index = argIndex
        pdclass.pd_method_table[method.name].arg_count = #method.defaults
        -- populate pd_args with defaults
        for _, value in ipairs(method.defaults) do
          pdclass.pd_args[argIndex] = args[argIndex] or value
          argIndex = argIndex + 1
        end
      end
    else
      pdclass:error(name..': no function \'' .. pd_method_name .. '\' defined')
    end
  end
  for sel, atoms in pairs(kwargs) do
    pdclass:handle_pd_message(sel, atoms)
  end
end

function pd_flames:parse_atoms(atoms)
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
function pd_flames:handle_pd_message(sel, atoms, n)
  if self.pd_method_table[sel] then
    local startIndex = self.pd_method_table[sel].index
    local valueCount = self.pd_method_table[sel].arg_count
    local values = {}
    if startIndex and valueCount then
      for i, atom in ipairs(atoms) do
        if i > valueCount then break end
        self.pd_args[startIndex + i-1] = atom
        table.insert(values, atom)
      end
    end
    -- run method with clipped atoms
    if self.pd_method_table[sel].func then
      self.pd_method_table[sel].func(self, values)
    end
    -- update object state
    self:set_args(self.pd_args)
  else
    local baseMessage = self.pd_name .. ': no method for \'' .. sel .. '\''
    local inletMessage = n and ' on inlet ' .. string.format("%d", n) or ''
    self:error(baseMessage .. inletMessage)
  end
end