-- load modules
dofile("config.lua")
dofile("web.lua")
dofile("wifi.lua")
dofile("poscontrol.lua")


-- initialize configuration
cfg_init()

-- start wifi
wifi_init()

-- initialize position controller
poscontrol_init()
