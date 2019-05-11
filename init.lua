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

-- (#5)
function wifi_client_set_defaults()
 nw_acc = {ssid="WIFI-NETWORK", pass="12345678"}
 wifi_client_set(nw_acc)
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
  ssid,_,_,mac=wifi.sta.getconfig()
 elseif(wifi.SOFTAP==wifi.getmode())then
  md="Access point"
  ip,nw,gw=wifi.ap.getip();
  ssid,_,_,mac=wifi.ap.getconfig()
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
 local buf=head.."<h1>Client settings</h1><h2>Target network:</h2><table>";
 buf = buf..[[<tr><th>Network name</th><th><input id="ssid" type="text" size="15" value="]]..par.ssid..[["></th></tr>]];
 buf = buf..[[<tr><th>Password</th><th><input type="password" size="15" value="]]..par.pass..[["></th></tr></table><h2>IP settings:</h2><table>]];
 buf = buf..[[<tr><th>Address</th><th><input id="ip" type="text" size="15" value="]]..par.ip..[["></th></tr>]];
 buf = buf..[[<tr><th>Network mask</th><th><input id="nm" type="text" size="15" value="]]..par.nm..[["></th></tr>]];
 buf = buf..[[<tr><th>Gateway</th><th><input id="gw" type="text" size="15" value="]]..par.gw..[["></th></tr></table></body></html>]];
 buf = buf..[[<button onClick="reply()">Apply</button>]];
 buf = buf..[[<script>function reply(){window.location="/set?ssid="+document.getElementById("ssid").value+"&ip="+document.getElementById("ip").value;}</script>]];
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
  for k, v in string.gmatch(args, "(%w+)=(%w+)&*") do
   par[k] = v
  end
 end

print("method:", method, "act:",action, "args:",args)

-- main command switch
 if("/config"==action)then
  print("c o n f i g u r a t i o n")
 elseif("/set"==action)then
  print("s e t")
  par["ssid"]="SSSS";
  par["pass"]="*****";
  par["ip"]="000.111.222.333";
  par["nm"]="000.111.222.333";
  par["gw"]="000.111.222.333";
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


