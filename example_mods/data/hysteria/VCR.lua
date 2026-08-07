function onCreatePost()
        if shadersEnabled then
    initLuaShader("vhsNoise")
initLuaShader("vhs")
initLuaShader("vhsRoll")

makeLuaSprite("vhs")
makeGraphic("vhs",screenWidth,screenHeight,"FFFFFF")
setSpriteShader("vhs","vhsNoise")

makeLuaSprite("vhsN")
makeGraphic("vhsN",screenWidth,screenHeight,"FFFFFF")
setSpriteShader("vhsN","vhs")

makeLuaSprite('roll')

makeGraphic('roll',screenWidth,screenHeight,'FFFFFF')

setSpriteShader('roll','vhsRoll')

runHaxeCode([[
import openfl.filters.ShaderFilter;

game.camGame.setFilters([
    new ShaderFilter(game.getLuaObject("vhs").shader)
    new ShaderFilter(game.getLuaObject("vhsN").shader)
    new ShaderFilter(game.getLuaObject("roll").shader)
]);

game.camHUD.setFilters([
    new ShaderFilter(game.getLuaObject("vhs").shader)
    new ShaderFilter(game.getLuaObject("vhsN").shader)
    new ShaderFilter(game.getLuaObject("roll").shader)
]);
]])
end
end

function onUpdate(elapsed)
    if shadersEnabled then
        setShaderFloat("vhs","iTime",os.clock())
        setShaderFloat("vhsN","iTime",os.clock())
        setShaderFloat('roll','iTime',os.clock())
    end
end

function onStepHit()
    if shadersEnabled then
        if curStep == 1648 then
            setShaderFloat('roll','transition',0.3)
        end
        if curStep == 1653 then
            setShaderFloat('roll','transition',0.7)
        end
        if curStep == 1658 then
            setShaderFloat('roll','transition',1)
        end
        if curStep == 1663 then
            setShaderFloat('roll','transition',0.7)
        end
        if curStep == 1665 then
            setShaderFloat('roll','transition',0.3)
        end
        if curStep == 1667 then
            setShaderFloat('roll','transition',0)
        end
    end
end