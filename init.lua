function receiver(client,request)
        print(request)
        print(node.heap())
        
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

wifi.setmode(wifi.STATION)
--wifi.sta.setip({ip="192.168.178.200",netmask="255.255.255.0",gateway="192.168.178.1"})
wifi.sta.setip({ip="192.168.0.8",netmask="255.255.255.0",gateway="192.168.0.1"})

station_cfg={}
station_cfg.ssid="NETGEAR2G"
station_cfg.pwd="********"
station_cfg.save=false
wifi.sta.config(station_cfg)

print(wifi.sta.getip())

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

srv=net.createServer(net.TCP)
print(node.heap())
srv:listen(80,function(conn)
    conn:on("receive", receiver)
    conn:on("sent", function(conn) conn:close() end)
    collectgarbage();
    end)
