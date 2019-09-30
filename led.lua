-- led.lua: led controller
-- dependency: poscontrol (initializes PWM frequency)

ledR_pin = 5
ledG_pin = 7
ledB_pin = 8

gpio.mode(ledR_pin, gpio.OUTPUT)
gpio.write(ledR_pin, gpio.LOW)

gpio.mode(ledG_pin, gpio.OUTPUT)
gpio.write(ledG_pin, gpio.LOW)

gpio.mode(ledB_pin, gpio.OUTPUT)
gpio.write(ledB_pin, gpio.LOW)

ledR_duty = 400
ledG_duty = ledR_duty
ledB_duty = ledR_duty
led_blnk=0
--same PWM freq was configured in the poscontrol module
led_freq = 300
pwm.setup(ledR_pin,led_freq,ledR_duty)
pwm.setup(ledG_pin,led_freq,ledG_duty)
pwm.setup(ledB_pin,led_freq,ledB_duty)
pwm.start(ledR_pin)
pwm.start(ledG_pin)
pwm.start(ledB_pin)


-- PWM, led controller
function led_cntrl(rgb_str, blnk)
print(rgb_str, blnk)
 led_blnk=blnk

--convert str to number
 num=tonumber(rgb_str,16)
--no shift operation
 r=num/65536
 g=(num/256)-(r*256)
 b=num-(r*65536)-(g*256)

--store values
 ledR_duty=r*4
 ledG_duty=g*4
 ledB_duty=b*4

 if true==blnk then
  --led_flsh_timer:start()
 else
  --led_flsh_timer:stop()
  led_invalidate()
 end

 collectgarbage();
end


--slow flashing implementation
led_flsh_dir=1
led_flsh_duty_max=200
led_flsh_duty_step=2
led_flsh_duty=led_flsh_duty_max-led_flsh_duty_step




--calculates intensity for flashing
function led_flsh_intens(clr)
 return ((clr*led_flsh_duty)/led_flsh_duty_max)
end


-- led state invalid, function updates it 
function led_invalidate()
 if true==led_blnk then
  r=led_flsh_intens(ledR_duty)
  g=led_flsh_intens(ledG_duty)
  b=led_flsh_intens(ledB_duty)
 else
  r=ledR_duty
  g=ledG_duty
  b=ledB_duty
 end

 pwm.setduty(ledR_pin, r)
 pwm.setduty(ledG_pin, g)
 pwm.setduty(ledB_pin, b)

 collectgarbage();
end
