# pdlua-flames
Simple `pdlua` module handling **fla**gs, **me**ssages and **s**tate management

## Requirements

Requires either `Pd (Pure Data)` with up-to-date `pdlua` extension or a current version of `plugdata` (which already includes `pdlua`):
* https://puredata.info/downloads
* https://github.com/agraef/pd-lua 
* https://plugdata.org/

## Intro to pdlua

For an intro on creating Pd objects with `pdlua`, see object's help (the object itself is named `pdlua`) and/or:
* https://agraef.github.io/pd-lua/tutorial/pd-lua-intro.html
* https://raw.githubusercontent.com/timothyschoen/pd-lua/master/doc/graphics.txt

## Usage

A basic `.pd_lua` object is created as follows and [flames](https://github.com/ben-wes/pdlua-flames/blob/main/pdlua_flames.lua) will take care of handling incoming messages, creation flags and state saving/restoring:

~~~ lua
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
~~~
