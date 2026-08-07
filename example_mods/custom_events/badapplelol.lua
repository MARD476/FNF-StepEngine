function onCreatePost()
    -- Crear un fondo negro gigante que cubra toda la pantalla
    makeLuaSprite('siluetaFondoNegro', '', -600, -300)
    makeGraphic('siluetaFondoNegro', screenWidth * 3, screenHeight * 3, '000000')
    setScrollFactor('siluetaFondoNegro', 0, 0)
    
    -- Colocarlo al fondo de la escena (detrás de todo)
    addLuaSprite('siluetaFondoNegro', false)
    
    -- Ocultarlo por defecto al iniciar la canción
    setProperty('siluetaFondoNegro.visible', false)
end

function setSiluetaMode(active)
    if active then
        -- 1. Mostrar el fondo negro gigante
        setProperty('siluetaFondoNegro.visible', true)

        -- 2. Poner a los personajes en BLANCO PURO
        runHaxeCode([[
            if (game.boyfriend != null) {
                game.boyfriend.setColorTransform(0, 0, 0, 1, 255, 255, 255, 0);
            }
            if (game.dad != null) {
                game.dad.setColorTransform(0, 0, 0, 1, 255, 255, 255, 0);
            }
            if (game.gf != null) {
                game.gf.setColorTransform(0, 0, 0, 1, 255, 255, 255, 0);
            }

            // Ocultar / Pintar de negro todos los objetos del stage
            for (member in game.members) {
                if (Std.isOfType(member, flixel.FlxSprite) && member != game.boyfriend && member != game.dad && member != game.gf && member != game.getLuaObject('siluetaFondoNegro')) {
                    var sprite:flixel.FlxSprite = cast member;
                    sprite.color = 0x000000;
                    // También puedes ocultarlos completamente si prefieres:
                    // sprite.visible = false;
                }
            }
        ]])
    else
        -- RESTAURAR COLORES NORMALES

        -- 1. Ocultar el fondo negro
        setProperty('siluetaFondoNegro.visible', false)

        -- 2. Restaurar personajes
        runHaxeCode([[
            if (game.boyfriend != null) {
                game.boyfriend.setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
                game.boyfriend.color = 0xFFFFFF;
            }
            if (game.dad != null) {
                game.dad.setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
                game.dad.color = 0xFFFFFF;
            }
            if (game.gf != null) {
                game.gf.setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
                game.gf.color = 0xFFFFFF;
            }

            // Restaurar visibilidad y color del escenario
            for (member in game.members) {
                if (Std.isOfType(member, flixel.FlxSprite)) {
                    var sprite:flixel.FlxSprite = cast member;
                    sprite.color = 0xFFFFFF;
                    sprite.visible = true;
                }
            }
        ]])
    end
end

-- Evento de Lua para activarlo desde el Chart Editor o Trigger
function onEvent(name, value1, value2)
    if name == 'badapplelol' then
        local enable = (value1 == '1' or value1 == 'true' or value1 == 'on')
        setSiluetaMode(enable)
    end
end

-- PRUEBA RÁPIDA: Si presionas la tecla "7" o en cierta parte de la canción
function onUpdate(elapsed)
    -- Puedes descomentar esto para probarlo manualmente presionando 'SPACE' en el juego:
    -- if keyJustPressed('space') then
    --     setSiluetaMode(true)
    -- end
end