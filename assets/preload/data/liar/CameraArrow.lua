local campointx = 0
local campointy = 0
local bfturn = false
local gfturn = false
local camMovement = 20
local velocity = 2

    -- edit these 2 last values up here so you dont have to manually do every single one
    
function onMoveCamera(focus)
    if focus == 'boyfriend' then
    campointx = getProperty('camFollow.x')
    campointy = getProperty('camFollow.y')
    bfturn = true
    
    elseif focus == 'dad' then
    campointx = getProperty('camFollow.x')
    campointy = getProperty('camFollow.y')
    bfturn = false
    setProperty('cameraSpeed', 2)
        elseif focus == 'gf' then
        campointx = getProperty('camFollow.x')
        campointy = getProperty('camFollow.y')
        bfturn = false
    end
end


function goodNoteHit(id, direction, noteType, isSustainNote)
    if bfturn then
        if direction == 0 then
            if gfturn then
                setProperty('camFollow.x', -500 + campointx - camMovement)
            else
                setProperty('camFollow.x', campointx - camMovement)
            end
        elseif direction == 1 then
            setProperty('camFollow.y', campointy + camMovement)
        elseif direction == 2 then
            setProperty('camFollow.y', campointy - camMovement)
        elseif direction == 3 then
            if gfturn then
                setProperty('camFollow.x', -500 + campointx + camMovement)
            else
                setProperty('camFollow.x', campointx + camMovement)
            end
        end
        setProperty('cameraSpeed', velocity)
    end    
end

function opponentNoteHit(id, direction, noteType, isSustainNote)
    if not bfturn then
        if direction == 0 then
            setProperty('camFollow.x', campointx - camMovement)
        elseif direction == 1 then
            setProperty('camFollow.y', campointy + camMovement)
        elseif direction == 2 then
            setProperty('camFollow.y', campointy - camMovement)
        elseif direction == 3 then
            setProperty('camFollow.x', campointx + camMovement)
        end
        if noteType == "GF Sing" then
            if direction == 0 then
                setProperty('camFollow.x', campointx - camMovement)
            elseif direction == 1 then
                setProperty('camFollow.y', campointy + camMovement)
            elseif direction == 2 then
                setProperty('camFollow.y', campointy - camMovement)
            elseif direction == 3 then
                setProperty('camFollow.x', campointx + camMovement)
            end
        end
        setProperty('cameraSpeed', velocity)
    end    
end

function onStepHit()
    if curStep == 1334 then
   gfturn = true
    end
    if curStep == 1458 then
        gfturn = false
    end
    if curStep == 1470 then
        gfturn = true
    end
    if curStep == 1709 then
        gfturn = false
    end
end