-- wifi.lua: wifi modes statemachine, mDNS
-- dependency: config.lua, web.lua


function wifi_start_client(par)
--use station(client) mode, where the device joins an existing network
--par is a table with "ssid" and "pass" elements
--ip in par is optional IP-settings that device will use after a new connection established
--nw_set is a table with "ip", "nm" and "gw" elements
--mode 
 wifi.setmode(wifi.STATION)
--IP settings
 if (par.ip~="")then
  wifi.sta.setip({ip=par.ip,netmask=par.nm,gateway=par.gw})        
 end
--wifi network settings
 st_cfg={ssid=par.ssid,pwd=par.pass,save=false}
 wifi.sta.config(st_cfg)

 collectgarbage()
end


function wifi_start_ap()
--activates access point mode
 wifi.setmode(wifi.SOFTAP)
 wifi.ap.setip({ip="192.168.1.1",netmask="255.255.255.0",gateway="192.168.1.1"})
 wifi.ap.config({ssid="WIFI Smartphone holder",pwd="smartholder"})
 mdns.register("smartphoneholder",{service="http",port=80})
 collectgarbage()
end


-- mDNS stuff: register mDNS if IP-address assigned
wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
 mdns.register("smartphoneholder",{service="http",port=80})
 collectgarbage()
end)

--wifi statemachine indication
WIFI_SM_INIT="init"--no mode configured
WIFI_SM_APNC="apnc"--Access Point,No client Connected
WIFI_SM_APCC="apcc"--Access Point,Client(s) Connected
WIFI_SM_CLNC="clnc"--CLient,Not Connected
WIFI_SM_CLCC="clcc"--CLient,ConneCted
WIFI_SM=WIFI_SM_INIT
--function to set mode(ro swith indication)
function wifi_sm_set(state)
 WIFI_SM=state
 print("WIFI state changed to: "..WIFI_SM)

-- set led modes depending from state
 if WIFI_SM=="apnc" then
  led_cntrl(cfg.cap,false)
 elseif WIFI_SM=="apcc" then
  led_cntrl(cfg.cap,true)
 elseif WIFI_SM=="clnc" then
  led_cntrl(cfg.cc,false)
 elseif WIFI_SM=="clcc" then
  led_cntrl(cfg.cc,true)
 end

 collectgarbage()
end

--function to refresh leds according to current mode
function wifi_sm_refresh(state)
 wifi_sm_set(WIFI_SM)
end

--state monitoring
--connection wait timeout timer,30s oneshort 
wifi_cl_timer=tmr.create()
wifi_cl_timer:register(30000, tmr.ALARM_SINGLE, function()
--switch to access point mode
 wifi_sm_set(WIFI_SM_APNC)
 wifi_start_ap()
end)

wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
--stop connection wait timeout timer
 wifi_cl_timer:stop()
 wifi_sm_set(WIFI_SM_CLCC)
end)

wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T)
 wifi_sm_set(WIFI_SM_CLNC)
end)

wifi.eventmon.register(wifi.eventmon.AP_STACONNECTED, function(T)
--ignore number of connected clients,always report related state
 wifi_sm_set(WIFI_SM_APCC)
end)

wifi.eventmon.register(wifi.eventmon.AP_STADISCONNECTED, function(T)
--check whether is it last disconnected client?
 if next(wifi.ap.getclient())==nil then
--table is empty,no connections
  wifi_sm_set(WIFI_SM_APNC)
 end
 collectgarbage()
end)


function wifi_init()
--initialization of the wifi stuff

--start wifi statemachine
 if "1"==cfg.valid then
  wifi_sm_set(WIFI_SM_CLNC)

--start connection wait timeout timer
  wifi_cl_timer:start()
  wifi_start_client(cfg)
 else
  wifi_sm_set(WIFI_SM_APNC)
  wifi_start_ap()
 end

-- start TCP server
 srv=net.createServer(net.TCP)
 srv:listen(80,function(conn)
  conn:on("receive", web_receiver)
  conn:on("sent", function(conn) conn:close() end)
  collectgarbage()
 end)
 collectgarbage()
end
