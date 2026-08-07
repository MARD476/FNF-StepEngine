local notaAlphaBase = 0 -- La opacidad cuando están "opacadas" (0.0 a 1.0)
local tiempoDesvanecer = 0.6 -- Qué tan rápido vuelve a opacarse el receptor después de un hit
local alphaActual = 0.25

local zoomStage = false

function onCreatePost() --defautl cam 0.85 -- 0.67
	--background boi
--stage1   
    for i = 0, 3 do
        setPropertyFromGroup('playerStrums', i, 'alpha', notaAlphaBase)
    end
tomokox = (getProperty('boyfriend.x') + 160)    
tomokoy = (getProperty('boyfriend.y') + 60) 

	makeLuaSprite('stage_red', 'deadHope/stageback', -300, -200);
	setLuaSpriteScrollFactor('stage_red', 1, 1);

		makeLuaSprite('stage_red2', 'deadHope/hospital_bg', -1160, -850);
	setLuaSpriteScrollFactor('stage_red2', 1, 1);

			makeLuaSprite('stage_red3', 'deadHope/BgPixel', 0, -70);
	setLuaSpriteScrollFactor('stage_red3', 1, 1);

		setProperty('stage_red3.scale.x', 1.8)
	setProperty('stage_red3.scale.y', 1.8)

				makeLuaSprite('stage_red4', 'Lies/difuminado', 0, 90);
	setLuaSpriteScrollFactor('stage_red4', 1, 1);
	setProperty('stage_red4.alpha', 0.7)

						makeLuaSprite('stage_red5', 'Lies/black', 0, 0);
			setProperty('stage_red5.scale.x', 75.1434438167878)
	setProperty('stage_red5.scale.y', 33.520590485465)
	setProperty('stage_red5.alpha', 0.76)

		makeLuaSprite('stage_red7', 'deadHope/RedVG', 0, 0);
		setObjectCamera('stage_red7', 'hud')
			--setProperty('dad.alpha', 0)
	--setProperty('gf.alpha', 0)
	--setProperty('boyfriend.visible', false)

								--setProperty('boyfriend.x', tomokox)
				--setProperty('boyfriend.y', tomokoy)

								 
	

	setProperty('stage_red2.visible', false)
	setProperty('stage_red.visible', false)
	setProperty('stage_red3.visible', false)
	setProperty('stage_red2.scale.x', 0.57)
	setProperty('stage_red.scale.y', 1.1)
	setProperty('stage_red2.scale.y', 0.57)
			setProperty('dad.scale.x', 0.86)
	setProperty('dad.scale.y', 0.86)
				setProperty('gf.scale.x', 0.86)
	setProperty('gf.scale.y', 0.86)
                 addLuaSprite('stage_red', false);
				 addLuaSprite('stage_red2', false);
				 addLuaSprite('stage_red3', false);
				 addLuaSprite('stage_red7', true);
				 setProperty("enableGifAnim", true)

end

function onStepHit()
		if curStep == 185 or curStep == 314 then
		destelloAclarar(0.9)

	end

	if curStep == 16 then
		setProperty('boyfriend.visible', true)
		setProperty('gf.visible', false)
		setProperty('dadGroup.visible', false)
	end

	if curStep == 32 then
		setProperty('boyfriend.visible', false)
		setProperty('gf.visible', true)
		setProperty('dadGroup.visible', true)
	end	setProperty('dad.visible', true)

	if curStep == 48 then
		setProperty('boyfriend.visible', true)
				setProperty('gf.visible', false)
		setProperty('dadGroup.visible', false)
end
	if curStep == 64 then
		setProperty('boyfriend.visible', false)
		setProperty('gf.visible', true)
		setProperty('dadGroup.visible', true)
end
		if curStep == 80 then
		setProperty('boyfriend.visible', true)
				setProperty('gf.visible', false)
		setProperty('dadGroup.visible', false)
end
	if curStep == 96 then
		setProperty('boyfriend.visible', false)
		setProperty('gf.visible', true)
		setProperty('dadGroup.visible', true)
end
		if curStep == 111 then
		setProperty('boyfriend.visible', true)
				setProperty('gf.visible', false)
		setProperty('dadGroup.visible', false)
end
		if curStep == 120 then
		setProperty('boyfriend.visible', true)
				setProperty('gf.visible', true)
		setProperty('dadGroup.visible', true)
end

	if  curStep == 128 then
		setProperty('stage_red.visible', true)
	end
	if curStep == 464 then
	--setProperty('boyfriend.visible', false)

	setProperty('dad.x', (getProperty('dad.x') + 30))
	setProperty('dad.y', (getProperty('dad.y') - 30))
	setProperty('gf.x', (getProperty('gf.x') + 30))
	setProperty('gf.y', (getProperty('gf.y') - 30))

		setProperty('stage_red.visible', false)
	setProperty('stage_red2.visible', true)
	end
	if curStep == 718 then
	setProperty('dad.x', (getProperty('dad.x') + 1))
	setProperty('dad.y', (getProperty('dad.y') + 40))
	setProperty('gf.x', (getProperty('gf.x')) - 40)
	setProperty('gf.y', (getProperty('gf.y') + 60))
	end

	if curStep == 720 then
		setProperty('stage_red2.visible', false)
		setProperty('stage_red3.visible', true)
		setProperty('dad.alpha', 0)
		setProperty('gf.alpha', 0)
		setProperty('boyfriend.alpha', 0) 
		tomokox = (getProperty('boyfriend.x') + 160)    
		tomokoy = (getProperty('boyfriend.y') + 60)  
		setProperty('boyfriend.x', tomokox)
		setProperty('boyfriend.y', tomokoy)
	end

	if curStep == 1501 then
		setProperty('camGame.visible', false)
	end

	if curStep == 1247 or curStep == 1407 then
		zoomStage = true
	end

	if curStep == 1343 or curStep == 1487 then
		zoomStage = false
	end
end

function onUpdate()
	if zoomStage then
		if mustHitSection == false then
			setProperty('defaultCamZoom', 0.7)
		else
			setProperty('defaultCamZoom', 0.9)
		end
	end
end