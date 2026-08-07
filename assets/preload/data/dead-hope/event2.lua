local notaAlphaBase = 0.6    
local tiempoDesvanecer = 0.4 

function onCreatePost()
    for i = 0, 3 do
        setPropertyFromGroup('playerStrums', i, 'alpha', notaAlphaBase)
        setPropertyFromGroup('opponentStrums', i, 'alpha', notaAlphaBase)
    end
end

function onUpdatePost(elapsed)
    for i = 0, 3 do
        -- Jugador
        local currentAlphaP = getPropertyFromGroup('playerStrums', i, 'alpha')
        if currentAlphaP > notaAlphaBase then
            setPropertyFromGroup('playerStrums', i, 'alpha', currentAlphaP - (elapsed / tiempoDesvanecer))
        end

        -- Oponente
        local currentAlphaO = getPropertyFromGroup('opponentStrums', i, 'alpha')
        if currentAlphaO > notaAlphaBase then
            setPropertyFromGroup('opponentStrums', i, 'alpha', currentAlphaO - (elapsed / tiempoDesvanecer))
        end
    end

    for i = 0, getProperty('notes.length') - 1 do
        setPropertyFromGroup('notes', i, 'alpha', notaAlphaBase)
    end
end

function goodNoteHit(id, noteData, noteType, isSustainNote)
    
    setPropertyFromGroup('playerStrums', noteData, 'alpha', 1.0)
end

function opponentNoteHit(id, noteData, noteType, isSustainNote)

    setPropertyFromGroup('opponentStrums', noteData, 'alpha', 1.0)
end