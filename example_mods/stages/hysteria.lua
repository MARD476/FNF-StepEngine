local mistStage = false
local shakeSection = false

function onCreatePost() --defautl cam 0.85 -- 0.67
	--background boi

	makeLuaSprite('stage_red', 'hysteria/servedOne', -670, -310);
	setLuaSpriteScrollFactor('stage_red', 0.9, 0.9);
			setProperty('stage_red.scale.x', 1.3)
	setProperty('stage_red.scale.y', 1.3)

		makeLuaSprite('stage_red2', 'hysteria/served', -670, -310);
	setLuaSpriteScrollFactor('stage_red2', 0.9, 0.9);
			setProperty('stage_red2.scale.x', 1.3)
	setProperty('stage_red2.scale.y', 1.3)

	setProperty('stage_red2.visible', false)

			makeLuaSprite('stage_red3', 'hysteria/mist', -670, -310);
	setLuaSpriteScrollFactor('stage_red3', 0.95, 0.95);

	setProperty('stage_red3.visible', false)

				makeLuaSprite('stage_red4', 'hysteria/redmist', -670, -310);
	setLuaSpriteScrollFactor('stage_red4', 0.95, 0.95);

	setProperty('stage_red4.visible', false)

								 
	

                 addLuaSprite('stage_red', false);
				 addLuaSprite('stage_red2', false);
				 addLuaSprite('stage_red3', false);
				 addLuaSprite('stage_red4', false);


end

function onUpdate()
	if mistStage then
		if mustHitSection == false then
			setProperty('defaultCamZoom', 0.7)
		else
			setProperty('defaultCamZoom', 0.95)
		end
	end
end

function onStepHit()
	if curStep == 351 then
		setProperty('stage_red.visible', false)
		setProperty('stage_red2.visible', true)
	end
	if curStep == 1664 then
		--setProperty('defaultZoom', 0.7)
		setProperty('boyfriend.x', (getProperty('boyfriend.x') - 120))
		setProperty('boyfriend.y', (getProperty('boyfriend.y') - 170))
		setProperty('dad.x', (getProperty('dad.x') + 90))
		setProperty('dad.y', (getProperty('dad.y') - 170))
		setProperty('gf.x', (getProperty('gf.x') + 130))
		setProperty('gf.y', (getProperty('gf.y') - 140))
		setProperty('stage_red2.visible', false)
		setProperty('stage_red3.visible', true)
		mistStage = true
	end
	if curStep == 2175 then
		mistStage = false
	end

	if curStep == 2191 then
		setProperty('boyfriend.visible', false)
		setProperty('gf.visible', false)
		setProperty('stage_red3.visible', false)
		setProperty('stage_red4.visible', true)
	end
	if curStep == 2208 then
		mistStage = true
		shakeSection = true
		setProperty('boyfriend.visible', true)
		setProperty('gf.visible', true)
	end

	if curStep == 2464 then
		--shakeSection = false
	end

	if curStep == 2591 then
		shakeSection = true
	end

	if curStep == 2719 then
		mistStage = false
		shakeSection = false
	end

	if curStep == 2735 then
		setProperty('stage_red4.visible', false)
		setProperty('stage_red3.visible', true)
	end

		if curStep >= 2463 and curStep <= 2591 then
		if curStep % 8 == 0 then
			doTweenY('rrr', 'camHUD', -5, stepCrochet*0.001, 'sineIn')
			doTweenY('rtr', 'camGame', 5, stepCrochet*0.001, 'sineIn')
		end
		if curStep % 8 == 2 then
			doTweenY('rir', 'camHUD', 0, stepCrochet*0.001, 'sineIn')
			doTweenY('ryr', 'camGame', 0, stepCrochet*0.001, 'sineIn')
		end
	end
end

function onSectionHit()
	if shakeSection then
		triggerEvent('Screen Shake', '0.5, 0.002', '0.5, 0.002')
	end
end




--{
	--"directory": "week1",
	--"defaultZoom": 0.590,
	--"stageUI": "",

	--"boyfriend": [920, 310],
	--"girlfriend": [360, 210],
	--"opponent": [-90, 310],
	--"hide_girlfriend": false,

	--"camera_boyfriend": [-160, -20],
	--"camera_opponent": [0, 0],
	--"camera_girlfriend": [0, 0],
	--"camera_speed": 3
--}


--{
	--"directory": "week1",
	--"defaultZoom": 0.7,
	--"stageUI": "",

	--"boyfriend": [800, 140],
	--"girlfriend": [490, 70],
	--"opponent": [0, 140],
	--"hide_girlfriend": false,

	--"camera_boyfriend": [-160, -50],
	--"camera_opponent": [40, 0],
	--"camera_girlfriend": [0, 0],
	--"camera_speed": 3
--}