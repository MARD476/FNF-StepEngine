package states.stages;

import states.stages.objects.*;
import objects.Character;

class StageLiar extends BaseStage
{
	public static var bgLies:BGSprite;
	public static var blackLies:BGSprite;
	public static var difi:FlxSprite;
	override function create()
	{
		bgLies = new BGSprite('Lies/Stage', -724, -468, 0,0);
		bgLies.scale.set(1.21066717585173,1.24571653479379);
		bgLies.alpha = 0;
		add(bgLies);

		blackLies = new BGSprite('Lies/black', 330, 704, 0,0);
		blackLies.scale.x = 75.1434438167878;
		blackLies.scale.y = 33.520590485465;
		add(blackLies);						
	}
}