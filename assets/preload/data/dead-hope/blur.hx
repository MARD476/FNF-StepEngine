// USES PSYCH ENGINE 0.7.1h
// Author: TheLeerName


var shaderGame = game.createRuntimeShader('blur');
var shaderHUD = game.createRuntimeShader('blur');
var filtersGame = [new ShaderFilter(shaderGame)];
var filtersHUD = [new ShaderFilter(shaderHUD)];


function onCreatePost()
{
	game.initLuaShader('blur');
 
  game.camGame._filters = filtersGame;
  game.camHUD._filters = filtersHUD;
shaderGame.setFloat('dim', 3.4); shaderGame.setFloat('size', 65);
shaderHUD.setFloat('dim', 3); shaderHUD.setFloat('size', 20);
}

function onStepHit()
{
	if (curStep == 1)
	{
  game.camGame._filters = filtersGame;
  game.camHUD._filters = filtersHUD;
shaderGame.setFloat('dim', 3.4); shaderGame.setFloat('size', 65);
shaderHUD.setFloat('dim', 3); shaderHUD.setFloat('size', 20);
	}

	if (curStep == 464)
	{
		game.camGame._filters = null;
		game.camHUD._filters = null;
	}
}