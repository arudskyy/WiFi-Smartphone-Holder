-- load modules
dofile("config.lua")
dofile("web.lua")
dofile("wifi.lua")
dofile("poscontrol.lua")
dofile("led.lua")

-- initialize configuration
cfg_init()

-- start wifi
wifi_init()
