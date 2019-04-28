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


function wifi_client_set_defaults()
  nw_acc = {ssid="WIFI-NETWORK", pass="12345678"}
  wifi_client_set(nw_acc)
  collectgarbage();
end


function wifi_client_set_users()
  nw_set = {ip="192.168.0.8",nwm="255.255.255.0",gw="192.168.0.1"}
  nw_acc = {ssid="NETGEAR2G", pass="*****"}
  wifi_client_set(nw_acc, nw_set)
  collectgarbage();
end


--wifi_client_set_defaults()
wifi_client_set_users()

-- DEBUG stuff
wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
 print("\n\tSTA - CONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..
 T.BSSID.."\n\tChannel: "..T.channel)
end)

wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
 print("\n\tSTA - GOT IP".."\n\tStation IP: "..T.IP.."\n\tSubnet mask: "..
 T.netmask.."\n\tGateway IP: "..T.gateway)
end)



-- TCP/IP server, HTTP web client
function receiver(client,request)
        print("receiver")
        --print(node.heap())
        
        local buf = "";
        
        local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
        if(method == nil)then
            _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
        end
        local _GET = {}
        if (vars ~= nil)then
            for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
                _GET[k] = v
            end
        end

        local _on,_off = "",""
        if(_GET.pin == "ON1")then
              if led1_pwm>100 then led1_pwm = led1_pwm - 13 end
              --pwm.setduty(led1,led1_pwm)
        elseif(_GET.pin == "OFF1")then
              if led1_pwm<200 then led1_pwm = led1_pwm + 13 end
              --pwm.setduty(led1,led1_pwm)
        elseif(_GET.pin == "ON2")then
              if led2_pwm>100 then led2_pwm = led2_pwm - 13 end
        elseif(_GET.pin == "OFF2")then
              if led2_pwm<200 then led2_pwm = led2_pwm + 13 end
        end
        buf = buf.."HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n";
        --buf = buf.."Content-Type: text/html";
        --buf = buf.."\r\n";
        --buf = buf..[[<!DOCTYPE html>]];
        buf = buf..[[<html> <head> <meta http-equiv="Content-Type" content="text/html; charset=utf-8"> <title>Camera Control</title>]];
        buf = buf.."</head> <body>";
        buf = buf..[[<style type="text/css"> button{font-size: 200%;} </style>]];
        buf = buf.."<h1> Camera Control Web Server</h1>";
        buf = buf.."<p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <a href=\"?pin=ON1\"><button>&nbsp;&nbsp;&uarr;&nbsp;&nbsp;</button></a></p>";
        buf = buf.."<p><a href=\"?pin=ON2\"><button>&nbsp;&larr;&nbsp;</button></a>&nbsp;&nbsp;<a href=\"?pin=OFF2\"><button>&nbsp;&rarr;&nbsp;</button></a></p>";
        buf = buf.."<p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <a href=\"?pin=OFF1\"><button>&nbsp;&nbsp;&darr;&nbsp;&nbsp;</button></a></p>";
        buf = buf.."</body> </html>";
        
        --print(buf);
        client:send(buf);
        --client:close();
        collectgarbage();
end

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


