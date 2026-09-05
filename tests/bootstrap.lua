-- Desktop Lua bootstrap shared by the suites and native-source checks
local Bootstrap = { addonName = "IronfurTracker" }

function Bootstrap.CreateEnvironment()
  local environment = setmetatable({}, { __index = _G })
  environment._G = environment
  environment._testBootstrap = Bootstrap
  environment.loadfile = function(path)
    return loadfile(path, "t", environment)
  end
  environment.dofile = function(path)
    return assert(environment.loadfile(path))()
  end
  environment.dofile("tests/wow_stubs.lua")
  return environment
end

-- Load files before dispatching lifecycle events so tests control initialization
function Bootstrap.LoadAddon(environment, savedVariables)
  local namespace, metadata, files = {}, {}, {}
  for line in io.lines(Bootstrap.addonName .. ".toc") do
    line = line:gsub("^%s+", ""):gsub("%s+$", "")
    if line ~= "" then
      local key, value = line:match("^##%s*([^:]+):%s*(.-)%s*$")
      if key then
        metadata[key] = value
      elseif not line:match("^#") then
        local path = line:gsub("\\", "/")
        if not path:match("%.lua$") then
          error("test bootstrap does not support TOC entry: " .. path)
        end
        files[#files + 1] = path
      end
    end
  end
  if metadata.SavedVariables ~= "IronfurTrackerDB" then
    error("IronfurTracker.toc must declare exactly ## SavedVariables: IronfurTrackerDB")
  end
  if #files == 0 then
    error("IronfurTracker.toc contains no runtime Lua files")
  end

  environment.IronfurTrackerDB = savedVariables
  for _, path in ipairs(files) do
    local chunk, loadError = environment.loadfile(path)
    if not chunk then
      error("unable to load " .. path .. ": " .. tostring(loadError))
    end
    chunk(Bootstrap.addonName, namespace)
  end
  environment._loadedAddonFiles = files
  environment._tocMetadata = metadata
  environment._test_ns = namespace
  return namespace
end

return Bootstrap
