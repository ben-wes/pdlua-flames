local flames = require("pdlua_flames") -- include module
local flames_demo = pd.Class:new():register("flames_demo")

function flames_demo:initialize(name, args)
  self.inlets = {DATA, DATA}
  -- define methods to be handled for defaults, messages and creation args
  -- defaults are required for all methods with arguments
  local methods =
  {
    { name = "threevalues", defaults = {1, 2, 3} },
    { name = "thirdvalue",  defaults = {3},
                            offset   = -1        }, -- same as 3rd value above
    { name = "novalue"                           },
    { name = "entry_but_no_function"             }  -- this creates a warning
  }
  flames:init_pd_methods(self, name, methods, args)
  return true
end

-- defined methods will be called with 'pd_' prefix
function flames_demo:pd_threevalues(x)
  pd.post('values are ' .. table.concat(x, " "))
end

function flames_demo:pd_thirdvalue(x)
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