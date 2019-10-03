-- web.lua: simplest HTTP web server implementation
-- dependency: config.lua, pos_cntrl.lua

--http answer to control
function web_cntrl(client)
 web_sendfile(client,"head.html")
 web_sendfile(client,"cntrl.html")
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

 web_sendfile(client,"head.html")
 local buf="<h1>Device status</h1><table>"
 buf=buf..[[<tr style="text-align:left"><th>WiFi mode:</th><th>]]..md.."</th></tr>"
 buf=buf..[[<tr style="text-align:left"><th>Network name:</th><th>]]..ssid.."</th></tr>"
 buf=buf..[[<tr style="text-align:left"><th>MAC:</th><th>]]..mac.."</th></tr>"
 buf=buf..[[<tr style="text-align:left"><th>Address:</th><th>]]..ip.."</th></tr>"
 buf=buf..[[<tr style="text-align:left"><th>Network mask:</th><th>]]..nw.."</th></tr>"
 buf=buf..[[<tr style="text-align:left"><th>Gateway:</th><th>]]..gw.."</th></tr></table></body></html>"
 --buf=buf..[[<tr style="text-align:left"><th>Heap:</th><th>]]..tostring(node.heap()).."</th></tr></table></body></html>"
 client:send(buf)
 --collectgarbage()
end


--http answer to set
function web_set(client,par,err)
 local bk_err=[[style="background-color:#ffcccc;"]]

 web_sendfile(client,"head.html")
 
 local buf="<h1"

 if(web_checktable(err))then buf = buf..[[ style="color:red;">Not entered valid c]]
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
 client:send(buf)
 buf = [[<h2>Mode-indicator, LED colors:</h2><table>]]
 buf = buf..[[<tr><th>Client </th><th><input id="cc" onchange="command('cccolor')" type="color" value="#]]..par.cc..[["></th></tr>]]
 buf = buf..[[<tr><th>Access point</th><th><input id="cap" onchange="command('capcolor')" type="color" value="#]]..par.cap..[["></th></tr></table>]]
 buf = buf..[[<br><br><button onClick="command('apply')">Apply</button>]]
 buf = buf..[[<script>function command(p){window.location="/"+p+"?ssid="+document.getElementById("ssid").value+"&pass="+document.getElementById("pass").value]]
 buf = buf..[[+"&ip="+document.getElementById("ip").value+"&nm="+document.getElementById("nm").value+"&gw="+document.getElementById("gw").value]]
 buf = buf..[[+"&cc="+document.getElementById("cc").value.slice(1)+"&cap="+document.getElementById("cap").value.slice(1);}]]
 buf = buf..[[</script></body></html>]]
 client:send(buf)
 --collectgarbage()
end


--sends file content to web
function web_sendfile(client, filename)
 local _line
 if file.open(filename,"r") then
  repeat _line = file.readline()
   if (_line~=nil) then
    --client:send(string.sub(_line,1,-2))
    client:send(_line)
   end
  until _line==nil
  file.close()
 else
  print("web_sendfile: can't open file: "..filename)
 end
end


--http answer to apply
function web_apply(client,par)
 web_sendfile(client,"head.html")
 web_sendfile(client,"apply.html")
end


--http answer to reset
function web_reset(client)
 web_sendfile(client,"head.html")
 client:send("<h1>Device is resetting</h1></body></html>")
--reset delay required to report reset web page
 web_reset_timer=tmr.create()
 web_reset_timer:register(1000, tmr.ALARM_SINGLE, function()  node.restart() end )
 web_reset_timer:start()
end


--helper to check for correct ip-settings
function web_checkipvals(ip)
 local r=true
 if nil~=string.match(ip,'^[1-9]%d*%.%d*%.%d*%.%d*$') then
  local t = string.gmatch(ip,'([1-9]%d*)%.(%d*)%.(%d*)%.(%d*)$')
  local x,y,v,w=t()
  local a,b,c,d
  a=tonumber(x);b=tonumber(y);c=tonumber(v);d=tonumber(w)
  if a<256 and b<256 and c<256 and d<255  then
   r=false
  end
 end
 --collectgarbage()
 return r
end



--check answer to apply
function web_check_apply(client,par,save)
 local err={}
 if(wifi.SOFTAP==wifi.getmode())then
  if par.ip~="" or par.nm~="" or par.gw~="" then
   err.ip=web_checkipvals(par.ip)
   err.gw=web_checkipvals(par.gw)
   err.nm=web_checkipvals(par.nm)
  end
--if table is not empty then some error ocured:call set one more time
  if web_checktable(err) or save==false then
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
 --collectgarbage()
end


--http answer to set and apply in Client mode
function web_notallowed(client)
 web_sendfile(client,"head.html")
 client:send([[<h2 style="color:red;">Functionality not available in Client mode</h2></body></html>]])
end


-- helper: returns true if table contains any not 'false' element
function web_checktable(err)
 local r=false
 for _,v in pairs(err) do if v then r=true break end end
 return r
end


-- helper: calls func(client, ...) on provided wifi mode, else reports web_notallowed web page
function web_call_onmode(client,func,mode,...)
  if(mode==wifi.getmode())then
   func(client,...)
  else
   web_notallowed(client)
  end
end



-- HTTP web client, dispatcher function 
function web_receiver(client,request)
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
   --print(k.."="..par[k])
  end
 end

-- main command switch
 if("/"==action or "/ctrl"==action)then
  poscontrol_cntrl(par)
  web_cntrl(client)

 elseif("/status"==action)then
  web_status(client)

 elseif("/set"==action)then
  local err={}
--initially mark all fields like an error 
  if "0"==cfg.valid then err.ip=true;err.nm=true;err.gw=true end
   web_call_onmode(client,web_set,wifi.SOFTAP,cfg,err)
  
  elseif("/apply"==action)then
   web_call_onmode(client,web_check_apply,wifi.SOFTAP,par,true)

 elseif("/cccolor"==action)then
  led_cntrl(par.cc,false)
  web_call_onmode(client,web_check_apply,wifi.SOFTAP,par,false)

 elseif("/capcolor"==action)then
  led_cntrl(par.cap,false)
  web_call_onmode(client,web_check_apply,wifi.SOFTAP,par,false)

 elseif("/clear"==action)then
  file.remove("cfg.txt")
  web_reset(client)
  
 elseif("/reset"==action)then
  web_call_onmode(client,web_reset,wifi.SOFTAP)

 --elseif("/t"==action)then
 -- print("..test..")
 --else
  --print("unsupported request: "..action)
 end

 collectgarbage();
end
