// Author: MARD


var shader = game.createRuntimeShader('tvstatic');
var filters = [new ShaderFilter(shader)];


function onCreatePost()
{
	game.initLuaShader('tvstatic');
 game.camGame._filters = filters;
shader.setFloat('time', 3); shader.setFloat('strength', 0.3); shader.setFloat('speed', 20);
game.camGame._filters = null;
}

var tottalTime:Float = 0;

function onUpdate(elapsed)
{
    tottalTime += elapsed/1000;
    shader.setFloat('time', tottalTime*1000);
}

function onStepHit()
{
	if (curStep == 720)
	{
		 game.camGame._filters = filters;
	}	
}