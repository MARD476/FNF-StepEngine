package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;

using StringTools;

class SMOptionsSubState extends MusicBeatSubstate
{
	private var curOption:SMGameplayOption = null;
	private var curSelected:Int = 0;
	private var optionsArray:Array<SMGameplayOption> = [];

	private var optionText:FlxTypedGroup<FlxText>;
	private var valueTexts:FlxTypedGroup<FlxText>;
	private var callback:Bool->Void;

	private var selector:FlxSprite;

	public static var songSpeed:Float = 1.0;

	function getOptions()
	{
		var option = new SMGameplayOption('Scroll Speed', 'scrollspeed', 'float', 1.0);
		option.scrollSpeed = 2.0;
		option.minValue = 0.35;
		option.maxValue = 6.0;
		option.changeValue = 0.05;
		option.decimals = 2;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		#if !html5
		var option = new SMGameplayOption('Playback Rate', 'songspeed', 'float', 1.0);
		option.scrollSpeed = 1.0;
		option.minValue = 0.5;
		option.maxValue = 3.0;
		option.changeValue = 0.05;
		option.displayFormat = '%vX';
		option.decimals = 2;
		optionsArray.push(option);
		#end

		var option = new SMGameplayOption('Health Gain Multiplier', 'healthgain', 'float', 1.0);
		option.scrollSpeed = 2.5;
		option.minValue = 0.0;
		option.maxValue = 5.0;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		var option = new SMGameplayOption('Health Loss Multiplier', 'healthloss', 'float', 1.0);
		option.scrollSpeed = 2.5;
		option.minValue = 0.5;
		option.maxValue = 5.0;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		var option = new SMGameplayOption('Instakill on Miss', 'instakill', 'bool', false);
		optionsArray.push(option);

		var option = new SMGameplayOption('Practice Mode', 'practice', 'bool', false);
		optionsArray.push(option);

		var option = new SMGameplayOption('Botplay', 'botplay', 'bool', false);
		optionsArray.push(option);

		var playSongOpt = new SMGameplayOption('Play Song', 'playsong_action', 'string', 'Press Accept', ['Press Accept']);
		optionsArray.push(playSongOpt);

		var backOpt = new SMGameplayOption('Back', 'back_action', 'string', 'Press Accept', ['Press Accept']);
		optionsArray.push(backOpt);
	}

	public function new(onComplete:Bool->Void)
	{
		super();
		this.callback = onComplete;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.7;
		add(bg);

		var titleText:FlxText = new FlxText(0, 40, FlxG.width, "STEPDANCING OPTIONS", 32);
		titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		add(titleText);

		selector = new FlxSprite().makeGraphic(18, 18, FlxColor.YELLOW);
		add(selector);

		optionText = new FlxTypedGroup<FlxText>();
		add(optionText);

		valueTexts = new FlxTypedGroup<FlxText>();
		add(valueTexts);

		getOptions();

		for (i in 0...optionsArray.length)
		{
			var text:FlxText = new FlxText(150, 120 + (i * 45), 450, optionsArray[i].name, 22);
			text.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, LEFT);
			text.ID = i;
			optionText.add(text);

			var valText:FlxText = new FlxText(600, 120 + (i * 45), 250, "", 22);
			valText.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.YELLOW, LEFT);
			valText.ID = i;
			valueTexts.add(valText);
			optionsArray[i].setChild(valText);

			updateTextFrom(optionsArray[i]);
		}

		changeSelection(0);
	}

	var holdTime:Float = 0;
	var holdValue:Float = 0;

	override function update(elapsed:Float)
	{
		if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
			callback(false);
		}

		if (curOption != null)
		{
			var usesCheckbox = (curOption.type == 'bool');

			if (usesCheckbox)
			{
				if (controls.ACCEPT)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					curOption.setValue((curOption.getValue() == true) ? false : true);
					curOption.change();
					updateTextFrom(curOption);
				}
			}
			else
			{
				if (curOption.variable == 'playsong_action' || curOption.variable == 'back_action')
				{
					if (controls.ACCEPT)
					{
						FlxG.sound.play(Paths.sound('confirmMenu'));
						if (curOption.variable == 'playsong_action')
						{
							var speedOpt = getOptionByName("Scroll Speed");
							if(speedOpt != null) songSpeed = speedOpt.getValue();

							close();
							callback(true);
						}
						else
						{
							close();
							callback(false);
						}
					}
				}
				else
				{
					if (controls.UI_LEFT || controls.UI_RIGHT)
					{
						var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P);
						if (holdTime > 0.5 || pressed)
						{
							if (pressed)
							{
								var add:Dynamic = null;
								if (curOption.type != 'string')
								{
									add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;
								}

								switch (curOption.type)
								{
									case 'int' | 'float' | 'percent':
										holdValue = curOption.getValue() + add;
										if (holdValue < curOption.minValue) holdValue = curOption.minValue;
										else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;

										switch (curOption.type)
										{
											case 'int':
												holdValue = Math.round(holdValue);
												curOption.setValue(holdValue);
											case 'float' | 'percent':
												holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
												curOption.setValue(holdValue);
										}

									case 'string':
										var num:Int = curOption.curOption;
										if (controls.UI_LEFT_P) --num;
										else num++;

										if (num < 0) num = curOption.options.length - 1;
										else if (num >= curOption.options.length) num = 0;

										curOption.curOption = num;
										curOption.setValue(curOption.options[num]);
								}
								updateTextFrom(curOption);
								curOption.change();
								FlxG.sound.play(Paths.sound('scrollMenu'));
							}
							else if (curOption.type != 'string')
							{
								holdValue = Math.max(curOption.minValue, Math.min(curOption.maxValue, holdValue + curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1)));

								switch (curOption.type)
								{
									case 'int':
										curOption.setValue(Math.round(holdValue));
									case 'float' | 'percent':
										var blah:Float = Math.max(curOption.minValue, Math.min(curOption.maxValue, holdValue + curOption.changeValue - (holdValue % curOption.changeValue)));
										curOption.setValue(FlxMath.roundDecimal(blah, curOption.decimals));
								}
								updateTextFrom(curOption);
								curOption.change();
							}
						}

						if (curOption.type != 'string')
						{
							holdTime += elapsed;
						}
					}
					else if (controls.UI_LEFT_R || controls.UI_RIGHT_R)
					{
						clearHold();
					}
				}
			}

			if (controls.RESET && curOption.variable != 'playsong_action' && curOption.variable != 'back_action')
			{
				curOption.setValue(curOption.defaultValue);
				if (curOption.type == 'string')
				{
					curOption.curOption = curOption.options.indexOf(curOption.getValue());
				}
				updateTextFrom(curOption);
				curOption.change();
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
		}

		super.update(elapsed);
	}

	function getOptionByName(name:String):SMGameplayOption
	{
		for (i in optionsArray)
		{
			if (i.name == name) return i;
		}
		return null;
	}

	function updateTextFrom(option:SMGameplayOption)
	{
		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if (option.type == 'percent') val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);
	}

	function clearHold()
	{
		if (holdTime > 0.5)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		holdTime = 0;
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0) curSelected = optionsArray.length - 1;
		if (curSelected >= optionsArray.length) curSelected = 0;

		for (item in optionText.members)
		{
			item.alpha = 0.6;
			if (item.ID == curSelected)
			{
				item.alpha = 1.0;
				selector.x = item.x - 25;
				selector.y = item.y + 4;
			}
		}
		for (text in valueTexts.members)
		{
			text.alpha = 0.6;
			if (text.ID == curSelected)
			{
				text.alpha = 1.0;
			}
		}

		curOption = optionsArray[curSelected];
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}

class SMGameplayOption
{
	private var child:FlxText;
	public var text(get, set):String;
	public var onChange:Void->Void = null;

	public var type(get, default):String = 'bool';
	public var scrollSpeed:Float = 50;

	public var variable:String = null;
	public var defaultValue:Dynamic = null;

	public var curOption:Int = 0;
	public var options:Array<String> = null;
	public var changeValue:Dynamic = 1;
	public var minValue:Dynamic = null;
	public var maxValue:Dynamic = null;
	public var decimals:Int = 1;

	public var displayFormat:String = '%v';
	public var name:String = 'Unknown';

	public function new(name:String, variable:String, type:String = 'bool', defaultValue:Dynamic = 'null variable value', ?options:Array<String> = null)
	{
		this.name = name;
		this.variable = variable;
		this.type = type;
		this.defaultValue = defaultValue;
		this.options = options;

		if (defaultValue == 'null variable value')
		{
			switch (type)
			{
				case 'bool': defaultValue = false;
				case 'int' | 'float': defaultValue = 0;
				case 'percent': defaultValue = 1;
				case 'string':
					defaultValue = '';
					if (options != null && options.length > 0) defaultValue = options[0];
			}
		}

		if (variable != 'playsong_action' && variable != 'back_action')
		{
			if (getValue() == null) setValue(defaultValue);
		}

		switch (type)
		{
			case 'string':
				if (options != null)
				{
					var num:Int = options.indexOf(getValue());
					if (num > -1) curOption = num;
				}
			case 'percent':
				displayFormat = '%v%';
				changeValue = 0.01;
				minValue = 0;
				maxValue = 1;
				scrollSpeed = 0.5;
				decimals = 2;
		}
	}

	public function change()
	{
		if (onChange != null) onChange();
	}

	public function getValue():Dynamic
	{
		if (variable == 'playsong_action' || variable == 'back_action') return "";
		return ClientPrefs.data.gameplaySettings.get(variable);
	}

	public function setValue(value:Dynamic)
	{
		if (variable != 'playsong_action' && variable != 'back_action')
		{
			ClientPrefs.data.gameplaySettings.set(variable, value);
		}
	}

	public function setChild(child:FlxText)
	{
		this.child = child;
	}

	private function get_text()
	{
		if (child != null) return child.text;
		return null;
	}

	private function set_text(newValue:String = '')
	{
		if (child != null) child.text = newValue;
		return newValue;
	}

	private function get_type()
	{
		var newValue:String = 'bool';
		switch (type.toLowerCase().trim())
		{
			case 'int' | 'float' | 'percent' | 'string': newValue = type;
			case 'integer': newValue = 'int';
			case 'str': newValue = 'string';
			case 'fl': newValue = 'float';
		}
		type = newValue;
		return type;
	}
}