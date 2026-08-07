//El codigo es un desasatre, lo se... pero despues se organiza -MARD
//este unicamente sirve para cargar los .sm (Stepmania). Aun falta mucho por añadir

package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;

import objects.HealthIcon;
import states.editors.ChartingState;

import substates.GameplayChangersSubstate;
import substates.ResetScoreSubState;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File; 
#end

#if FEATURE_STEPMANIA
import smTools.SMFile;
#end

class FreeplayState extends MusicBeatState
{
	public static var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	public static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;
	var finalAudioPath:String = "";

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	public static var blockFreeplayInputs:Bool = false;

	public static var loadedStepmaniaOnce:Bool = false;
	public static var seenSMFreeplayIntro:Bool = false;

	public static var songData:Map<String, Array<Dynamic>> = []; 

	#if VIDEOS_ALLOWED
	var previewMP3:hxcodec.flixel.FlxVideoSprite; //carga archivo .ogg como .mp3
	#end

	var smPreviewCache:Map<String, String> = new Map();
	var smSampleCache:Map<String, Int> = new Map();

	var pendingPreview:String = "";
	var previewDelay:Float = 0;

	var previewTimer:FlxTimer;

	override function create()
	{
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if desktop
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				//addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		Mods.loadTopMod();

		// ==========================================
		// LOGICA DE CARGA DE ARCHIVOS .SM (StepMania)
		// ==========================================
		

		#if FEATURE_STEPMANIA
		if (!SMManager.isLoaded) {
			SMManager.loadAllSongs();
		}

		//cache de las canciones uwu 
		songs = SMManager.songs;
		songData = SMManager.songData;
		this.smPreviewCache = SMManager.smPreviewCache;
		#end

		#if VIDEOS_ALLOWED
		previewMP3 = new hxcodec.flixel.FlxVideoSprite();
		add(previewMP3);
		#end
		
		// ==========================================

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.targetY = i;
			grpSongs.add(songText);

			songText.scaleX = Math.min(1, 980 / songText.width);
			songText.snapToPosition();

			Mods.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			songText.visible = songText.active = songText.isMenuItem = false;
			icon.visible = icon.active = false;

			iconArray.push(icon);
			add(icon);
		}
		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);

		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;
		lerpSelected = curSelected;

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));
		changeSelection();

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		#if PRELOAD_ALL
		var leText:String = "Select the song.";
		var size:Int = 16;
		#else
		var leText:String = "JOTO";
		var size:Int = 18;
		#end
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);
		
		updateTexts();
		super.create();

		if (!FlxG.save.data.seenSMFreeplayIntro)
		{
			FlxG.save.data.seenSMFreeplayIntro = true;
			persistentUpdate = false;
			openSubState(new SMTutorialSubState(function() {
				persistentUpdate = true;
			}));
		}
	}

	override function closeSubState() {
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, FlxMath.bound(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, FlxMath.bound(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) {
			ratingSplit.push('');
		}
		
		while(ratingSplit[1].length < 2) {
			ratingSplit[1] += '0';
		}

		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
		positionHighscore();

		var shiftMult:Int = 1;
		if (!blockFreeplayInputs)
        {
			if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

			if(songs.length > 1)
			{
				if(FlxG.keys.justPressed.HOME)
				{
					curSelected = 0;
					changeSelection();
					holdTime = 0;	
				}
				else if(FlxG.keys.justPressed.END)
				{
					curSelected = songs.length - 1;
					changeSelection();
					holdTime = 0;	
				}
				if (controls.UI_UP_P)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (controls.UI_DOWN_P)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}

				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}

				if(FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				}
			}

			if (controls.UI_LEFT_P)
			{
				changeDiff(-1);
				_updateSongLastDifficulty();
			}
			else if (controls.UI_RIGHT_P)
			{
				changeDiff(1);
				_updateSongLastDifficulty();
			}

			if (controls.BACK)
			{
				persistentUpdate = false;
				if(colorTween != null) {
					colorTween.cancel();
				}
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				FlxG.sound.music.fadeIn(2, 0, 0.7);
				MusicBeatState.switchState(new MainMenuState());
			}

			/*if(FlxG.keys.justPressed.CONTROL)
			{
				persistentUpdate = false;
				openSubState(new GameplayChangersSubstate());
			}*/
			/*else if(FlxG.keys.justPressed.SPACE)
			{
				if(instPlaying != curSelected)
				{
					#if PRELOAD_ALL
					destroyFreeplayVocals();
					FlxG.sound.music.volume = 0;

					if (songs[curSelected].songCharacter == "sm") {
						#if FEATURE_STEPMANIA
						var data = songs[curSelected];
						var bytes = File.getBytes(data.folder + "/" + data.sm.header.MUSIC);
						var sound = new openfl.media.Sound();
						sound.loadCompressedDataFromByteArray(bytes.getData(), bytes.length);
						FlxG.sound.playMusic(sound, 0.7);
						#end
					} else {
						Mods.currentModDirectory = songs[curSelected].folder;
						var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
						PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
						if (PlayState.SONG.needsVoices)
							vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
						else
							vocals = new FlxSound();

						FlxG.sound.list.add(vocals);
						FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.7);
						vocals.play();
						vocals.persist = true;
						vocals.looped = true;
						vocals.volume = 0.7;
					}
					instPlaying = curSelected;
					#end
				}
			}*/

			else if (controls.ACCEPT)
			{
				persistentUpdate = false;

				persistentUpdate = false;

				var isSMReal:Bool = false;
				var currentSongObj = songs[curSelected];
				
				if (currentSongObj != null)
				{
					if (currentSongObj.songCharacter == "sm" || currentSongObj.isSMFile || songData.exists(currentSongObj.songName))
					{
						if (songData.exists(currentSongObj.songName)) {
							isSMReal = true;
						}
					}
				}

	            if (isSMReal)
				{
					trace("¡Es una canción SM! Esperando doble pulsación para opciones...");
					#if FEATURE_STEPMANIA

					blockFreeplayInputs = true;
					
					persistentUpdate = false;

					var waitingForOptions:Bool = true;
					var optionChosen:Bool = false;

					var noticeText:FlxText = new FlxText(0, FlxG.height - 100, FlxG.width, "Press ENTER again for options (2s)...", 24);
					noticeText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.YELLOW, CENTER);
					noticeText.borderColor = FlxColor.BLACK;
					noticeText.borderStyle = OUTLINE;
					noticeText.borderSize = 2;
					add(noticeText);

					var timer:flixel.util.FlxTimer = new flixel.util.FlxTimer();
					timer.start(2.0, function(tmr:flixel.util.FlxTimer) {
						if (waitingForOptions)
						{
							noticeText.destroy();
							//trace("Inicia Pues");
							
							PlayState.SONG = songData.get(currentSongObj.songName)[curDifficulty];
							PlayState.isStoryMode = false;
							PlayState.storyDifficulty = curDifficulty;
							Reflect.setField(PlayState, "isSM", true);
							Reflect.setField(PlayState, "sm", currentSongObj.sm);
							Reflect.setField(PlayState, "pathToSm", currentSongObj.path);
							blockFreeplayInputs = false;

							if(colorTween != null) {
								colorTween.cancel();
							}

							LoadingState.loadAndSwitchState(new PlayState());
							FlxG.sound.music.volume = 0;
							destroyFreeplayVocals();
							
							#if MODS_ALLOWED
							DiscordClient.loadModRPC();
							#end
						}
					});
					
					remove(noticeText);
					timer.cancel();
					
					openSubState(new SMPauseWaitSubState(function(wantOptions:Bool) {
						if (wantOptions)
						{
							openSubState(new SMOptionsSubState(function(confirmed:Bool) {
								if (confirmed)
								{
									PlayState.SONG = songData.get(currentSongObj.songName)[curDifficulty];
									PlayState.isStoryMode = false;
									PlayState.storyDifficulty = curDifficulty;
									Reflect.setField(PlayState, "isSM", true);
									Reflect.setField(PlayState, "sm", currentSongObj.sm);
									Reflect.setField(PlayState, "pathToSm", currentSongObj.path);
									blockFreeplayInputs = false;

									if(colorTween != null) {
										colorTween.cancel();
									}

									LoadingState.loadAndSwitchState(new PlayState());
									FlxG.sound.music.volume = 0;
									destroyFreeplayVocals();
									
									#if MODS_ALLOWED
									DiscordClient.loadModRPC();
									#end
								}
								else
								{
									blockFreeplayInputs = false;
								}
							}));
						}
						else
						{
							PlayState.SONG = songData.get(currentSongObj.songName)[curDifficulty];
							PlayState.isStoryMode = false;
							PlayState.storyDifficulty = curDifficulty;
							Reflect.setField(PlayState, "isSM", true);
							Reflect.setField(PlayState, "sm", currentSongObj.sm);
							Reflect.setField(PlayState, "pathToSm", currentSongObj.path);
							blockFreeplayInputs = false;

							if(colorTween != null) {
								colorTween.cancel();
							}

							LoadingState.loadAndSwitchState(new PlayState());
							FlxG.sound.music.volume = 0;
							destroyFreeplayVocals();
							
							#if MODS_ALLOWED
							DiscordClient.loadModRPC();
							#end
						}
					}));

					return;
					#end
				}
				else
				{
					var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
					var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
					Reflect.setField(PlayState, "isSM", false);

					try {
						PlayState.SONG = Song.loadFromJson(poop, songLowercase);
						PlayState.isStoryMode = false;
						PlayState.storyDifficulty = curDifficulty;
					}
					catch(e:Dynamic) {
						trace('ERROR! $e');
						var errorStr:String = e.toString();
						if(errorStr.startsWith('[file_contents,assets/data/')) errorStr = 'Missing file: ' + errorStr.substring(27, errorStr.length-1);
						missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
						missingText.screenCenter(Y);
						missingText.visible = true;
						missingTextBG.visible = true;
						FlxG.sound.play(Paths.sound('cancelMenu'));

						updateTexts(elapsed);
						super.update(elapsed);
						return;
					}
				}

				if(colorTween != null) {
					colorTween.cancel();
				}

				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
				destroyFreeplayVocals();
				
				#if MODS_ALLOWED
				DiscordClient.loadModRPC();
				#end
			}
			else if(controls.RESET)
			{
				persistentUpdate = false;
				openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
		}

		updateTexts(elapsed);
		super.update(elapsed);
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}

	function changeDiff(change:Int = 0)
	{
		if (blockFreeplayInputs) return;
		curDifficulty += change;

        if (songs[curSelected].songCharacter == "sm")
		{
			if (curDifficulty < 0)
				curDifficulty = songs[curSelected].smDifficulties.length - 1;
			if (curDifficulty >= songs[curSelected].smDifficulties.length)
				curDifficulty = 0;
				
			#if !switch
			var smDiffName:String = songs[curSelected].smDifficulties[curDifficulty];
			var formattedSongName:String = Paths.formatToSongPath(songs[curSelected].songName) + "-" + smDiffName.toLowerCase();
			
			intendedScore = Highscore.getScore(formattedSongName, 0);
			intendedRating = Highscore.getRating(formattedSongName, 0);
			#end
			
			diffText.text = '< ' + smDiffName + ' >';
		} else {
			if (curDifficulty < 0)
				curDifficulty = Difficulty.list.length-1;
			if (curDifficulty >= Difficulty.list.length)
				curDifficulty = 0;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty);
		if (Difficulty.list.length > 1)
			diffText.text = '< ' + lastDifficultyName.toUpperCase() + ' >';
		else
			diffText.text = lastDifficultyName.toUpperCase();
		}


		positionHighscore();
		missingText.visible = false;
		missingTextBG.visible = false;
	}

	var currentPlayingPath:String = "";
	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (blockFreeplayInputs) return;
		_updateSongLastDifficulty();
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var lastList:Array<String> = Difficulty.list;
		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;
			
		var newColor:Int = songs[curSelected].color;
		if(newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			bullShit++;
			item.alpha = 0.6;
			if (item.targetY == curSelected)
				item.alpha = 1;
		}
		
        if (songs[curSelected].songCharacter == "sm") {
			curDifficulty = 0;
			var smDiffName:String = songs[curSelected].smDifficulties[curDifficulty];
			if(smDiffName != null) {
				diffText.text = '< ' + smDiffName + ' >';
			} else {
				diffText.text = '< NORMAL >';
			}
			#if !switch
			var formattedSongName:String = Paths.formatToSongPath(songs[curSelected].songName) + "-" + smDiffName.toLowerCase();
			intendedScore = Highscore.getScore(formattedSongName, 0);
			intendedRating = Highscore.getRating(formattedSongName, 0);
			#end
			positionHighscore();
		}

			Mods.currentModDirectory = songs[curSelected].folder;
			PlayState.storyWeek = songs[curSelected].week;
			Difficulty.loadFromWeek();
			var savedDiff:String = songs[curSelected].lastDifficulty;
			var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
			
			if(savedDiff != null && !lastList.contains(savedDiff) && Difficulty.list.contains(savedDiff))
				curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
			else if(lastDiff > -1)
				curDifficulty = lastDiff;
			else if(Difficulty.list.contains(Difficulty.getDefault()))
				curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
			else
				curDifficulty = 0;


		pendingPreview = finalAudioPath;
		previewDelay = 0.15;

		// =======================================================================
		// PREVIEWS DE STEPMANIA 
		// =======================================================================

		var cancionActual = songs[curSelected];

		if (cancionActual.isSMFile || cancionActual.songCharacter == "sm") 
		{
			if (FlxG.sound.music != null && FlxG.sound.music.playing) {
				FlxG.sound.music.pause();
			}

			var targetTitle:String = cancionActual.songName.toLowerCase().trim();
			var songKey = cancionActual.songName.toLowerCase().trim();
				var finalAudioPath = CacheSongsSM.songPaths.get(songKey);
				var tiempoInicio = CacheSongsSM.songSampleStarts.get(songKey);
			//var tiempoInicio:Int = 30000; 
			try {
				if (cancionActual.sm != null && cancionActual.sm.header != null) {
					if (Reflect.hasField(cancionActual.sm.header, "SAMPLESTART")) {
						var sampleStart:Float = Std.parseFloat(Reflect.field(cancionActual.sm.header, "SAMPLESTART"));
						if (!Math.isNaN(sampleStart) && sampleStart > 0) {
							tiempoInicio = Std.int(sampleStart * 1000);
						}
					}
				}
			} catch(e:Dynamic) {
				tiempoInicio = 30000;
			}
            if (previewTimer != null) previewTimer.cancel();
			previewTimer = new FlxTimer().start(0.15, function(tmr:FlxTimer) {
			if (finalAudioPath != "" && sys.FileSystem.exists(finalAudioPath)) 
			{
                #if VIDEOS_ALLOWED
				try {
					if (currentPlayingPath != finalAudioPath) 
					{
						previewMP3.play(finalAudioPath, true);
						previewMP3.bitmap.time = tiempoInicio;
						
						currentPlayingPath = finalAudioPath; 
						
						trace("preview: " + currentPlayingPath);
					}
			
				} catch(e:Dynamic) {
					trace("Error cargar: " + e);
				}
				#else
				try {
					var bytes = sys.io.File.getBytes(finalAudioPath);
					var sound = new openfl.media.Sound();
					sound.loadCompressedDataFromByteArray(bytes.getData(), bytes.length);
					
					FlxG.sound.playMusic(sound, 0.7, true);
					FlxG.sound.music.time = tiempoInicio;
				} catch(e:Dynamic) {
					trace("Error Pa" + e);
				}
				#end
			}
			});
		}
		else 
		{
			#if VIDEOS_ALLOWED
			if (previewMP3 != null) { previewMP3.stop(); }
			#end
			//trace("Test");
				if (FlxG.sound.music != null) {
					if (!FlxG.sound.music.playing) FlxG.sound.music.resume();
					FlxG.sound.music.volume = 0.7; 
				}
			
		}
	
	
		// =======================================================================

		changeDiff();
		_updateSongLastDifficulty();
	}

	inline private function _updateSongLastDifficulty()
	{
		songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty);
	}

	private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	public function updateTexts(elapsed:Float = 0.0)
	{
		lerpSelected = FlxMath.lerp(lerpSelected, curSelected, FlxMath.bound(elapsed * 9.6, 0, 1));
		for (i in _lastVisibles)
		{
			grpSongs.members[i].visible = grpSongs.members[i].active = false;
			iconArray[i].visible = iconArray[i].active = false;
		}
		_lastVisibles = [];

		var min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + _drawDistance)));

		for (i in min...max)
		{
			var item:Alphabet = grpSongs.members[i];
			item.visible = item.active = true;
			item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

			var icon:HealthIcon = iconArray[i];
			icon.visible = icon.active = true;
			_lastVisibles.push(i);
		}
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
		#if FEATURE_STEPMANIA
		public var isSMFile:Bool = false;
	public var sm:SMFile;
	public var path:String;
	public var smDifficulties:Array<String> = [];
	#end
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";
	public var lastDifficulty:String = null;
	public var smPath:String = "";


#if FEATURE_STEPMANIA
	public function new(song:String, week:Int, songCharacter:String, color:Int, ?sm:SMFile = null, ?path:String = "")
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.sm = sm;
		this.folder = Mods.currentModDirectory;
		if(this.folder == null) this.folder = '';
		this.path = path;
		this.color = color;
	}
	#else

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
	#end
}