-- config.lua: configuration stuff
-- dependency: no


--global table, keeps configuration
cfg={valid="0", file="config.txt"}


-- initialization of the configuration
function cfg_init()
 cfg_get()
 if "0"==cfg.valid then
  cfg_setdefault()
 end
end


-- set default configuration values
function cfg_setdefault()
 cfg.ssid="enter SSID"
 cfg.pass="password"
 cfg.ip="192.168.1.10"
 cfg.nm="255.255.255.0"
 cfg.gw="192.168.1.1"
 cfg.cc="000080"
 cfg.cap="008000"
end

-- load configuration from file
function cfg_get()
 local fl,k, v
 if file.open(cfg.file, "r") then
--extract arguments
  while true do
   fl=file.readline()
   if nil==fl then break end
   for k,v in string.gmatch(fl, "(%w+)=([%w. ]+)") do
    cfg[k] = v
   end
  end
  file.close()
 end
 collectgarbage()
end


-- store configuration to file
function cfg_save()
 local k,v
 if file.open(cfg.file, "w") then
  for k,v in pairs(cfg) do
   file.writeline(k.."="..v..";")
  end
  file.close()
 end
end


-- invalidate configuration and remove configuration file
function cfg_reset()
 cfg.valid="0"
 if file.exists(cfg.file) then
  file.remove(cfg.file)
 end
end


-- print actual configuration
--function cfg_print()
-- local k,v
-- print("___Configuration________")
-- for k,v in pairs(cfg) do print(k,v) end
-- print("________________________")
--end
