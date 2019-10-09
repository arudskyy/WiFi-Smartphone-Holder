-- web.lua: simplest HTTP web server implementation
-- dependency: config.lua, pos_cntrl.lua

--http answer to status.json
function web_status_json(client)
 local md,ssid,ip,nw,gw,ssid,mac,st,hp,rem,use
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
 -- additional parameters
 st=tostring(tmr.time())
 hp=node.heap()
 rem,use,_=file.fsinfo()

 --create here json file data
 client:send([[jd='["]]..md..[[","]]..ssid..[[","]]..mac..[[","]]..ip..[[","]]..nw..[[","]]..gw..[[","]]..hp..[[","]]..st..[[","]]..use..[[","]]..rem..[["]';]])
end


--http answer to set.json
function web_set_json(client)
 --create here json file data
 client:send([[jd='["]]..cfg.ssid..[[","]]..cfg.pass..[[","]]..cfg.ip..[[","]]..cfg.nm..[[","]]..cfg.gw..[[","#]]..cfg.cc..[[","#]]..cfg.cap..[["]';]])
end


--sends file content to web
function web_sendfile(client, filename)
 local bytes_send = 0

 if false==file.exists(filename) then
  print("web_sendfile: file not exists: "..filename)
  client:close()
  return
 end

 -- callback function confirms data sending
 local function web_sendfile_cnf(loc_socket)
  -- file exists? 
  if nil==file.open(filename,"r") then
   loc_socket:close()
   return
  end
   
  -- go to next position in the file to read 
  file.seek("set",bytes_send)
  -- read part of data and close the file 
  local fd = file.read(1460)
  file.close()
  
  if nil~=fd then
   --increment number of send bytes and send data
   bytes_send=bytes_send+string.len(fd)
   loc_socket:send(fd)
  else
   -- nothing to send, close socket
   loc_socket:close()
  end
  -- free memory
  fd=nil
  collectgarbage();

 end-- of callback function

 -- get Content-Type string depending on file extension:
 local fileext_type = {jpg="image/jpeg"}
 local cont_type = fileext_type[ filename:match("[^.]+$") ]
 if nil==cont_type then
  cont_type = "text/html"
 end
 -- send the http header
 client:send("HTTP/1.0 200 OK\r\nContent-type: "..cont_type.."\r\n\r\n", web_sendfile_cnf)
end


--http answer to apply
function web_apply(client,par)
 web_sendfile(client,"apply.html")
end


--http answer to reset
function web_reset(client)
 web_sendfile(client,"reset.html")
--reset delay required to report reset web page
 web_reset_timer=tmr.create()
 web_reset_timer:register(1000, tmr.ALARM_SINGLE, function()  node.restart() end )
 web_reset_timer:start()
end


--helper to check for correct ip-settings, returns false if settings are ok
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
 return r
end


--check answer to apply
function web_check_apply(client,par,save)
 local err_ip=false
 local err_gw=false
 local err_nm=false

 if(wifi.SOFTAP==wifi.getmode())then
  if par.ip~="" or par.nm~="" or par.gw~="" then
   err_ip=web_checkipvals(par.ip)
   err_gw=web_checkipvals(par.gw)
   err_nm=web_checkipvals(par.nm)
  end

--copy temporary parameters to configuration
  cfg.ssid=par.ssid;cfg.pass=par.pass;cfg.ip=par.ip;cfg.nm=par.nm;cfg.gw=par.gw;cfg.cc=par.cc;cfg.cap=par.cap;

--if table is not empty then some error ocured:call set one more time
  if err_ip or err_gw or err_nm then
   web_sendfile(client,"set_err.html")
  elseif save==false then
   web_sendfile(client,"set.html")
  else
--apply parameters
   web_apply(client,par)
--set config to valid
   cfg.valid="1"
   cfg_save()
  end
 else
  web_sendfile(client,"notallowed.html")
 end
end


-- helper: calls func(client, ...) on provided wifi mode, else reports web_notallowed web page
function web_call_onmode(client,func,mode,...)
  if(mode==wifi.getmode())then
   func(client,...)
  else
   web_sendfile(client,"notallowed.html")
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
 --print("request: "..action)
 if("/"==action or "/ctrl"==action or "/ctrl.html"==action)then
  poscontrol_cntrl(par)
  web_sendfile(client,"cntrl.html")

 elseif("/favicon.ico"==action)then
 -- ignore

 elseif("/status.json"==action)then
  web_status_json(client)

 elseif("/set.json"==action)then
  web_set_json(client)

 elseif("/set.html"==action)then
  web_call_onmode(client,web_sendfile,wifi.SOFTAP,"set.html")
  
  
 elseif("/apply.html"==action)then
  web_call_onmode(client,web_check_apply,wifi.SOFTAP,par,true)

 elseif("/cccolor"==action)then
  led_cntrl(par.cc,false)
  cfg.cc=par.cc --take over the color for the set page
  web_call_onmode(client,web_check_apply,wifi.SOFTAP,par,false)

 elseif("/capcolor"==action)then
  led_cntrl(par.cap,false)
  cfg.cap=par.cap --take over the color for the set page
  web_call_onmode(client,web_check_apply,wifi.SOFTAP,par,false)

 elseif("/clear"==action)then
  file.remove("cfg.txt")
  web_reset(client)
  
 elseif("/reset.html"==action)then
  web_call_onmode(client,web_reset,wifi.SOFTAP)

 elseif nil~=action then
  web_sendfile(client,action:sub(2))

 else
  client:close()
 end

 collectgarbage();
end
