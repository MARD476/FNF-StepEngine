package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class SMResultsSubState extends MusicBeatSubstate
{
	var finishCallback:Void->Void;

	public function new(sicks:Int, goods:Int, bads:Int, shits:Int, misses:Int, maxCombo:Int, score:Int, accuracy:Float, ratingFc:String, onFinish:Void->Void)
	{
		super();
		this.finishCallback = onFinish;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.8;
		add(bg);

		var titleText:FlxText = new FlxText(0, 50, FlxG.width, "STEPDANCING RESULTS", 36);
		titleText.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.YELLOW, CENTER);
		titleText.borderColor = FlxColor.BLACK;
		titleText.borderStyle = OUTLINE;
		titleText.borderSize = 2;
		add(titleText);

		var statsY:Float = 140;
		var spacing:Float = 35;

		createStatRow(150, statsY, "Score:", Std.string(score), FlxColor.WHITE);
		createStatRow(150, statsY + spacing, "Max Combo:", Std.string(maxCombo), FlxColor.CYAN);
		createStatRow(150, statsY + (spacing * 2), "Sicks (Flawless):", Std.string(sicks), FlxColor.GREEN);
		createStatRow(150, statsY + (spacing * 3), "Goods:", Std.string(goods), FlxColor.YELLOW);
		createStatRow(150, statsY + (spacing * 4), "Bads:", Std.string(bads), FlxColor.ORANGE);
		createStatRow(150, statsY + (spacing * 5), "Shits:", Std.string(shits), FlxColor.PURPLE);
		createStatRow(150, statsY + (spacing * 6), "Misses:", Std.string(misses), FlxColor.RED);

		var accuracyFormatted:String = Std.string(Math.fround(accuracy * 100) / 100) + "%";
		createStatRow(150, statsY + (spacing * 7.5), "Accuracy:", accuracyFormatted, FlxColor.GREEN);
		createStatRow(150, statsY + (spacing * 8.5), "Rating / FC:", ratingFc, FlxColor.PINK);

		var continueText:FlxText = new FlxText(0, FlxG.height - 60, FlxG.width, "Press ENTER to continue", 22);
		continueText.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, CENTER);
		add(continueText);

        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	function createStatRow(x:Float, y:Float, label:String, value:String, valueColor:FlxColor)
	{
		var labelTxt:FlxText = new FlxText(x, y, 350, label, 22);
		labelTxt.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, LEFT);
		add(labelTxt);

		var valueTxt:FlxText = new FlxText(x + 400, y, 250, value, 22);
		valueTxt.setFormat(Paths.font("vcr.ttf"), 22, valueColor, RIGHT);
		add(valueTxt);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.ACCEPT || controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
			if (finishCallback != null)
			{
				finishCallback();
			}
		}
	}
}