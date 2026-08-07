package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class SMTutorialSubState extends FlxSubState
{
	var selectedSection:Int = 0;
	var infoText:FlxText;
	var optionText:FlxText;

	var finishCallback:Void->Void;

	public function new(onFinish:Void->Void)
	{
		super();
		this.finishCallback = onFinish;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.8;
		add(bg);

		var panel:FlxSprite = new FlxSprite(100, 50).makeGraphic(FlxG.width - 200, FlxG.height - 100, 0xFFA9A9A9);
		panel.alpha = 0.9;
		add(panel);

		var titleText:FlxText = new FlxText(120, 70, FlxG.width - 240, "Welcome to Step Engine!", 32);
		titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.YELLOW, CENTER);
		add(titleText);

		infoText = new FlxText(140, 140, FlxG.width - 280, "", 20);
		infoText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT);
		add(infoText);

		optionText = new FlxText(140, FlxG.height - 120, FlxG.width - 280, "", 22);
		optionText.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.GREEN, CENTER);
		add(optionText);

		updateContent();
	}

	function updateContent()
	{
		if (selectedSection == 0)
		{
			infoText.text = "Here you can play custom StepMania songs!\n\n"
				+ "How to add songs:\n"
				+ "1. Go to your assets folder and look for the .sm directory.\n"
				+ "2. Paste your custom song folders right there.\n\n"
				+ "[Press LEFT / RIGHT to switch pages | Press ACCEPT to view Compatibility Info]";
			optionText.text = "> SKIP TUTORIAL <";
		}
		else
		{
			infoText.text = "Compatibility & Recommendations:\n\n"
				+ "- Audio formats: Fully compatible with .ogg and .mp3.\n"
				+ "- Chart format: Only compatible with .sm files (.scc will not load).\n"
				+ "- Recommendation: It is highly recommended to use songs from older StepMania versions for best stability.\n\n"
				+ "[Press LEFT / RIGHT to switch pages]";
			optionText.text = "> GOT IT, LET'S PLAY! <";
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
			selectedSection = (selectedSection == 0) ? 1 : 0;
			updateContent();
		}

		if (FlxG.keys.justPressed.ENTER)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			if (finishCallback != null)
				finishCallback();
			close();
		}
	}
}