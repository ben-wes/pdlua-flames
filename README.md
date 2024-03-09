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

function flames_demo:initialize(sel, args)
  self.inlets = {DATA, DATA}
  -- define methods that are handled for defaults, messages and creation args
  --
  -- defaults are required for all methods with arguments
  local methods =
  {
    { name = "threevalues", default = {1, 2, 3} },
    { name = "onevalue",    default = {0}       },
    { name = "novalue"                          }
  }
  pd_flames:init_pd_methods(self, methods, args)
  return true
end

-- defined methods will be called with 'pd_' prefix
function flames_demo:pd_threevalues(x)
  pd.post('values are '..table.concat(x, " "))
end

function flames_demo:pd_onevalue(x)
  pd.post('one value is '..x[1])
end

function flames_demo:pd_novalue()
  pd.post('no value here')
end

-- messages are then handled with the handle_pd_message() method
function flames_demo:in_1(sel, atoms)
  self:handle_pd_message(sel, atoms)
end
~~~
