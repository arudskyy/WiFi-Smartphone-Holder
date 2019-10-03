-- poscontrol.lua: position controller
-- dependency: no

step1_pin = 1
dir1_pin = 2
en1_pin = 0

step2_pin = 12
dir2_pin = 4
en2_pin = 6

step_freq = 300

gpio.mode(dir1_pin, gpio.OUTPUT)
gpio.write(dir1_pin, gpio.LOW)

gpio.mode(en1_pin, gpio.OUTPUT)
gpio.write(en1_pin, gpio.HIGH)

gpio.mode(dir2_pin, gpio.OUTPUT)
gpio.write(dir2_pin, gpio.HIGH)

gpio.mode(en2_pin, gpio.OUTPUT)
gpio.write(en2_pin, gpio.HIGH)


pwm.setup(step1_pin,step_freq,512)
pwm.setup(step2_pin,step_freq,512)


mytimer1 = tmr.create()

mytimer1:register(300, tmr.ALARM_SEMI, function()
    pwm.stop(step1_pin)
    gpio.write(en1_pin, gpio.HIGH)
end)

mytimer2 = tmr.create()

mytimer2:register(1000, tmr.ALARM_SEMI, function()
    pwm.stop(step2_pin)
    gpio.write(en2_pin, gpio.HIGH)
    gpio.write(dir2_pin, gpio.HIGH)
end)


-- PWM, motor controller
function poscontrol_cntrl(par)
--position controller
 --print("poscontrol_cntrl called with:",par.pin)

 if(par~=nil) then
 if(par.pin == "ON1")then
  gpio.write(dir1_pin, gpio.LOW)
  gpio.write(en1_pin, gpio.LOW)
  pwm.start(step1_pin)

  mytimer1:stop()
  mytimer1:start()
              
 elseif(par.pin == "OFF1")then
  gpio.write(dir1_pin, gpio.HIGH)
  gpio.write(en1_pin, gpio.LOW)
  pwm.start(step1_pin)

  mytimer1:stop()
  mytimer1:start()
              
 elseif(par.pin == "ON2")then
  gpio.write(dir2_pin, gpio.HIGH)
  gpio.write(en2_pin, gpio.LOW)
  pwm.start(step2_pin)

  mytimer2:stop()
  mytimer2:start()
              
 elseif(par.pin == "OFF2")then
  gpio.write(dir2_pin, gpio.LOW)
  gpio.write(en2_pin, gpio.LOW)
  pwm.start(step2_pin)

  mytimer2:stop()
  mytimer2:start()
 end
 end
end
