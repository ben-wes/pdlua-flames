# pdlua-flames
simple `pdlua` example object with helper methods handling **fla**gs, **me**ssages and **s**tate management

## setup

requires either `Pd (Pure Data)` with up-to-date `pdlua` extension or a current version of `plugdata` (which already includes `pdlua`):
* https://puredata.info/downloads
* https://github.com/agraef/pd-lua 
* https://plugdata.org/

## introduction to pdlua

for an intro on creating Pd objects with `pdlua`, see object's help in Pd and:
* https://agraef.github.io/pd-lua/tutorial/pd-lua-intro.html
* https://raw.githubusercontent.com/timothyschoen/pd-lua/master/doc/graphics.txt

## usage

the actual functionality of the `.pd_lua` file is then defined above the [flames](https://github.com/ben-wes/pdlua-flames/blob/main/flames_demo.pd_lua#L41) as follows and will take care of handling incoming messages, creation flags and state saving/restoring:

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
    { name = "entry_but_no_function"             }  -- this creates a warning
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
~~~
