function onStepHit()
    if not lowQuality and windowsModding then
    if curStep == 543 then
        popupWindowOpponent(550, 500, "fish") --80, -640 1300, 5
        changePositionOpp(600,4, 0.2)
    end

    if curStep == 606 then
        closeWindowOpp();
    end
    
    if curStep == 607 then
        popupWindowPlayer(550, 500, "pito")
        changePositionPla(600, 4, 0.2)
    end

    if curStep == 672 then
        closeWindowPla();
        closeWindowOpp();
    end
end
end

function onEvent(n, v1, v2)
    seconds = mysplit(v2, ',')
    if n == 'Move Window Dad' then
        if not lowQuality and windowsModding then
        changePositionOpp(v1, seconds[1], seconds[2])
        end
    end

    if n == 'Move Window Player' then
        if not lowQuality and windowsModding then
        changePositionPla(v1, seconds[1], seconds[2])
        end
    end
end

function mysplit (inputstr, sep)
   if sep == nil then
      sep = "%s"
   end
   local t={}
   for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		num = tonumber(str)
		table.insert(t, num)
   end
   return t
end