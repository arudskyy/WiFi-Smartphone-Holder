-- poscontrol.lua: position controller
-- dependency: no


-- PWM, motor controller
function poscontrol_cntrl(par)
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


function poscontrol_init()
end

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
