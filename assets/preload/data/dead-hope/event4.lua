local separacionPixeles = 20        
local velocidadRetorno = 4        
local xOriginalP = {}
local xOriginalO = {}

local speedBop = 4


local direccionFlecha = {[-1] = 0, [0] = -1.5, [1] = -0.5, [2] = 0.25, [3] = 1.5}

function onCreatePost()
    for i = 0, 3 do
        xOriginalP[i] = getPropertyFromGroup('playerStrums', i, 'x')
        xOriginalO[i] = getPropertyFromGroup('opponentStrums', i, 'x')
    end
end

function onUpdatePost(elapsed)
    for i = 0, 3 do
        local xBase = xOriginalP[i]
        if xBase ~= nil then
            local currentX = getPropertyFromGroup('playerStrums', i, 'x')
            
            if currentX ~= xBase then
                local factorDir = direccionFlecha[i]
                local nuevoX = currentX - (elapsed * velocidadRetorno * (separacionPixeles * factorDir))
                
                if (factorDir < 0 and nuevoX > xBase) or (factorDir > 0 and nuevoX < xBase) then
                    nuevoX = xBase
                end
                setPropertyFromGroup('playerStrums', i, 'x', nuevoX)
            end
        end
    end

    for i = 0, 3 do
        local xBase = xOriginalO[i]
        if xBase ~= nil then
            local currentX = getPropertyFromGroup('opponentStrums', i, 'x')
            
            if currentX ~= xBase then
                local factorDir = direccionFlecha[i]
                local nuevoX = currentX - (elapsed * velocidadRetorno * (separacionPixeles * factorDir))
                
                if (factorDir < 0 and nuevoX > xBase) or (factorDir > 0 and nuevoX < xBase) then
                    nuevoX = xBase
                end
                setPropertyFromGroup('opponentStrums', i, 'x', nuevoX)
            end
        end
    end
end

function onBeatHit()
    if curBeat % speedBop == 0 then
        for i = 0, 3 do
            local factorDir = direccionFlecha[i]
            
            -- Jugador
            if xOriginalP[i] ~= nil then
                setPropertyFromGroup('playerStrums', i, 'x', xOriginalP[i] + (separacionPixeles * factorDir))
            end
            
            -- Oponente
            if xOriginalO[i] ~= nil then
                setPropertyFromGroup('opponentStrums', i, 'x', xOriginalO[i] + (separacionPixeles * factorDir))
            end
        end
    end
end

function onStepHit()
    if curStep == 465 then
        speedBop = 1
    end
    if curStep == 720 then
        speedBop = 4
    end
    if curStep == 991 then
        speedBop = 2
    end
    if curStep == 1247 then
        speedBop = 0 
    end
end