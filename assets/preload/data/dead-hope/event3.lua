local esperandoTecla = false
local pulsacionesActuales = 0
local pulsacionesRequeridas = 3
local dañoPorFallo = 0.4 
local nombreFuente = 'vcr.ttf' 

function onCreate()

    makeLuaText('alertaEspacio', '', 600, 340, 300)
    setTextSize('alertaEspacio', 54)
    setObjectCamera('alertaEspacio', 'hud')
    setTextAlignment('alertaEspacio', 'center')
    setTextFont('alertaEspacio', nombreFuente)
    addLuaText('alertaEspacio')
    setProperty('alertaEspacio.visible', false)
end

function onUpdate(elapsed)
    if esperandoTecla then
        
        if keyboardJustPressed('SPACE') then
            pulsacionesActuales = pulsacionesActuales + 1
            

            cancelTimer('tiempoPasoEspacio')
            esperandoTecla = false
            
            if pulsacionesActuales >= pulsacionesRequeridas then
                
                setProperty('alertaEspacio.visible', false)
                playSound('confirmMenu', 0.4)
                triggerEvent('Set Cam Zoom', 0.67, 0.3)
                setProperty('health', getProperty('health') + 0.05)
            else
            
                procesarSiguientePaso()
            end
        end
    end
end


function iniciarMecanicaEspacio(tiempoPorPaso)
    pulsacionesActuales = 0
    tiempoLimitePorPaso = tiempoPorPaso
    procesarSiguientePaso()
end


function procesarSiguientePaso()
    esperandoTecla = true
    setProperty('alertaEspacio.visible', true)
    
    
    if pulsacionesActuales == 0 then
        setTextColor('alertaEspacio', 'FFCC00') 
        setTextString('alertaEspacio', '¡SPACE: 1/3!')
        triggerEvent('Set Cam Zoom', 0.77, 0.3)
    elseif pulsacionesActuales == 1 then
        setTextColor('alertaEspacio', 'FF6600') 
        setTextString('alertaEspacio', '¡SPACE: 2/3!')
        triggerEvent('Set Cam Zoom', 0.87, 0.3)
        playSound('MenuTimer tick', 0.3)
    elseif pulsacionesActuales == 2 then
        setTextColor('alertaEspacio', 'FF0000') 
        setTextString('alertaEspacio', '¡SPACE: 3/3!')
        triggerEvent('Set Cam Zoom', 0.97, 0.3)
        playSound('MenuTimer tick', 0.3)
    end
    

    runTimer('tiempoPasoEspacio', tiempoLimitePorPaso, 1)
end

function onTimerCompleted(tag, loops, loopsLeft)

    if tag == 'tiempoPasoEspacio' and esperandoTecla then
        esperandoTecla = false
        setProperty('alertaEspacio.visible', false)
        
        
        local vidaActual = getProperty('health')
        setProperty('health', vidaActual - dañoPorFallo)
        
        cameraFlash('hud', 'FF0000', 0.2, true)
        triggerEvent('Set Cam Zoom', 0.67, 0.3)
        playSound('Common invalid', 0.4)
    end
end

function onStepHit()

    if curStep == 771 then
        iniciarMecanicaEspacio(1.2)
    end

    if curStep == 835 then
        iniciarMecanicaEspacio(1.2)
    end

    if curStep == 899 then
        iniciarMecanicaEspacio(1.2)
    end

    if curStep == 964 then
        iniciarMecanicaEspacio(1.2)
    end

    if curStep == 1044 then
        iniciarMecanicaEspacio(1.2)
    end

    if curStep == 1108 then
        iniciarMecanicaEspacio(1.2)
    end

    if curStep == 1172 then
        iniciarMecanicaEspacio(1.2)
    end

    if curStep == 1236 then
        iniciarMecanicaEspacio(1.2)
    end
end