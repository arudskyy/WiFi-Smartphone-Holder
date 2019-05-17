-- configuration stuff
-- global table, keeps configuration
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



print("1")
cfg_print()
cfg_get()
print("2")
cfg_print()
cfg_set()
print("3")
cfg_print()
cfg_get()
print("4")
cfg_print()
cfg.ip="10.10"
cfg.valid="1"
print("5")
cfg_print()
cfg_set()
print("6")
cfg_print()

cfg_get()
print("7")
cfg_print()
-- cfg_reset()
print("8")
cfg_print()
cfg_get()
print("9")
cfg_print()
-- end configuration


function wifi_client_set(nw_acc, nw_set)
--use station mode, where the device joins an existing network
-- nw_acc is a table with "ssid" and "pass" elements
-- nw_set is optional IP-settings that device will use after a new connection established
-- nw_set is a table with "ip", "nwm" and "gw" elements

-- mode 
 wifi.setmode(wifi.STATION)
-- IP settings
 if (nw_set ~= nil)then
  wifi.sta.setip({ip=nw_set.ip,netmask=nw_set.nwm,gateway=nw_set.wg})        
 end

--wifi network settings
 station_cfg={}
 station_cfg.ssid=nw_acc.ssid
 station_cfg.pwd=nw_acc.pass
 station_cfg.save=false

 wifi.sta.config(station_cfg)

 print(wifi.sta.getip())
	
 collectgarbage();
end


function wifi_client_set_users()
 nw_set = {ip="192.168.0.8",nwm="255.255.255.0",gw="192.168.0.1"}
 nw_acc = {ssid="NETGEAR2G", pass="artemolga"}
 wifi_client_set(nw_acc, nw_set)
 collectgarbage();
end


-- mDNS stuff (#13): register mDNS if IP-address assigned
wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
--print("\n\tSTA - GOT IP".."\n\tStation IP: "..T.IP.."\n\tSubnet mask: "..T.netmask.."\n\tGateway IP: "..T.gateway)
 mdns.register("smartphoneholder", { service="http", port=80 })
end)


--wifi_client_set_defaults()
wifi_client_set_users()

-- DEBUG stuff
wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
 print("\n\tSTA - CONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..
 T.BSSID.."\n\tChannel: "..T.channel)
end)


function cntrl_pos(par)
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

head="HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n";
head=head..[[<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"><title>WiFi Smartphone Holder</title></head> <body>]];
head=head.."<a href=\ctrl><button>Control</button></a><a href=\set><button>Settings</button></a><a href=\status><button>Status</button></a>";

function cntrl_web(client)
--http answer to control
 local buf=head..[[<style type="text/css"> button{font-size: 200%;} </style>]];
 buf = buf.."<h1>Control 3</h1><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <a href=\"ctrl?pin=ON1\"><button>&nbsp;&nbsp;&uarr;&nbsp;&nbsp;</button></a></p>";
 buf = buf.."<p><a href=\"ctrl?pin=ON2\"><button>&nbsp;&larr;&nbsp;</button></a>&nbsp;&nbsp;<a href=\"ctrl?pin=OFF2\"><button>&nbsp;&rarr;&nbsp;</button></a></p>";
 buf = buf.."<p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <a href=\"ctrl?pin=OFF1\"><button>&nbsp;&nbsp;&darr;&nbsp;&nbsp;</button></a></p>";
 buf = buf.."</body> </html>";
 client:send(buf);
 collectgarbage();
end


function status_web(client)
--http answer to status
 local md,ssid,ip,nw,gw,ssid,mac;
 if(wifi.STATION==wifi.getmode())then
  md="Client"
  ip,nw,gw=wifi.sta.getip();
  ssid,_,_,_=wifi.sta.getconfig()
  mac=wifi.sta.getmac()
 elseif(wifi.SOFTAP==wifi.getmode())then
  md="Access point"
  ip,nw,gw=wifi.ap.getip();
  ssid,_,_,_=wifi.ap.getconfig()
  mac=wifi.ap.getmac()
 else
  md="unknown";
  ip=md;nw=md;gw=md;ssid=md;mac=md;
 end
 local buf=head.."<h1>Device status</h1><table>";
 buf = buf..[[<tr style="text-align:left"><th>WiFi mode:</th><th>]]..md.."</th></tr>";
 buf = buf..[[<tr style="text-align:left"><th>Network name:</th><th>]]..ssid.."</th></tr>";
 buf = buf..[[<tr style="text-align:left"><th>MAC:</th><th>]]..mac.."</th></tr>";
 buf = buf..[[<tr style="text-align:left"><th>Address:</th><th>]]..ip.."</th></tr>";
 buf = buf..[[<tr style="text-align:left"><th>Network mask:</th><th>]]..nw.."</th></tr>";
 buf = buf..[[<tr style="text-align:left"><th>Gateway:</th><th>]]..gw.."</th></tr></table></body></html>";
 client:send(buf);
 collectgarbage();
end


function set_web(client,par)
--http answer to set
 local bk_err=[[ style="background-color:#ffcccc;"]];

 local buf=head.."<h1>Client settings</h1><h2>Target network:</h2><table>";
 buf = buf.."<tr><th>Network name</th><th><input"..bk_err..[[id="ssid" type="text" size="15" value="]]..par.ssid..[["></th></tr>]];
 buf = buf..[[<tr><th>Password</th><th><input id=pass type="password" size="15" value="]]..par.pass..[["></th></tr></table><h2>IP settings:</h2><table>]];
 buf = buf..[[<tr><th>Address</th><th><input id="ip" type="text" size="15" value="]]..par.ip..[["></th></tr>]];
 buf = buf..[[<tr><th>Network mask</th><th><input id="nm" type="text" size="15" value="]]..par.nm..[["></th></tr>]];
 buf = buf..[[<tr><th>Gateway</th><th><input id="gw" type="text" size="15" value="]]..par.gw..[["></th></tr></table>]];
 buf = buf..[[<h2>Mode-indicator, LED colors:</h2><table>]];
 buf = buf..[[<tr><th>Client (user settings)</th><th><input id="ccu" type="color" value="]]..par.ccu..[["></th></tr>]];
 buf = buf..[[<tr><th>Client (default settings) </th><th><input id="ccd" type="color" value="]]..par.ccd..[["></th></tr>]];
 buf = buf..[[<tr><th>Access point</th><th><input id="cap" type="color" value="]]..par.cap..[["></th></tr></table>]];
 buf = buf..[[<br><br><button onClick="apply()">Apply</button>]];
 buf = buf..[[<script>function apply(){window.location="/set?ssid="+document.getElementById("ssid").value+"&pass="+document.getElementById("pass").value]];
 buf = buf..[[+"&ip="+document.getElementById("ip").value+"&nm="+document.getElementById("nm").value+"&gw="+document.getElementById("gw").value]];
 buf = buf..[[+"&ccu="+document.getElementById("ccu").value.slice(1)+"&ccd="+document.getElementById("ccd").value.slice(1)]];
 buf = buf..[[+"&cap="+document.getElementById("cap").value.slice(1);}</script></body></html>]];
 --buf = buf.."</body></html>";
 client:send(buf);
 collectgarbage();
end


-- HTTP web client, main function
function receiver(client,request)
print("receiver")
print(request)
--parse request to get method, action and arguments       
 local _, _, method, action, args = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");

 if(method == nil)then
--in case of empty request
  _, _, method, action = string.find(request, "([A-Z]+) (.+) HTTP");
 end
 local par = {}

 if (args ~= nil)then
--extract arguments
  for k, v in string.gmatch(args, "([%w.]+)=([%w.]+)&*") do
   par[k] = v
   print(k.."="..v)
  end
 end

print("method:", method, "act:",action, "args:",args)

-- main command switch
 if("/config"==action)then
  print("c o n f i g u r a t i o n")
 elseif("/set"==action)then
  print("s e t")
  if(nil==par["ssid"])then
   par["ssid"]="enter SSID";
  end
  par["pass"]="12345";
  par["ip"]="000.111.222.333";
  par["nm"]="000.111.222.333";
  par["gw"]="000.111.222.333";
  par["ccu"]="#00aa00";
  par["ccd"]="#003333";
  par["cap"]="#227799";
  set_web(client,par)
 elseif("/status"==action)then
  status_web(client)
 else
  cntrl_pos(par)
  cntrl_web(client)
 end

 collectgarbage();
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


