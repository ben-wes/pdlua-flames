# pdlua-flames
a simple pdlua example object handling **fla**gs, **me**ssages and **s**tate management

requires Pd (Pure Data) and up-to-date `pdlua` extension:
* https://puredata.info/downloads
* https://github.com/agraef/pd-lua 

---

the actual functionality of the pdlua object is then defined like this:

~~~ lua
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
  pd_flames:init_pd_methods(name, self, methods, args)
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
~~~
