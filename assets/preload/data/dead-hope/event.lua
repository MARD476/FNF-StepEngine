local maxAlpha = 1  
local minAlpha = 0.2         
local tiempoOscurecer = 1.4  
local alphaActual = 1

local stopp = false

function onCreatePost()
posePositionGOD(180,280, 170,277, 180,330, 80,230, 185,275)
posePositionGODBF(895,350, 827,248, 837,247, 820,250, 830,246)
posePositionGODGF(320,130, 280,120, 300,170, 300,100, 330,155)
				 setProperty("gifScaleX", 2)

				 setProperty("healthBar.visible", false)
				 setProperty("iconP1.visible", false)
				 setProperty("iconP2.visible", false)
				 setProperty("scoreTxt.visible", false)
				 setProperty("camHUD.visible", false)

    makeLuaSprite('cuadroNegro', '', -500, -200)
    makeGraphic('cuadroNegro', screenWidth + 2000, screenHeight + 1000, '000000')
    setObjectCamera('cuadroNegro', 'game')
    setProperty('cuadroNegro.alpha', alphaActual)
    
    addLuaSprite('cuadroNegro', true)

    makeLuaSprite('cuadroNegro2', '', -500, -200)
    makeGraphic('cuadroNegro2', screenWidth + 2000, screenHeight + 1000, '000000')
    setObjectCamera('cuadroNegro2', 'hud')
    setProperty('cuadroNegro2.alpha', alphaActual)
	setProperty('cuadroNegro2.visible', false)
    addLuaSprite('cuadroNegro2', true)
end 

function onUpdatePost(elapsed)
	if stopp == false then

    if alphaActual < maxAlpha then
        alphaActual = alphaActual + (elapsed / tiempoOscurecer)
        if alphaActual > maxAlpha then 
            alphaActual = maxAlpha 
        end
        setProperty('cuadroNegro.alpha', alphaActual)
		setProperty('cuadroNegro2.alpha', alphaActual)
    end
	
end
end

function onStepHit()
	if curStep == 120 then
		stopp = true
		alphaActual = 0
	end
	 if curStep == 121 then setProperty('cuadroNegro.alpha', 1) end
	 if curStep == 122 then setProperty('cuadroNegro.alpha', 0) end
	 if curStep == 123 then setProperty('cuadroNegro.alpha', 1) end
	 if curStep == 124 then setProperty('cuadroNegro.alpha', 0) end
	 if curStep == 125 then setProperty('cuadroNegro.alpha', 1) end
	 if curStep == 126 then setProperty('cuadroNegro.alpha', 0) end
	 if curStep == 127 then setProperty('cuadroNegro.alpha', 1) end
	 if curStep == 128 then setProperty('cuadroNegro.alpha', 0) end
	 if curStep == 129 then
		setProperty('cuadroNegro.visible', false)
		setProperty('cuadroNegro2.visible', true)
		setProperty("camHUD.visible", true)
		stopp = false
	    maxAlpha = 0.65 
		alphaActual = 0.2
		tiempoOscurecer = 2.4
	 end

	 if curStep == 464 then
		stopp = true
		setProperty('cuadroNegro2.visible', false)
						 setProperty("healthBar.visible", true)
				 setProperty("iconP1.visible", true)
				 setProperty("iconP2.visible", true)
				 setProperty("scoreTxt.visible", true)
	 end
end
function onBeatHit()
	if stopp == false then
	if curBeat % 4 == 0 then
		    alphaActual = minAlpha
    setProperty('cuadroNegro.alpha', alphaActual)
	setProperty('cuadroNegro2.alpha', alphaActual)
	end
end
end