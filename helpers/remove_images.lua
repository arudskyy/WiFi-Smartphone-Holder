function rm_img(a,z)
 while a<=z do
   file.remove(tostring(a)..".jpg")
   print("removed "..tostring(a)..".jpg")
   a=a+1
 end
end