----configuration stuff
--global table, keeps configuration
cfg={valid="0", file="cfg.txt"}

function cfg_get()
 if file.open(cfg.file, "r") then
--extract arguments
  while true do
   fl=file.readline()
   if nil==fl then break end
   for k, v in string.gmatch(fl, "(%w+)=([%w.]+)") do
    cfg[k] = v
   end
  end
  file.close()
 end
 if "0"==cfg.valid then
--default values
  cfg.ssid="enter SSID"
  cfg.pass="password"
  cfg.ip="192.168.1.10"
  cfg.nm="255.255.255.0"
  cfg.gw="192.168.1.1"
  cfg.cc="0000ff"
  cfg.cap="00ff00"
 end
 collectgarbage()
end

function cfg_save()
 if file.open(cfg.file, "w") then
  for key,value in pairs(cfg) do
   file.writeline(key.."="..value..";")
  end
  file.close()
 end
end

function cfg_print()
 print("___Configuration________")
 for key,value in pairs(cfg) do print(key,value) end
 print("________________________")
end

function cfg_reset()
cfg.valid="0"
 if file.exists(cfg.file) then
  file.remove(cfg.file)
 end
end
----end configuration

----wifi modes
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
 local ap_cfg={}
 ap_cfg.ssid="WIFI Smartphone holder"
 ap_cfg.pwd="smartholder"
 wifi.ap.config(ap_cfg)
 collectgarbage()
end


-- mDNS stuff: register mDNS if IP-address assigned
wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
 mdns.register("smartphoneholder", { service="http", port=80 })
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
 collectgarbage()
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

----end wifi modes


function pos_cntrl(par)
--position controller
 print("position_ctrl:",par.pin)

 if(par.pin == "ON1")then
  if led1_pwm>100 then led1_pwm = led1_pwm - 13 end
 elseif(par.pin == "OFF1")then
  if led1_pwm<200 then led1_pwm = led1_pwm + 13 end
 elseif(par.pin == "ON2")then
  if led2_pwm>100 then led2_pwm = led2_pwm - 13 end
 elseif(par.pin == "OFF2")then
  if led2_pwm<200 then led2_pwm = led2_pwm + 13 end
 end
       
 collectgarbage();
end

----HTTP interface
head="HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n"
head=head..[[<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"><title>WiFi Smartphone Holder</title></head> <body>]]
head=head.."<a href=\ctrl><button>Control</button></a><a href=\set><button>Settings</button></a><a href=\status><button>Status</button></a>"

--http answer to control
function web_cntrl(client)
 local buf=head..[[<style type="text/css"> button{font-size: 200%;} </style>]];
 buf=buf.."<h1>Control</h1><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <a href=\"ctrl?pin=ON1\"><button>&nbsp;&nbsp;&uarr;&nbsp;&nbsp;</button></a></p>";
 buf=buf.."<p><a href=\"ctrl?pin=ON2\"><button>&nbsp;&larr;&nbsp;</button></a>&nbsp;&nbsp;<a href=\"ctrl?pin=OFF2\"><button>&nbsp;&rarr;&nbsp;</button></a></p>";
 buf=buf.."<p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <a href=\"ctrl?pin=OFF1\"><button>&nbsp;&nbsp;&darr;&nbsp;&nbsp;</button></a></p>";
 buf=buf.."</body> </html>";
 client:send(buf);
 collectgarbage();
end

--http answer to status
function web_status(client)
 local md,ssid,ip,nw,gw,ssid,mac
 if(wifi.STATION==wifi.getmode())then
  md="Client"
  ip,nw,gw=wifi.sta.getip()
  ssid,_,_,_=wifi.sta.getconfig()
  mac=wifi.sta.getmac()
 elseif(wifi.SOFTAP==wifi.getmode())then
  md="Access point"
  ip,nw,gw=wifi.ap.getip()
  ssid,_,_,_=wifi.ap.getconfig()
  mac=wifi.ap.getmac()
 else
  md="unknown"
  ip=md;nw=md;gw=md;ssid=md;mac=md;
 end
 local buf=head.."<h1>Device status</h1><table>"
 buf=buf..[[<tr style="text-align:left"><th>WiFi mode:</th><th>]]..md.."</th></tr>"
 buf=buf..[[<tr style="text-align:left"><th>Network name:</th><th>]]..ssid.."</th></tr>"
 buf=buf..[[<tr style="text-align:left"><th>MAC:</th><th>]]..mac.."</th></tr>"
 buf=buf..[[<tr style="text-align:left"><th>Address:</th><th>]]..ip.."</th></tr>"
 buf=buf..[[<tr style="text-align:left"><th>Network mask:</th><th>]]..nw.."</th></tr>"
 buf=buf..[[<tr style="text-align:left"><th>Gateway:</th><th>]]..gw.."</th></tr></table></body></html>"
 client:send(buf)
 collectgarbage()
end

--http answer to set
function web_set(client,par,err)
 local buf=head.."<h1>Client settings</h1><h2>Target network:</h2><table>"
 buf=buf..[[<tr><th>Network name</th><th><input id="ssid" type="text" size="15" value="]]..par.ssid..[["></th></tr>]]
 buf=buf..[[<tr><th>Password</th><th><input id=pass type="password" size="15" value="]]..par.pass..[["></th></tr></table><h2>IP settings:</h2><table>]]
 buf=buf.."<tr><th>Address</th><th><input "
 buf=buf..[[id="ip" type="text" size="15" value="]]..par.ip..[["></th></tr><tr><th>Network mask</th><th><input ]]
 buf=buf..[[id="nm" type="text" size="15" value="]]..par.nm..[["></th></tr><tr><th>Gateway</th><th><input ]]
 buf=buf..[[id="gw" type="text" size="15" value="]]..par.gw..[["></th></tr></table>]]
 client:send(buf)
 buf=[[<h2>Mode-indicator, LED colors:</h2><table>]]
 buf=buf..[[<tr><th>Client </th><th><input id="cc" type="color" value="#]]..par.cc..[["></th></tr>]]
 buf=buf..[[<tr><th>Access point</th><th><input id="cap" type="color" value="#]]..par.cap..[["></th></tr></table>]]
 buf=buf..[[<br><br><button onClick="apply()">Apply</button>]]
 buf=buf..[[<script>function apply(){window.location="/apply?ssid="+document.getElementById("ssid").value+"&pass="+document.getElementById("pass").value]]
 buf=buf..[[+"&ip="+document.getElementById("ip").value+"&nm="+document.getElementById("nm").value+"&gw="+document.getElementById("gw").value]]
 buf=buf..[[+"&cc="+document.getElementById("cc").value.slice(1)+"&cap="+document.getElementById("cap").value.slice(1);}</script></body></html>]]
 client:send(buf)
 collectgarbage()
end

--http answer to apply
function web_apply(client,par)
 local buf=head.."<h1>Client settings</h1><h2>Stored successfully!</h2><h2>Reset device to apply.</h2></body></html>"
 client:send(buf)
 collectgarbage()
end

--http answer to set and apply in Client mode
function web_notallowed(client)
 local buf=head..[[<h2 style="color:red;">Functionality not available in Client mode</h2></body></html>]]
 client:send(buf)
 collectgarbage()
end


function checkip(ip)
 local r=true
 if nil~=string.match(ip,'^[1-9]%d*%.%d*%.%d*%.%d*$') then
  local t = string.gmatch(ip,'([1-9]%d*)%.(%d*)%.(%d*)%.(%d*)$')
  local x,y,v,w=t()
  a=tonumber(x);b=tonumber(y);c=tonumber(v);d=tonumber(w)
  if a<256 and b<256 and c<256 and d<256  then
   r=false
  end
 end
 collectgarbage()
 return r;
end

-- HTTP web client, main function
function receiver(client,request)
--print(request)
--parse request to get method, action and arguments       
 local _, _, method, action, args = string.find(request, "([A-Z]+) (.+)?(.+) HTTP")

 if(method == nil)then
--in case of empty request
  _, _, method, action = string.find(request, "([A-Z]+) (.+) HTTP")
 end
 local par = {}

 if (args ~= nil)then
--extract arguments
  for k, v in string.gmatch(args, "([%w.]+)=([%w.%%]*)&*") do
   par[k],_ = string.gsub(v, "%%20", " ")
   print(k.."="..par[k])
  end
 end
--print("method:", method, "act:",action, "args:",args)

 local err={}
-- main command switch
 if("/set"==action)then
  if(wifi.SOFTAP==wifi.getmode())then
   if "0"==cfg.valid then
    err.ip=true;err.nm=true;err.gw=true
   end
   web_set(client,cfg,err)
  else
   web_notallowed(client)
  end

 elseif("/apply"==action)then
  if(wifi.SOFTAP==wifi.getmode())then
   if par.ip~="" or par.nm~="" or par.gw~="" then
    if checkip(par.ip) then err.ip=true end
    if checkip(par.nm) then err.nm=true end
    if checkip(par.gw) then err.gw=true end
   end
--if table is not empty then some error ocured:call set one more time
   if next(err)~=nil then
    web_set(client,par,err)
   else
--apply parameters
    web_apply(client,par)
--copy parameters to configuration and store they
    cfg.ssid=par.ssid;cfg.pass=par.pass;cfg.ip=par.ip;cfg.nm=par.nm;cfg.gw=par.gw;cfg.cc=par.cc;cfg.cap=par.cap;cfg.valid="1"
    cfg_save()
   end
  else
   web_notallowed(client)
  end

 elseif("/status"==action)then
  web_status(client)

 elseif("/"==action or "/ctrl"==action)then
  pos_cntrl(par)
  web_cntrl(client)
 else
  print("unsupported request: "..action)
 end

 collectgarbage();
end
----end of HTTP interface


---MAIN---
-- get stored configuration
cfg_get()
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
print(node.heap())
srv:listen(80,function(conn)
 conn:on("receive", receiver)
 conn:on("sent", function(conn) conn:close() end)
 collectgarbage();
end)


-- PWM, motor controller
led1 = 1
led1_pwm = 150
led1_pwm_c = 150
led1_pwm_status = 1
led2 = 2
led2_pwm = 150
led2_pwm_c = 150
led2_pwm_status = 1
pwm.setup(led1,100,led1_pwm)
pwm.start(led1)
pwm.setup(led2,100,led2_pwm)
pwm.start(led2)

mytimer = tmr.create()

mytimer:register(20, tmr.ALARM_AUTO, function() 
    if led1_pwm_c==led1_pwm then
        if led1_pwm_status==1 then
            pwm.stop(led1)
            led1_pwm_status = 0
        end
    else
        if led1_pwm_c<led1_pwm then led1_pwm_c = led1_pwm_c + 1 end
        if led1_pwm_c>led1_pwm then led1_pwm_c = led1_pwm_c - 1 end
        pwm.setduty(led1,led1_pwm_c)
        if led1_pwm_status==0 then
            pwm.start(led1)
            led1_pwm_status = 1
        end
    end
    
    if led2_pwm_c==led2_pwm then
        if led2_pwm_status==1 then
            pwm.stop(led2)
            led2_pwm_status = 0
        end
    else
        if led2_pwm_c<led2_pwm then led2_pwm_c = led2_pwm_c + 1 end
        if led2_pwm_c>led2_pwm then led2_pwm_c = led2_pwm_c - 1 end
        pwm.setduty(led2,led2_pwm_c)
        if led2_pwm_status==0 then
            pwm.start(led2)
            led2_pwm_status = 1
        end
    end

end)
mytimer:start()
