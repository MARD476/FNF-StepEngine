package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ui.FlxButton; 
import options.OptionsState;
import states.LoadingState;

class LiarWarningSubState extends FlxSubState
{
	var currentPage:Int = 0;
	var maxPages:Int = 2; 
	
	var contentText:FlxText;
	var youtubeLinkText:FlxText; 
	var footerText:FlxText;
	var titleText:FlxText;
	
	var callback:Bool->Void;

	public function new(onComplete:Bool->Void)
	{
		super();
		this.callback = onComplete;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.85;
		add(bg);

		var panel:FlxSprite = new FlxSprite(80, 40).makeGraphic(FlxG.width - 160, FlxG.height - 80, FlxColor.fromString("#151515"));
		panel.alpha = 0.95;
		add(panel);

		titleText = new FlxText(100, 60, FlxG.width - 200, "WARNING - IMPORTANT NOTICE", 28);
		titleText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.RED, CENTER);
		add(titleText);

		contentText = new FlxText(110, 130, FlxG.width - 220, "", 18);
		contentText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT);
		add(contentText);

		youtubeLinkText = new FlxText(110, 240, FlxG.width - 220, "", 18);
		youtubeLinkText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.RED, LEFT);
		add(youtubeLinkText);

		footerText = new FlxText(110, FlxG.height - 110, FlxG.width - 220, "", 16);
		footerText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.YELLOW, CENTER);
		add(footerText);

		FlxG.mouse.visible = true;

		updatePageContent();
	}

	function updatePageContent()
	{
		if (currentPage == 0)
		{
			titleText.text = "NOTICE 1: WINDOWS EVENTS";
			contentText.text = "This song features events that modify your Windows environment. If you encounter any bugs or errors, please let me know and comment on the video:";
			youtubeLinkText.visible = true;
			youtubeLinkText.text = "> CLICK HERE TO OPEN YOUTUBE VIDEO <";
			footerText.text = "[ Press ENTER to go to the next page ]";
		}
		else if (currentPage == 1)
		{
			titleText.text = "NOTICE 2: PERFORMANCE & COMPATIBILITY";
			contentText.text = "If you use 'MSI Afterburner', please close or disable it temporarily, as it can cause the game to crash without warning and freeze all events (same applies to other GPU overlay software). You can re-enable it afterwards.\n\nIf you prefer not to disable it, go to Options -> Graphics and uncheck the Windows option to prevent errors.";
			youtubeLinkText.visible = false; 
			youtubeLinkText.text = "";
			footerText.text = "[ Press ENTER to next page | CTRL to open Options ]";
		}
		else if (currentPage == 2)
		{
			titleText.text = "NOTICE 3: PLAYER EXPERIENCE";
			contentText.text = "I deeply care about players' experience, so I always try to make sure everything in the game runs as smoothly and well-designed as possible.\n\nYou have been warned that this song modifies system parameters to deliver a unique experience.\n\nThere's no turning back now.";
			youtubeLinkText.visible = false;
			youtubeLinkText.text = "";
			footerText.text = "[ Press ENTER to START the song ]";
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (currentPage == 0 && FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(youtubeLinkText))
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				CoolUtil.browserLoad('https://youtu.be/wCh1toKg1d0?si=3KmW5e6WD6eSFd_p'); 
			}
		}

		if (currentPage == 1 && FlxG.keys.justPressed.CONTROL)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			OptionsState.onPlayState = false;
			MusicBeatState.switchState(new OptionsState());
			return;
		}

		if (FlxG.keys.justPressed.ENTER)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			
			if (currentPage < maxPages)
			{
				currentPage++;
				updatePageContent();
			}
			else
			{
				FlxG.mouse.visible = false;
				if (callback != null)
					callback(true);
				close();
			}
		}
	}
}