package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class SMPauseWaitSubState extends MusicBeatSubstate
{
	var callback:Bool->Void;
	var timer:FlxTimer;
	var canPress:Bool = true;
	var txt:FlxText;

	public function new(onComplete:Bool->Void)
	{
		super();
		this.callback = onComplete;

		this.persistentUpdate = false;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.5;
		add(bg);

		txt = new FlxText(0, FlxG.height / 2 - 20, FlxG.width, "", 28);
		txt.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.YELLOW, CENTER);
		txt.borderColor = FlxColor.BLACK;
		txt.borderStyle = OUTLINE;
		txt.borderSize = 2;
		add(txt);

		timer = new FlxTimer().start(2.0, function(tmr:FlxTimer) {
			if (canPress)
			{
				canPress = false;
				close();
				callback(false);
			}
		});

		updateCountdownText();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (canPress && timer != null && timer.active)
		{
			updateCountdownText();
		}

		if (canPress && controls.ACCEPT)
		{
			canPress = false;
			timer.cancel();
			FlxG.sound.play(Paths.sound('confirmMenu'));
			close();
			callback(true);
		}

		if (controls.BACK)
		{
			canPress = false;
			timer.cancel();
			close();
			callback(false);
		}
	}

	function updateCountdownText()
	{
		var timeLeft:Float = timer.timeLeft;
		var seconds:Int = Math.ceil(timeLeft);
		if (seconds < 1) seconds = 1;
		
		txt.text = "Press ENTER again for options (" + seconds + "s)...";
	}
}