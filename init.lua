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
end

function cfg_set()
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
print("wifi_start_ap")
m=wifi.setmode(wifi.SOFTAP)
print("SOFTAP "..m.."/"..wifi.SOFTAP)
--
 local a,b,mac=wifi.ap.getmac()
 print(mac)
 --a,b=string.gmatch(mac,'([a-f0-9]+):([a-f0-9]+)$')
 --print(a,b)
 local ap_cfg={}
 ap_cfg.ssid="WIFI Smartphone holder " --..a..b
 print(ap_cfg.ssid)
 ap_cfg.pwd="smartholder"
 wifi.ap.config(ap_cfg)
 mac=wifi.ap.getmac()
 print(mac)
end


-- mDNS stuff: register mDNS if IP-address assigned
wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
 mdns.register("smartphoneholder", { service="http", port=80 })
end)
----end wifi modes


-- DEBUG stuff
wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
 print("\n\tSTA - CONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..T.BSSID.."\n\tChannel: "..T.channel)
end)


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

head="HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n"
head=head..[[<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"><title>WiFi Smartphone Holder</title></head> <body>]]
head=head.."<a href=\ctrl><button>Control</button></a><a href=\set><button>Settings</button></a><a href=\status><button>Status</button></a>"

function web_cntrl(client)
--http answer to control
 local buf=head..[[<style type="text/css"> button{font-size: 200%;} </style>]];
 buf = buf.."<h1>Control</h1><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <a href=\"ctrl?pin=ON1\"><button>&nbsp;&nbsp;&uarr;&nbsp;&nbsp;</button></a></p>";
 buf = buf.."<p><a href=\"ctrl?pin=ON2\"><button>&nbsp;&larr;&nbsp;</button></a>&nbsp;&nbsp;<a href=\"ctrl?pin=OFF2\"><button>&nbsp;&rarr;&nbsp;</button></a></p>";
 buf = buf.."<p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <a href=\"ctrl?pin=OFF1\"><button>&nbsp;&nbsp;&darr;&nbsp;&nbsp;</button></a></p>";
 buf = buf.."</body> </html>";
 client:send(buf);
 collectgarbage();
end


function web_status(client)
--http answer to status
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
 buf = buf..[[<tr style="text-align:left"><th>WiFi mode:</th><th>]]..md.."</th></tr>"
 buf = buf..[[<tr style="text-align:left"><th>Network name:</th><th>]]..ssid.."</th></tr>"
 buf = buf..[[<tr style="text-align:left"><th>MAC:</th><th>]]..mac.."</th></tr>"
 buf = buf..[[<tr style="text-align:left"><th>Address:</th><th>]]..ip.."</th></tr>"
 buf = buf..[[<tr style="text-align:left"><th>Network mask:</th><th>]]..nw.."</th></tr>"
 buf = buf..[[<tr style="text-align:left"><th>Gateway:</th><th>]]..gw.."</th></tr></table></body></html>"
 client:send(buf)
 collectgarbage()
end


function web_set(client,par,err)
--http answer to set
 local bk_err=[[style="background-color:#ffcccc;"]]

 local buf=head.."<h1"
 if(next(err))then buf = buf..[[ style="color:red;">Not entered valid c]]
 else buf = buf..">C" end
 buf = buf.."lient settings</h1><h2>Target network:</h2><table>"
 buf = buf..[[<tr><th>Network name</th><th><input id="ssid" type="text" size="15" value="]]..par.ssid..[["></th></tr>]]
 buf = buf..[[<tr><th>Password</th><th><input id=pass type="password" size="15" value="]]..par.pass..[["></th></tr></table><h2>IP settings:</h2><table>]]
 buf = buf.."<tr><th>Address</th><th><input "
 if(err.ip)then buf = buf..bk_err end
 buf = buf..[[id="ip" type="text" size="15" value="]]..par.ip..[["></th></tr><tr><th>Network mask</th><th><input ]]
 if(err.nm)then buf = buf..bk_err end
 buf = buf..[[id="nm" type="text" size="15" value="]]..par.nm..[["></th></tr><tr><th>Gateway</th><th><input ]]
 if(err.gw)then buf = buf..bk_err end
 buf = buf..[[id="gw" type="text" size="15" value="]]..par.gw..[["></th></tr></table>]]
 buf = buf..[[<h2>Mode-indicator, LED colors:</h2><table>]]
 buf = buf..[[<tr><th>Client </th><th><input id="cc" type="color" value="#]]..par.cc..[["></th></tr>]]
 buf = buf..[[<tr><th>Access point</th><th><input id="cap" type="color" value="#]]..par.cap..[["></th></tr></table>]]
 buf = buf..[[<br><br><button onClick="apply()">Apply</button>]]
 buf = buf..[[<script>function apply(){window.location="/apply?ssid="+document.getElementById("ssid").value+"&pass="+document.getElementById("pass").value]]
 buf = buf..[[+"&ip="+document.getElementById("ip").value+"&nm="+document.getElementById("nm").value+"&gw="+document.getElementById("gw").value]]
 buf = buf..[[+"&cc="+document.getElementById("cc").value.slice(1)+"&cap="+document.getElementById("cap").value.slice(1);}</script></body></html>]]
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
print("receiver")
print(request)
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

print("method:", method, "act:",action, "args:",args)

-- main command switch
 if("/set"==action)then
  local err={}
  if "0"==cfg.valid then
   err.ip=true;err.nm=true;err.gw=true
  end
  web_set(client,cfg,err)

 elseif("/apply"==action)then
  local err={}
  if par.ip==par.nm and par.ip==par.gw and par.ip=="" then
  else
   if checkip(par.ip) then err.ip=true end
   if checkip(par.nm) then err.nm=true end
   if checkip(par.gw) then err.gw=true end
  end
  web_set(client,par,err)

 elseif("/status"==action)then
  web_status(client)

 else
  pos_cntrl(par)
  web_cntrl(client)
 end

 collectgarbage();
end


--MAIN--
-- get stored configuration
cfg_get()
--wifi_client_set_defaults()
--wifi_client_set_users()
wifi_start_ap()
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


