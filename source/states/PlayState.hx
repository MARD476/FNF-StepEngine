package states;

// If you want to add your stage to the game, copy states/stages/Template.hx,
// and put your stage code there, then, on PlayState, search for
// "switch (curStage)", and add your stage to that list.

// If you want to code Events, you can either code it on a Stage file or on PlayState, if you're doing the latter, search for:
// "function eventPushed" - Only called *one time* when the game loads, use it for precaching events that use the same assets, no matter the values
// "function eventPushedUnique" - Called one time per event, use it for precaching events that uses different assets based on its values
// "function eventEarlyTrigger" - Used for making your event start a few MILLISECONDS earlier
// "function triggerEvent" - Called when the song hits your event's timestamp, this is probably what you were looking for

import backend.Achievements;
import backend.Highscore;
import backend.StageData;
import backend.WeekData;
import backend.Song;
import backend.Section;
import backend.Rating;

#if FEATURE_STEPMANIA
import smTools.SMFile;
#end

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.math.FlxPoint;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.animation.FlxAnimationController;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import lime.app.Application;
import lime.graphics.RenderContext;
import lime.ui.MouseButton;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.Window;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.media.Sound;
import openfl.display.BitmapData;
import openfl.Lib;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import openfl.events.KeyboardEvent;
import tjson.TJSON as Json;

import cutscenes.CutsceneHandler;
import cutscenes.DialogueBoxPsych;

import states.StoryMenuState;
import states.FreeplayState;
import states.editors.ChartingState;
import states.editors.CharacterEditorState;

import substates.PauseSubState;
import substates.GameOverSubstate;

#if !flash 
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if VIDEOS_ALLOWED 
#if (hxCodec >= "3.0.0") import hxcodec.flixel.FlxVideo as VideoHandler;
#elseif (hxCodec >= "2.6.1") import hxcodec.VideoHandler as VideoHandler;
#elseif (hxCodec == "2.6.0") import VideoHandler;
#else import vlc.MP4Handler as VideoHandler; #end
#end

import hxcodec.flixel.FlxVideoSprite;

import flxgif.FlxGifSprite;
import hxwindowmode.WindowColorMode;

import objects.Note.EventNote;
import objects.*;
import states.stages.objects.*;

#if LUA_ALLOWED
import psychlua.*;
#else
import psychlua.FunkinLua;
import psychlua.LuaUtils;
import psychlua.HScript;
#end

import FlxVideoSprite;

import flxgif.FlxGifSprite;

#if (SScript >= "3.0.0")
import tea.SScript;
#end

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;
	public static var ratingStuff:Array<Dynamic> = [
		['F', 0.2], //From 0% to 19%
		['E', 0.4], //From 20% to 39%
		['D', 0.5], //From 40% to 49%
		['C', 0.6], //From 50% to 59%
		['B', 0.69], //From 60% to 68%
		['A', 0.7], //69%
		['AA', 0.8], //From 70% to 79%
		['AAA', 0.9], //From 80% to 89%
		['AAAA', 1], //From 90% to 99%
		['AAAAA', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];

	//event variables
	public var isCameraOnForcedPos:Bool = false;

	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	
	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	#end

	#if LUA_ALLOWED
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, FlxText> = new Map<String, FlxText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public static var stageUI:String = "normal";
	public static var isPixelStage(get, never):Bool;

	@:noCompletion
	static function get_isPixelStage():Bool
		return stageUI == "pixel";

	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 2000;

	public var vocals:FlxSound;
	public var inst:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	public var camFollow:FlxObject;
	private static var prevCamFollow:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	public var healthBar:HealthBar;
	public var timeBar:HealthBar;
	public var healthBarOverlay:FlxSprite;
	var songPercent:Float = 0;

	public var ratingsData:Array<Rating> = Rating.loadDefault();
	public var fullComboFunction:Void->Void = null;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Int> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	#if LUA_ALLOWED
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	#end
	public var introSoundsSuffix:String = '';

	// Less laggy controls
	private var keysArray:Array<String>;

	public var precacheList:Map<String, String> = new Map<String, String>();
	public var songName:String;

	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;

	var difi:FlxSprite;

	public static var opponentWindow:Window;
	public static var playerWindow:Window;
	public static var opponentWin = new Sprite();
	public static var playerWin = new Sprite();
	public static var opponentScrollWin = new Sprite();
	public static var playerScrollWin = new Sprite();
	public var instaTween:Float = 0.3;

	var imageCool = new Sprite();
	var image:FlxGifSprite;
	var imagePoses:String;

	var posess = "MAYAMIVIEJAWEEEEEEEEE";

	var display = Application.current.window.display.currentMode;

    public var customXOpp:Int = 0;
	public var customYOpp:Int = 0;
	public var customXPla:Int = 0;
	public var customYPla:Int = 0;
	var windowMove:Bool = false;
	var windowMovePla:Bool = false;
	var windowMoveLong:Bool = false;
	var enableTween:Bool = false;
	var windowTween:Array<FlxTween> = [];
	// WINDOW MOVE VAR
	var winx:Int;
	var winy:Int;

	var win:Application;

	var changex:Int;
	var changey:Int;

	var mueveteBro:Bool = false;

	var normalWinX:Int;
	var normalWinY:Int;
	
	var boomSpeed:Float = 0;
	var bamZoom:Float = 0;

	var trailunderdad:FlxTrail;

	var startAutoplay:Bool = false;

	public var camCounter:FlxCamera;

	var blackCam:FlxSprite;

	var zoomBlurAllowed:Bool = true;
	var intensityBlur:Float = 200;
	var posBlur = {x: 0.5, y: 0.5};

	var shaderZoomBlur = null;
	var shaderFilterZoomBlur = null;


	var shaderBlur = null;
	var filtersBlur = null;

	var shaderStatic = null;
	var filtersStatic = null;
	var tottalTime:Float = 0;

	var pixelShaders = null;
	var pixelFilters = null;
	var progressTrans:Float = 0;

	var transitionColor:Array<Float> = [0, 0, 0, 1];

	var addFilters = null;

	var zoomHUDTween:FlxTween;

	var vgRed:FlxSprite;
	var blackRar:FlxSprite;

	var winMoveNote:Bool = false;

	public var enableGifAnim:Bool = true;
	public var gifXI:Int = 0;
    public var gifYI:Int = 0;

	public var gifXL:Int = 0;
    public var gifYL:Int = 0;

	public var gifXD:Int = 0;
    public var gifYD:Int = 0;

	public var gifXU:Int = 0;
    public var gifYU:Int = 0;

	public var gifXR:Int = 0;
    public var gifYR:Int = 0;
/////////////////////////////////////////
	public var gifXIB:Int = 0;
    public var gifYIB:Int = 0;

	public var gifXLB:Int = 0;
    public var gifYLB:Int = 0;

	public var gifXDB:Int = 0;
    public var gifYDB:Int = 0;

	public var gifXUB:Int = 0;
    public var gifYUB:Int = 0;

	public var gifXRB:Int = 0;
    public var gifYRB:Int = 0;

	var shouldFreezeForSM:Bool = false;

	////////////////////////////////////////////

	public var gifXIG:Int = 0;
    public var gifYIG:Int = 0;

	public var gifXLG:Int = 0;
    public var gifYLG:Int = 0;

	public var gifXDG:Int = 0;
    public var gifYDG:Int = 0;

	public var gifXUG:Int = 0;
    public var gifYUG:Int = 0;

	public var gifXRG:Int = 0;
    public var gifYRG:Int = 0;

	public var gifScaleX:Int = 0;
    public var gifScaleY:Int = 0;

	public var imageGifDad:FlxGifSprite; 
	var gifCacheDad:Map<String, FlxGifSprite> = new Map<String, FlxGifSprite>();
	var gifCacheGf:Map<String, FlxGifSprite> = new Map<String, FlxGifSprite>();
	var gifCacheBf:Map<String, FlxGifSprite> = new Map<String, FlxGifSprite>();

	public static var activeDesktopEffect:Bool = false;

	var boppingHUD:Float;
	var boppingHUDTween:FlxTween;
	var boppingGameTween:FlxTween;

	var beatApp:Float = 2;

	public static var optimizeMod:Bool = false;

	public static var isSM:Bool = false;
	#if FEATURE_STEPMANIA
	public static var sm:SMFile;
	public static var pathToSm:String;
	var blackStage:FlxSprite;
	#end

	private var stopEndTime:Float = -1;
	private var stopActive:Bool = false;

	public var baseScrollBPM:Float = 120;

	#if VIDEOS_ALLOWED
	public var mp3Nativo:FlxVideoSprite;
	#end

	public var smFolder:String = ""; 
	public var bgVideo:FlxVideoSprite = null; 
	public var bgSprite:FlxSprite = new FlxSprite(); 


	private var lastSystemTime:Float = 0;

	// tiempo real 
	private var songSystemStartStamp:Float = 0;
	// posición del audio (ms)
	private var songLastAudioTime:Float = 0;
	// reloj del sistema 
	private var useSystemClock:Bool = false;

	// No se xd
	private var songPositionAtStop:Float = 0;

var bgFile:String = "";

var valueValues:String = "";

var firstSyncDone:Bool = false;

	override public function create()
	{
		//trace('Playback Rate: ' + playbackRate);
		Paths.clearStoredMemory();

		startCallback = startCountdown;
		endCallback = endSong;

		// for lua
		instance = this;

		PauseSubState.songName = null; //Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed');
		fullComboFunction = fullComboUpdate;

		keysArray = [
			'note_left',
			'note_down',
			'note_up',
			'note_right'
		];

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		winx = Lib.application.window.x;
		winy = Lib.application.window.y;
		changex = winx;
		changey = winy;		

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain');
		healthLoss = ClientPrefs.getGameplaySetting('healthloss');
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill');
		practiceMode = ClientPrefs.getGameplaySetting('practice');
		cpuControlled = ClientPrefs.getGameplaySetting('botplay');

		startAutoplay = cpuControlled;

		optimizeMod = ClientPrefs.data.lowQuality;

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camCounter = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camCounter.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camCounter, false);
		FlxG.cameras.add(camOther, false);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = true;
		persistentDraw = true;

		firstSyncDone = false;

		smFolder = Reflect.field(PlayState, "pathToSm");

		/*if (SONG == null)
			SONG = Song.loadFromJson('tutorial');*/

		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		baseScrollBPM = SONG.bpm;

		TimingStruct.clearTimings();

		var currentIndex = 0;
		for (event in SONG.events)
		{
			var eventName:String = event[1][0][0]; 
			
			if (eventName == "Change BPM")
			{
				var bpmValue:Float = Std.parseFloat(event[1][0][1]);
				var timeInMs:Float = event[0];
				
				var beat:Float = (timeInMs / 1000) * (Conductor.bpm / 60);

				var endBeat:Float = Math.POSITIVE_INFINITY;
				var bpm = bpmValue * playbackRate;

				TimingStruct.addTiming(beat, bpm, endBeat, 0);

				if (currentIndex != 0)
				{
					var data = TimingStruct.AllTimings[currentIndex - 1];
					data.endBeat = beat;
					data.length = ((data.endBeat - data.startBeat) / (data.bpm / 60)) / playbackRate;
					var step = ((60 / data.bpm) * 1000) / 4;
					
					var prevTiming = TimingStruct.AllTimings[currentIndex];
					prevTiming.startStep = Math.floor((((data.endBeat / (data.bpm / 60)) * 1000) / step) / playbackRate);
					prevTiming.startTime = data.startTime + data.length / playbackRate;
				}
				currentIndex++;
			}
		}

		#if desktop
		storyDifficultyText = Difficulty.getString();

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		else
			detailsText = "Freeplay";

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		songName = Paths.formatToSongPath(SONG.song);
		if(SONG.stage == null || SONG.stage.length < 1) {
			SONG.stage = StageData.vanillaSongStage(songName);
		}
		curStage = SONG.stage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = StageData.dummy();
		}

		defaultCamZoom = stageData.defaultZoom;

		stageUI = "normal";
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			stageUI = stageData.stageUI;
		else {
			if (stageData.isPixelStage)
				stageUI = "pixel";
		}
		
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage': new states.stages.StageWeek1(); //Week 1
			case 'spooky': new states.stages.Spooky(); //Week 2
			case 'philly': 
			new states.stages.Philly(); //Week 3
			/*var posesFrecuentes:Array<String> = ['Left', 'Down', 'Up', 'Right', 'Idle'];
            enableGifAnim = true;

			if (enableGifAnim)
			{
				for (pose in posesFrecuentes) {
					var preGIF = new FlxGifSprite(0, 0).loadGif('assets/images/deadHope/' + pose + '.gif');
					gifCache.set(pose, preGIF);
				}			
			}*/

			case 'limo': new states.stages.Limo(); //Week 4
			case 'mall': new states.stages.Mall(); //Week 5 - Cocoa, Eggnog
			case 'mallEvil': new states.stages.MallEvil(); //Week 5 - Winter Horrorland
			case 'school': new states.stages.School(); //Week 6 - Senpai, Roses
			case 'schoolEvil': new states.stages.SchoolEvil(); //Week 6 - Thorns
			case 'tank': new states.stages.Tank(); //Week 7 - Ugh, Guns, Stress
			case 'liesStage': 
				var bg:FlxSprite = new FlxSprite().makeGraphic(4000, 2000, FlxColor.fromRGB(1, 1, 1));
				bg.screenCenter();
				bg.scrollFactor.set();
				add(bg);
				FlxTransWindow.getWindowsTransparent(); 
				FlxTransWindow.getWindowsbackward();
				Lib.application.window.resizable = false;
				normalWinX = Lib.application.window.x;
				normalWinY = Lib.application.window.y;
			    new states.stages.StageLiar(); 
					vgRed = new FlxSprite();
					vgRed.frames = Paths.getSparrowAtlas('Lies/VgAnim', 'shared', true);
					vgRed.animation.addByPrefix('RedVgAnim', 'RedAlpha', 12, true);
					vgRed.cameras = [camCounter];
					vgRed.alpha = 0.5;
					vgRed.visible = false;
					vgRed.screenCenter();
					add(vgRed);
					vgRed.animation.play('RedVgAnim');	


				blackCam = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
				blackCam.alpha = 1;
				blackCam.cameras = [camCounter];
				add(blackCam);
		}

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}

			blackRar = new FlxSprite(-500, -300).makeGraphic(5000, 5000, FlxColor.BLACK);
			blackRar.visible = false;
			add(blackRar);	

		add(gfGroup);
	
		add(dadGroup);

		add(boyfriendGroup);	

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getPreloadPath(), 'scripts/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
			{
				if(file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);
				if(file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
			}
		#end

		// STAGE SCRIPTS
		#if LUA_ALLOWED
		startLuasNamed('stages/' + curStage + '.lua');
		#end

		#if HSCRIPT_ALLOWED
		startHScriptsNamed('stages/' + curStage + '.hx');
		#end

		if (!stageData.hide_girlfriend)
		{
			if(SONG.gfVersion == null || SONG.gfVersion.length < 1) SONG.gfVersion = 'gf'; //Fix for the Chart Editor
			gf = new Character(0, 0, SONG.gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterScripts(gf.curCharacter);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterScripts(dad.curCharacter);

		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterScripts(boyfriend.curCharacter);

		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}

		switch (curStage)
		{
			case 'liesStage':
				trailunderdad = new FlxTrail(dad, null, 4, 5, 0.2, 0.067);
					trailunderdad.members[0].x += FlxG.random.float(-1, 4);
					trailunderdad.members[0].y += FlxG.random.float(-1, 4);
				insert(members.indexOf(dadGroup), trailunderdad);
				remove(trailunderdad);
				
				difi = new FlxSprite(0, 30).loadGraphic(Paths.image("Lies/difuminado"));
				difi.scale.set(3,3);
				difi.alpha = 0.7;
				difi.scrollFactor.set();
				insert(members.indexOf(boyfriendGroup) + 1, difi);	
		}

        if (isSM)
		{
					blackStage = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		blackStage.antialiasing = ClientPrefs.data.antialiasing;
		blackStage.scrollFactor.set();
		blackStage.visible = isSM;
		blackStage.cameras = [camHUD];
		blackStage.color = 0xFF222222;
		add(blackStage);
		}


		if (isSM)
		{
			if (sm != null)
			bgFile = getDefaultBackground(smFolder, sm.header);
			else
				bgFile = getDefaultBackground(smFolder, null);

			if (bgFile != "")
			{
				triggerEvent("BG Change", bgFile, "", 0);
		    }
		}


		//skipCountdown = true;

		
		stagesFunc(function(stage:BaseStage) stage.createPost());

		Conductor.songPosition = -5000 / Conductor.songPosition;
		var showTime:Bool = (ClientPrefs.data.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = updateTime = showTime;
		if(ClientPrefs.data.downScroll) timeTxt.y = FlxG.height - 44;
		if(ClientPrefs.data.timeBarType == 'Song Name') timeTxt.text = SONG.song;

		timeBar = new HealthBar(0, timeTxt.y + (timeTxt.height / 4), 'timeBar', function() return songPercent, 0, 1);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		if(ClientPrefs.data.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var splash:NoteSplash = new NoteSplash(100, 100);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.000001; //cant make it invisible or it won't allow precaching

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		generateSong(SONG.song);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();
				
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.snapToTarget();

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		moveCameraSection();

		healthBar = new HealthBar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.11), 'healthBar', function() return health, 0, 2);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.data.hideHud;
		healthBar.alpha = ClientPrefs.data.healthBarAlpha;
		reloadHealthBarColors();
		add(healthBar);

		healthBarOverlay = new FlxSprite().loadGraphic(Paths.image('healthBarOverlay'));
		healthBarOverlay.y = FlxG.height * 0.89;
		healthBarOverlay.screenCenter(X);
		healthBarOverlay.scrollFactor.set();
		healthBarOverlay.visible = !ClientPrefs.data.hideHud;
        healthBarOverlay.color = FlxColor.BLACK;
		healthBarOverlay.blend = MULTIPLY;
		healthBarOverlay.x = healthBar.x-1.9;
	    healthBarOverlay.alpha = ClientPrefs.data.healthBarAlpha;
		add(healthBarOverlay); healthBarOverlay.alpha = ClientPrefs.data.healthBarAlpha; if(ClientPrefs.data.downScroll) healthBarOverlay.y = 0.11 * FlxG.height;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.data.hideHud;
		iconP1.alpha = ClientPrefs.data.healthBarAlpha;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.data.hideHud;
		iconP2.alpha = ClientPrefs.data.healthBarAlpha;
		add(iconP2);

		scoreTxt = new FlxText(0, healthBar.y + 28, FlxG.width, "", 16);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.2;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		add(scoreTxt);

		botplayTxt = new FlxText(400, timeBar.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = false;
		add(botplayTxt);
		if(ClientPrefs.data.downScroll) {
			botplayTxt.y = timeBar.y - 78;
		}

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];

		healthBar.cameras = [camHUD];
		healthBarOverlay.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];

		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeTxt.cameras = [camHUD];

		switch(SONG.song.toLowerCase())
		{
			case 'liar':
			    //dad.color = FlxColor.fromRGB(60, 60, 60); me jode el juego :((
				dad.alpha = 0;
				boyfriend.color = FlxColor.fromRGB(60, 60, 60); 
				for (spr in [healthBar, iconP1, iconP2, scoreTxt, timeBar, timeTxt])
                spr.visible = false; 
		}			

		startingSong = true;
		
		#if LUA_ALLOWED
		for (notetype in noteTypes)
			startLuasNamed('custom_notetypes/' + notetype + '.lua');

		for (event in eventsPushed)
			startLuasNamed('custom_events/' + event + '.lua');
		#end

		#if HSCRIPT_ALLOWED
		for (notetype in noteTypes)
			startHScriptsNamed('custom_notetypes/' + notetype + '.hx');

		for (event in eventsPushed)
			startHScriptsNamed('custom_events/' + event + '.hx');
		#end
		noteTypes = null;
		eventsPushed = null;

		if(eventNotes.length > 1)
		{
			for (event in eventNotes) event.strumTime -= eventEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getPreloadPath(), 'data/' + songName + '/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
			{
				if(file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);
				if(file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
			}
		#end

		startCallback();
		RecalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if(ClientPrefs.data.hitsoundVolume > 0) precacheList.set('hitsound', 'sound');
		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');

		if (PauseSubState.songName != null) {
			precacheList.set(PauseSubState.songName, 'music');
		} else if(ClientPrefs.data.pauseMusic != 'None') {
			precacheList.set(Paths.formatToSongPath(ClientPrefs.data.pauseMusic), 'music');
		}

		precacheList.set('alphabet', 'image');
		resetRPC();

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		callOnScripts('onCreatePost');

		//shader 	
		switch(SONG.song.toLowerCase())
		{
			case 'liar':
			    /// TV STATIC ///
			    initLuaShader('tvstatic');
			    shaderStatic = createRuntimeShader('tvstatic');
                filtersStatic = new ShaderFilter(shaderStatic);

                @:privateAccess
				var currentFiltersGameStatic = camGame._filters;
				if (currentFiltersGameStatic == null) currentFiltersGameStatic = [];
				currentFiltersGameStatic.push(filtersStatic);

                @:privateAccess
				camGame._filters = currentFiltersGameStatic;
				shaderStatic.setFloat('time', 3); shaderStatic.setFloat('strength', 0.1); shaderStatic.setFloat('speed', 20);


				/// BLUR ///
			    initLuaShader('blur');
				shaderBlur = createRuntimeShader('blur');
				filtersBlur = new ShaderFilter(shaderBlur);

                @:privateAccess
				var currentFiltersGameBlur = camHUD._filters;
				if (currentFiltersGameBlur == null) currentFiltersGameBlur = [];
				currentFiltersGameBlur.push(filtersBlur);


				@:privateAccess
				camHUD._filters = currentFiltersGameBlur;
				shaderBlur.setFloat('dim', 10); shaderBlur.setFloat('size', 20);


                /// ZOOM BLUR ///
				initLuaShader('zoomblur');
				shaderZoomBlur = createRuntimeShader('zoomblur');
				shaderFilterZoomBlur = new ShaderFilter(shaderZoomBlur);
				
				//Game//
				@:privateAccess
				var currentFiltersGameBlurZoom = camGame._filters;
				if (currentFiltersGameBlurZoom == null) currentFiltersGameBlurZoom = [];
				currentFiltersGameBlurZoom.push(shaderFilterZoomBlur);

				@:privateAccess
				camGame._filters = currentFiltersGameBlurZoom;

				//HUD//
				@:privateAccess
				var currentFiltersHUDZoomBlur = camHUD._filters;
				if (currentFiltersHUDZoomBlur == null) currentFiltersHUDZoomBlur = [];
				currentFiltersHUDZoomBlur.push(shaderFilterZoomBlur);

				@:privateAccess
				camHUD._filters = currentFiltersHUDZoomBlur;

				shaderZoomBlur.setFloat('posX', posBlur.x); 
				shaderZoomBlur.setFloat('posY', posBlur.y);


                /// PIXEL TRANSITION ///
                initLuaShader('pixeltransition'); 
				pixelShaders = createRuntimeShader('pixeltransition');
				pixelFilters = new ShaderFilter(pixelShaders);

                @:privateAccess
				var currentFiltersGamePixel = camGame._filters;
				if (currentFiltersGamePixel == null) currentFiltersGamePixel = [];
				currentFiltersGamePixel.push(pixelFilters);

                @:privateAccess
				camGame._filters = currentFiltersGamePixel;
	            pixelShaders.setFloat("progress_trans", 0);
				pixelShaders.setFloatArray("transition_color", transitionColor);
		}	

		cacheCountdown();
		cachePopUpScore();
		
		for (key => type in precacheList)
		{
			//trace('Key $key is type $type');
			switch(type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}

		super.create();
		Paths.clearUnusedMemory();
		
		CustomFadeTransition.nextCamera = camOther;
		if(eventNotes.length < 1) checkEventNote();
	}

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			if(ratio != 1)
			{
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		songSpeed = value;
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);
		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		if(generatedMusic)
		{
			if(vocals != null) vocals.pitch = value;
			FlxG.sound.music.pitch = value;

			var ratio:Float = playbackRate / value; //funny word huh
			if(ratio != 1)
			{
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		playbackRate = value;
		FlxAnimationController.globalSpeed = value;
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * value;
		setOnScripts('playbackRate', playbackRate);
		return value;
	}

	public function addTextToDebug(text:String, color:FlxColor) {
		#if LUA_ALLOWED
		var newText:DebugLuaText = luaDebugGroup.recycle(DebugLuaText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);

		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += newText.height + 2;
		});
		luaDebugGroup.add(newText);
		#end
	}

	public function reloadHealthBarColors() {
		healthBar.setColors(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScripts(newBoyfriend.curCharacter);
					if (newCharacter == "pico-pre")
					{
						newBoyfriend.color = FlxColor.fromRGB(60, 60, 60);
					}  
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScripts(newDad.curCharacter);

					if (newCharacter == "fish")
					{
                        //newChar.scale.set(1.2,1.2);
						newDad.color = FlxColor.fromRGB(120, 120, 120);
					}    
					if (newCharacter == "bffal")
					{
						//newChar.scale.set(1.2,1.2);
						newDad.color = FlxColor.fromRGB(100, 100, 100);
					}    
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScripts(newGf.curCharacter);
				}
		}
	}

	function startCharacterScripts(name:String)
	{
		// Lua
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(luaFile);
		if(FileSystem.exists(replacePath))
		{
			luaFile = replacePath;
			doPush = true;
		}
		else
		{
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile))
				doPush = true;
		}
		#else
		luaFile = Paths.getPreloadPath(luaFile);
		if(Assets.exists(luaFile)) doPush = true;
		#end

		if(doPush)
		{
			for (script in luaArray)
			{
				if(script.scriptName == luaFile)
				{
					doPush = false;
					break;
				}
			}
			if(doPush) new FunkinLua(luaFile);
		}
		#end

		// HScript
		#if HSCRIPT_ALLOWED
		var doPush:Bool = false;
		var scriptFile:String = 'characters/' + name + '.hx';
		var replacePath:String = Paths.modFolders(scriptFile);
		if(FileSystem.exists(replacePath))
		{
			scriptFile = replacePath;
			doPush = true;
		}
		else
		{
			scriptFile = Paths.getPreloadPath(scriptFile);
			if(FileSystem.exists(scriptFile))
				doPush = true;
		}
		
		if(doPush)
		{
			if(SScript.global.exists(scriptFile))
				doPush = false;

			if(doPush) initHScript(scriptFile);
		}
		#end
	}

	public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		#if LUA_ALLOWED
		if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if(text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		if(variables.exists(tag)) return variables.get(tag);
		#end
		return null;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;

		var filepath:String = Paths.video(name);
		#if sys
		if(!FileSystem.exists(filepath))
		#else
		if(!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}

		var video:VideoHandler = new VideoHandler();
			#if (hxCodec >= "3.0.0")
			// Recent versions
			video.play(filepath);
			video.onEndReached.add(function()
			{
				video.dispose();
				startAndEnd();
				return;
			}, true);
			#else
			// Older versions
			video.playVideo(filepath);
			video.finishCallback = function()
			{
				startAndEnd();
				return;
			}
			#end
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}

	function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogue')))" and it should load dialogue.json
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			startAndEnd();
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		var introImagesArray:Array<String> = switch(stageUI) {
			case "pixel": ['${stageUI}UI/ready-pixel', '${stageUI}UI/set-pixel', '${stageUI}UI/date-pixel'];
			case "normal": ["ready", "set" ,"go"];
			default: ['${stageUI}UI/ready', '${stageUI}UI/set', '${stageUI}UI/go'];
		}
		introAssets.set(stageUI, introImagesArray);
		var introAlts:Array<String> = introAssets.get(stageUI);
		for (asset in introAlts) Paths.image(asset);
		
		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	public function startCountdown()
	{
		if(startedCountdown) {
			callOnScripts('onStartCountdown');
			return false;
		}

		seenCutscene = true;
		inCutscene = false;
		var ret:Dynamic = callOnScripts('onStartCountdown', null, true);
		if(ret != FunkinLua.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);
			for (i in 0...playerStrums.length) {
				setOnScripts('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnScripts('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnScripts('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnScripts('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				//if(ClientPrefs.data.middleScroll) opponentStrums.members[i].visible = false;
			}

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5;
			setOnScripts('startedCountdown', true);
			callOnScripts('onCountdownStarted', null);

			var swagCounter:Int = 0;
			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return true;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return true;
			}
			moveCameraSection();

			if (!isSM)
			{


				startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
				{
					if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
					{
						gf.dance(); 
						if (enableGifAnim) gifCharacterNoteGf('Idle',gifXIG,gifYIG);
					}
						
					if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
					{
						boyfriend.dance(); 
						if (enableGifAnim) gifCharacterNoteBf('Idle',gifXIB,gifYIB);
					}

					if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
					{
						dad.dance(); 
						if (enableGifAnim) gifCharacterNoteDad('Idle',gifXI,gifYI);
					}
						
					var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
					var introImagesArray:Array<String> = switch(stageUI) {
						case "pixel": ['${stageUI}UI/ready-pixel', '${stageUI}UI/set-pixel', '${stageUI}UI/date-pixel'];
						case "normal": ["ready", "set" ,"go"];
						default: ['${stageUI}UI/ready', '${stageUI}UI/set', '${stageUI}UI/go'];
					}
					introAssets.set(stageUI, introImagesArray);

					var introAlts:Array<String> = introAssets.get(stageUI);
					var antialias:Bool = (ClientPrefs.data.antialiasing && !isPixelStage);
					var tick:Countdown = THREE;

					switch (swagCounter)
					{
						case 0:
							FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
							tick = THREE;
						case 1:
							countdownReady = createCountdownSprite(introAlts[0], antialias);
							FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
							tick = TWO;
						case 2:
							countdownSet = createCountdownSprite(introAlts[1], antialias);
							FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
							tick = ONE;
						case 3:
							countdownGo = createCountdownSprite(introAlts[2], antialias);
							FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
							tick = GO;
						case 4:
							tick = START;
					}

					notes.forEachAlive(function(note:Note) {
						if(ClientPrefs.data.opponentStrums || note.mustPress)
						{
							note.copyAlpha = false;
							note.alpha = note.multAlpha;
							if(ClientPrefs.data.middleScroll && !note.mustPress)
								note.alpha *= 0.35;
						}
					});

					stagesFunc(function(stage:BaseStage) stage.countdownTick(tick, swagCounter));
					callOnLuas('onCountdownTick', [swagCounter]);
					callOnHScript('onCountdownTick', [tick, swagCounter]);

					swagCounter += 1;
				}, 5);
            } else {
				startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
                {
					if (gf != null && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned) gf.dance(); 
					if (boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned) boyfriend.dance();
					if (dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned) dad.dance();

					var tick:Countdown = THREE;
					var antialias:Bool = (ClientPrefs.data.antialiasing && !isPixelStage);

					switch (tmr.loopsLeft)
					{
						case 4:
							var readySprite = createCountdownSprite('ready', antialias); 
							readySprite.screenCenter();
							readySprite.scale.set(0.8, 0.8);
							FlxTween.tween(readySprite.scale, {x: 1, y: 1}, 0.5, {ease: FlxEase.backOut});
							//FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
							tick = THREE;

						case 1:
							var goSprite = createCountdownSprite('go', antialias);
							goSprite.screenCenter();
							FlxTween.tween(goSprite, {alpha: 0, y: goSprite.y - 100}, 0.3, {
								ease: FlxEase.cubeIn,
								onComplete: function(t) { goSprite.destroy(); }
							});
							//FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
							tick = GO;
							
						case 0: 
							if (startingSong)
							{
								if (isSM && shouldFreezeForSM)
								{
									Conductor.songPosition = 0;
								}
								startSong();
							}
					}

					stagesFunc(function(stage:BaseStage) stage.countdownTick(tick, swagCounter));
					swagCounter += 1;
				}, 5);
			}
		}   
		return true;
	}

	inline private function createCountdownSprite(image:String, antialias:Bool):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(image));
		spr.cameras = [camCounter];
		spr.scrollFactor.set();
		spr.updateHitbox();

		if (PlayState.isPixelStage)
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom));

		spr.screenCenter();
		spr.antialiasing = antialias;
		insert(members.indexOf(notes), spr);
		FlxTween.tween(spr, {/*y: spr.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				remove(spr);
				spr.destroy();
			}
		});
		return spr;
	}

	public function addBehindGF(obj:FlxBasic)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxBasic)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindDad(obj:FlxBasic)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function updateScore(miss:Bool = false)
	{
		var accuracy:String = '0 %';
		var str:String = 'N/A';
		if(totalPlayed != 0)
		{
			var percent:Float = CoolUtil.floorDecimal(ratingPercent * 100, 2);
			accuracy = '$percent %';
			str = '($ratingFC) $ratingName';
		}

		scoreTxt.text = 'Score: ' + songScore
		+ ' | Combo Breaks: ' + songMisses
		+ ' | Accuracy: ' + accuracy
		+ ' | ' + str;

		if(ClientPrefs.data.scoreZoom && !miss)
		{
			if(scoreTxtTween != null) {
				scoreTxtTween.cancel();
			}
			scoreTxt.scale.x = 1.075;
			scoreTxt.scale.y = 1.075;
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween) {
					scoreTxtTween = null;
				}
			});
		}
		callOnScripts('onUpdateScore', [miss]);
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();
		if (mp3Nativo != null) mp3Nativo.pause();
		if (bgVideo != null)
		{
			bgVideo.canResume = false;
			bgVideo.pause();
		}
		
		if (mp3Nativo != null) mp3Nativo.bitmap.time = Std.int(time); else FlxG.sound.music.time = time; 
		if (bgVideo != null) bgVideo.bitmap.time = Std.int(time);
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.play();
		if (bgVideo != null)
		{
			bgVideo.canResume = true;
			bgVideo.resume();
		}
		if (mp3Nativo != null)
		{
			mp3Nativo.resume(); 
			Conductor.songPosition = time;
			songSystemStartStamp = haxe.Timer.stamp() - (time / 1000.0);
			songLastAudioTime = time;
			useSystemClock = false;
		} else {
			if (Conductor.songPosition <= vocals.length)
			{
				vocals.time = time;
				vocals.pitch = playbackRate;
			}
			vocals.play();
			Conductor.songPosition = time;
			songSystemStartStamp = haxe.Timer.stamp() - (time / 1000.0);
			songLastAudioTime = time;
			useSystemClock = false;
		}


	}

	public function startNextDialogue() {
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue() {
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}

	function startSong():Void
	{
		startingSong = false;

		@:privateAccess
		if (inst != null && inst._sound != null)
		{
			FlxG.sound.playMusic(inst._sound, 1, false);
		}
		else if (mp3Nativo != null)
		{

            mp3Nativo.resume();
		}
		else
		{
			trace("Error: Ninguna fuente de audio fue cargada correctamente.");
		}

		if (bgVideo != null)
		{
			bgVideo.canResume = true;
			bgVideo.resume();
		}
		FlxG.sound.music.pitch = playbackRate;
		if (!isSM) FlxG.sound.music.onComplete = finishSong.bind();
		vocals.play();

		if (mp3Nativo != null)
		{
			var audioPosMs:Float = mp3Nativo.bitmap != null ? mp3Nativo.bitmap.time : 0;
			Conductor.songPosition = audioPosMs;
			songSystemStartStamp = haxe.Timer.stamp() - (audioPosMs / 1000.0);
			songLastAudioTime = audioPosMs;
			useSystemClock = false;
		}
		else if (FlxG.sound.music != null)
		{
			Conductor.songPosition = FlxG.sound.music.time;
			songSystemStartStamp = haxe.Timer.stamp() - (Conductor.songPosition / 1000.0);
			songLastAudioTime = Conductor.songPosition;
			useSystemClock = false;
		}

		switch (curStage)
		{
			case 'stage':
			    //popupWindow2(1000,1000,0,"xd");
		}

		if(startOnTime > 0) setSongTime(startOnTime - 500);
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
			if (mp3Nativo != null) mp3Nativo.pause();
			if (bgVideo != null)
			{
				bgVideo.canResume = false;
				bgVideo.pause();
			}
		}

		// Song duration in a float, useful for the time left feature
		if (mp3Nativo != null) {
			// hxCodec almacena la duración en milisegundos :3
			songLength = mp3Nativo.bitmap.duration; 
		} else if (FlxG.sound.music != null) {
			songLength = FlxG.sound.music.length;
		}
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart');
	}

	var debugNum:Int = 0;
	private var noteTypes:Array<String> = [];
	private var eventsPushed:Array<String> = [];
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeed = PlayState.SONG.speed;
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}

		var songData = SONG;
		Conductor.bpm = songData.bpm;

		curSong = songData.song;
		

		#if FEATURE_STEPMANIA
		if (SONG.needsVoices && !isSM)
			vocals = new FlxSound().loadEmbedded(Paths.voices(songData.song));
		else
			vocals = new FlxSound();
		#else
		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(songData.song));
		else
			vocals = new FlxSound();
		#end

		vocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);

		#if FEATURE_STEPMANIA
		if (!isStoryMode && isSM)
		{
			var targetTitle:String = SONG.song.toLowerCase().trim();
			var finalAudioPath:String = "";

			// Cache de las canciones
			if (CacheSongsSM.songPaths.exists(targetTitle)) {
				finalAudioPath = CacheSongsSM.songPaths.get(targetTitle);
				trace("NAME: " + finalAudioPath);
			} 
			else 
			{
				// por si la cancion no se encuentra en cache
				var formattedSongName:String = Paths.formatToSongPath(SONG.song);
				var nombreCarpetaFinal:String = formattedSongName;
				var folderTarget:String = "assets/sm";
				var seEncontroCarpeta:Bool = false;

				if (sys.FileSystem.exists(folderTarget)) {
					for (folder in sys.FileSystem.readDirectory(folderTarget)) {
						var pathCandidato:String = folderTarget + "/" + folder;
						if (sys.FileSystem.isDirectory(pathCandidato)) {
							if (folder.toLowerCase() == targetTitle) {
								nombreCarpetaFinal = folder;
								seEncontroCarpeta = true;
								break;
							}
						}
					}
				}
				
				finalAudioPath = "assets/sm/" + nombreCarpetaFinal + "/" + formattedSongName + ".mp3"; // si broooo, hay soporte para .mp3
				if (!sys.FileSystem.exists(finalAudioPath)) 
					finalAudioPath = "assets/sm/" + nombreCarpetaFinal + "/" + formattedSongName + ".ogg";
			}

			if (finalAudioPath != "" && sys.FileSystem.exists(finalAudioPath))
			{
				#if VIDEOS_ALLOWED
				inst = null;
				mp3Nativo = new FlxVideoSprite();
				
				mp3Nativo.bitmap.onEndReached.add(function() {
					if (PlayState.instance != null) PlayState.instance.endSong(); 
				});

				mp3Nativo.play(finalAudioPath, false);
				mp3Nativo.pause(); 
				trace("BIEN NAME: " + finalAudioPath);
				#end
			}
			else {
				trace("No se encontró audio");
				inst = new FlxSound().loadEmbedded(Paths.inst(SONG.song));
			}
		}
		else
			inst = new FlxSound().loadEmbedded(Paths.inst(SONG.song));
		#else
		inst = new FlxSound().loadEmbedded(Paths.inst(SONG.song));
		#end

		FlxG.sound.list.add(inst);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var file:String = Paths.json(songName + '/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
				for (i in 0...event[1].length)
					makeEvent(event, i);
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				for (note in unspawnNotes)
				{
					if (note.strumTime - Conductor.songPosition < 500) 
					{
						shouldFreezeForSM = true;
						break;
					}
				}

				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1]<4));
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts

				swagNote.scrollFactor.set();

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				var floorSus:Int = Math.floor(susLength);
				if(floorSus > 0) {
					for (susNote in 0...floorSus+1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
						
						sustainNote.correctionOffset = swagNote.height / 2;
						if(!PlayState.isPixelStage)
						{
							if(oldNote.isSustainNote)
							{
								oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
								oldNote.scale.y /= playbackRate;
								oldNote.updateHitbox();
							}

							if(ClientPrefs.data.downScroll)
								sustainNote.correctionOffset = 0;
						}
						else if(oldNote.isSustainNote)
						{
							oldNote.scale.y /= playbackRate;
							oldNote.updateHitbox();
						}

						if (sustainNote.mustPress) sustainNote.x += FlxG.width / 2; // general offset
						else if(ClientPrefs.data.middleScroll)
						{
							sustainNote.x += 310;
							if(daNoteData > 1) //Up and Right
							{
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if(ClientPrefs.data.middleScroll)
				{
					swagNote.x += 310;
					if(daNoteData > 1) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}

				if(!noteTypes.contains(swagNote.noteType)) {
					noteTypes.push(swagNote.noteType);
				}
			}
		}
		for (event in songData.events) //Event Notes
			for (i in 0...event[1].length)
				makeEvent(event, i);

		unspawnNotes.sort(sortByTime);
		generatedMusic = true;
	}

	// called only once per different event (Used for precaching)
	function eventPushed(event:EventNote) {
		eventPushedUnique(event);
		if(eventsPushed.contains(event.event)) {
			return;
		}

		stagesFunc(function(stage:BaseStage) stage.eventPushed(event));
		eventsPushed.push(event.event);
	}

	// called by every event with the same name
	function eventPushedUnique(event:EventNote) {
		switch(event.event) {
			case "Change Character":
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						var val1:Int = Std.parseInt(event.value1);
						if(Math.isNaN(val1)) val1 = 0;
						charType = val1;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);
			
			case 'Play Sound':
				precacheList.set(event.value1, 'sound');
				Paths.sound(event.value1);
		}
		stagesFunc(function(stage:BaseStage) stage.eventPushedUnique(event));
	}

	function eventEarlyTrigger(event:EventNote):Float {
		var returnedValue:Null<Float> = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], true, [], [0]);
		if(returnedValue != null && returnedValue != 0 && returnedValue != FunkinLua.Function_Continue) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function makeEvent(event:Array<Dynamic>, i:Int)
	{
		var subEvent:EventNote = {
			strumTime: event[0] + ClientPrefs.data.noteOffset,
			event: event[1][i][0],
			value1: event[1][i][1],
			value2: event[1][i][2]
		};
		eventNotes.push(subEvent);
		eventPushed(subEvent);
		callOnScripts('onEventPushed', [subEvent.event, subEvent.value1 != null ? subEvent.value1 : '', subEvent.value2 != null ? subEvent.value2 : '', subEvent.strumTime]);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int):Void
	{
		var strumLineX:Float = ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if(!ClientPrefs.data.opponentStrums) targetAlpha = 0;
				else if(ClientPrefs.data.middleScroll) targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			if (!isStoryMode && !skipArrowStartTween)
			{
				//babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
				babyArrow.alpha = targetAlpha;

			if (player == 1)
				playerStrums.add(babyArrow);
			else
			{
				if(ClientPrefs.data.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		stagesFunc(function(stage:BaseStage) stage.openSubState(SubState));
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (mp3Nativo != null) {
				mp3Nativo.pause();
			}

			if (bgVideo != null)
			{
				bgVideo.canResume = false;
				bgVideo.pause();
			}

			if (startTimer != null && !startTimer.finished) startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished) finishTimer.active = false;
			if (songSpeedTween != null) songSpeedTween.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars)
				if(char != null && char.colorTween != null)
					char.colorTween.active = false;

			#if LUA_ALLOWED
			for (tween in modchartTweens) tween.active = false;
			for (timer in modchartTimers) timer.active = false;
			#end
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		stagesFunc(function(stage:BaseStage) stage.closeSubState());
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (mp3Nativo != null) {
        mp3Nativo.resume();
    }
	 if (bgVideo != null)
	{
		bgVideo.canResume = true;
		bgVideo.resume();
	}

			if (startTimer != null && !startTimer.finished) startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished) finishTimer.active = true;
			if (songSpeedTween != null) songSpeedTween.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars)
				if(char != null && char.colorTween != null)
					char.colorTween.active = true;

			#if LUA_ALLOWED
			for (tween in modchartTweens) tween.active = true;
			for (timer in modchartTimers) timer.active = true;
			#end

			paused = false;
			callOnScripts('onResume');
			resetRPC(startTimer != null && startTimer.finished);
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		if (health > 0 && !paused) resetRPC(Conductor.songPosition > 0.0);
		//if (mp3Nativo != null) mp3Nativo.pause();
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused) DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		//if (mp3Nativo != null) mp3Nativo.pause();
		super.onFocusLost();
	}

	// Updating Discord Rich Presence.
	function resetRPC(?cond:Bool = false)
	{
		#if desktop
		if (cond)
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.data.noteOffset);
		else
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();

		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;
		if (!isSM) Conductor.songPosition = FlxG.sound.music.time;
		if (!isSM) {
			Conductor.songPosition = FlxG.sound.music.time;
			songSystemStartStamp = haxe.Timer.stamp() - (Conductor.songPosition / 1000.0);
			songLastAudioTime = Conductor.songPosition;
			useSystemClock = false;
		}
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			vocals.pitch = playbackRate;
		}
		vocals.play();
	}

	public var stopOffset:Float = 0;

	public function resyncAudioStep():Void
	{
		if(finishTimer != null) return;
		if (songSpeedTween != null) songSpeedTween.cancel();

		Conductor.songPosition = FlxG.sound.music.time - Conductor.offset - stopOffset;
		
		songSystemStartStamp = haxe.Timer.stamp() - ((Conductor.songPosition + Conductor.offset + stopOffset) / 1000.0);
		songLastAudioTime = Conductor.songPosition + Conductor.offset + stopOffset;
		useSystemClock = false;
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	override public function update(elapsed:Float)
	{
		/*if (FlxG.keys.justPressed.NINE)
		{
			iconP1.swapOldIcon();
		}*/

		if (FlxG.keys.justPressed.F11)
		{
			FlxG.fullscreen = !FlxG.fullscreen;
		}

		/*if (FlxG.keys.justPressed.B)
		{
			cpuControlled = true;
		}
		if (FlxG.keys.justPressed.T)
		{
			cpuControlled = false;
		}*/

		callOnScripts('onUpdate', [elapsed]);

		FlxG.camera.followLerp = 0;
		if(!inCutscene && !paused) {
			FlxG.camera.followLerp = FlxMath.bound(elapsed * 2.4 * cameraSpeed * playbackRate / (FlxG.updateFramerate / 60), 0, 1);
			if(!startingSong && !endingSong && boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}

		super.update(elapsed);


		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);

		if(botplayTxt != null && botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnScripts('onPause', null, true);
			if(ret != FunkinLua.Function_Stop) {
				openPauseMenu();
			}
		}

		if (controls.justPressed('debug_1') && !endingSong && !inCutscene)
			openChartEditor();

		iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 0.50)));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, 0.50)));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Int = 26;
		if (health > 2) health = 2;
		iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
		iconP1.animation.curAnim.curFrame = (healthBar.percent < 20) ? 1 : 0;
		iconP2.animation.curAnim.curFrame = (healthBar.percent > 80) ? 1 : 0;

		if (controls.justPressed('debug_2') && !endingSong && !inCutscene)
			openCharacterEditor();


		if (startedCountdown && !paused)
		{
			if(isSM)
			{
				if (stopActive) // para los stops de Stepmania
				{
					stopDurationLeft -= elapsed * 1000 * playbackRate;
					
					Conductor.songPosition = songPositionAtStop;

					if (stopDurationLeft <= 0)
					{
						stopActive = false;
						stopDurationLeft = 0;
						var audioTimeMs:Float = 0;
						var audioAvailable:Bool = false;
						#if VIDEOS_ALLOWED
						if (mp3Nativo != null && mp3Nativo.bitmap != null)
						{
							audioTimeMs = mp3Nativo.bitmap.time;
							audioAvailable = true;
						}
						#end
						if (!audioAvailable && FlxG.sound.music != null)
						{
							audioTimeMs = FlxG.sound.music.time;
							audioAvailable = true;
						}
						var baseMs:Float = audioAvailable ? (audioTimeMs - Conductor.offset - stopOffset) : ((haxe.Timer.stamp() - songSystemStartStamp) * 1000.0 - Conductor.offset - stopOffset);
						songSystemStartStamp = haxe.Timer.stamp() - (baseMs / 1000.0);
						songLastAudioTime = audioAvailable ? audioTimeMs : songLastAudioTime;
						useSystemClock = false;
					}
				}
				else
				{
						//guardar
						var lastPos:Float = Conductor.songPosition;
						
						var audioTimeMs:Float = 0;
						var audioAvailable:Bool = false;
						#if VIDEOS_ALLOWED
						if (mp3Nativo != null && mp3Nativo.bitmap != null)
						{
							audioTimeMs = mp3Nativo.bitmap.time;
							audioAvailable = true;
						}
						#end
						if (!audioAvailable && FlxG.sound.music != null)
						{
							audioTimeMs = FlxG.sound.music.time;
							audioAvailable = true;
						}
						
						var rawTime:Float = audioAvailable ? (audioTimeMs - Conductor.offset - stopOffset) : ( (haxe.Timer.stamp() - songSystemStartStamp) * 1000.0 - Conductor.offset - stopOffset );
						
						if (audioAvailable)
						{
							if (audioTimeMs < 3000 && Math.abs((rawTime + 80) - lastPos) > 10 && !firstSyncDone)
							{
								Conductor.songPosition = rawTime + 80;
								firstSyncDone = true;
							}
							else
							{
								if (audioTimeMs <= songLastAudioTime && audioTimeMs < songLength)
								{
									Conductor.songPosition = lastPos + (elapsed * 1000 * playbackRate);
									useSystemClock = true;
								}
								else
								{
									Conductor.songPosition = rawTime + 80; 
									useSystemClock = false;
								}
							}
							if (audioTimeMs > songLastAudioTime) songLastAudioTime = audioTimeMs;
						}
						else
						{
							Conductor.songPosition = (haxe.Timer.stamp() - songSystemStartStamp) * 1000.0 - Conductor.offset - stopOffset;
							useSystemClock = true;
						}
				}
			} else {
				Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;
			}
		}

		if (startingSong)
		{
            if (isSM && shouldFreezeForSM)
			{
				if (!startedCountdown)
					Conductor.songPosition = -Conductor.crochet * 2;
				else
					Conductor.songPosition = -Conductor.crochet * 2;
			}
			else
			{

				if (startedCountdown && Conductor.songPosition >= 0)
					startSong();
				else if(!startedCountdown)
					Conductor.songPosition = -Conductor.crochet * 5;
			}
		}

		else if (!paused && updateTime)
		{
			var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.data.noteOffset);
			songPercent = (curTime / songLength);

			var songCalc:Float = (songLength - curTime);
			if(ClientPrefs.data.timeBarType == 'Time Elapsed') songCalc = curTime;

			var secondsTotal:Int = Math.floor(songCalc / 1000);
			if(secondsTotal < 0) secondsTotal = 0;

			if(ClientPrefs.data.timeBarType != 'Song Name')
				timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, FlxMath.bound(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, FlxMath.bound(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
		}

		
		if (combo > songMaxCombo)
		{
			songMaxCombo = combo;
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.data.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime * playbackRate;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote, dunceNote.strumTime]);
				callOnHScript('onSpawnNote', [dunceNote]);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			if(!inCutscene)
			{
				if(!cpuControlled) {
					keysCheck();
				} else if(boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
					boyfriend.dance();
					if (enableGifAnim) gifCharacterNoteBf('Idle',gifXIB,gifYIB);
					//boyfriend.animation.curAnim.finish();
				}

				if(notes.length > 0)
				{
					if(startedCountdown)
					{
						var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
						notes.forEachAlive(function(daNote:Note)
						{
							var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
							if(!daNote.mustPress) strumGroup = opponentStrums;

							var strum:StrumNote = strumGroup.members[daNote.noteData];
							daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);

							if(daNote.mustPress)
							{
								if(cpuControlled && !daNote.blockHit && daNote.canBeHit && (daNote.isSustainNote || daNote.strumTime <= Conductor.songPosition))
									goodNoteHit(daNote);
							}
							else if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
								opponentNoteHit(daNote);

							if(daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumNote(strum);

							// Kill extremely late notes and cause misses
							if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
							{
								if (!daNote.isSustainNote && daNote.mustPress && !cpuControlled &&!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
									noteMiss(daNote);

								daNote.active = false;
								daNote.visible = false;

								daNote.kill();
								notes.remove(daNote, true);
								daNote.destroy();
							}
						});
					}
					else
					{
						notes.forEachAlive(function(daNote:Note)
						{
							daNote.canBeHit = false;
							daNote.wasGoodHit = false;
						});
					}
				}
			}
			checkEventNote();
		}

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

        if (!optimizeMod)
		{
			switch(SONG.song.toLowerCase())
			{
				case 'liar':
				tottalTime += elapsed/1000;
				shaderStatic.setFloat('time', tottalTime*1000);

				if (shaderZoomBlur != null) {
					shaderZoomBlur.setFloat('focusPower', zoomBlurAllowed ? (camHUD.zoom - 1) * intensityBlur : 0);
				}

			}
		}

        var win = Application.current.window;

        if (mueveteBro)
		{
			Lib.application.window.x = Std.int(winx);
			Lib.application.window.y = Std.int(winy);
		}

		setOnScripts('cameraX', camFollow.x);
		setOnScripts('cameraY', camFollow.y);
		setOnScripts('botPlay', cpuControlled);
		callOnScripts('onUpdatePost', [elapsed]);    

		if (image != null && image.pixels != null) 
			{
				//imageCool.graphics.clear(); 
				

				imageCool.graphics.beginBitmapFill(image.pixels);
				imageCool.graphics.drawRect(0, 0, image.pixels.width, image.pixels.height);
				imageCool.graphics.endFill();
				
				// Si el GIF tiene un scrollRect hay que actualizarlo también si cambia :O
				imageCool.scrollRect = new Rectangle(0, 0, image.width, image.height);
			}

		/*if (dad.animation.curAnim.finished || dad.animation.curAnim.name == 'idle') {
			if (imagePoses != 'Idle') {
				imagePoses = 'Idle';
				if (image != null && image.pixels != null) image.loadGif('assets/images/Idle.gif');
			}
		}*/	

    /*if (dad != null && dad.animation != null)
    {
        var anim = dad.animation.curAnim;

        if (anim != null)
        {
            if (anim.finished || anim.name == 'idle')
            {
                if (posess != 'Idle')
                {
                    posess = 'Idle';

                    if (frames != null && frames.length > 0)
                    {
                        setPose("idle");
                    }
                }
            }
        }
    }*/

		@:privateAccess
        var oppFrame = dad._frame;
        
        if (oppFrame == null || oppFrame.frame == null) return; // prevents crashes (i think???)

		var framess = oppFrame.frame;
            
        var rect = new Rectangle(framess.x, framess.y, framess.width, framess.height);
        
		opponentScrollWin.scrollRect = rect;

		var centerX:Float = 0;
		var centerY:Float = 0;

		if (opponentWindow != null) {
			centerX = opponentWindow.width / 2;
			centerY = opponentWindow.height / 2;
		}

		if(customXOpp == 0){
			customXOpp = -10;
		}
		if (opponentWindow != null && !windowMove)
		{
						    for (tween in windowTween)
				{
					tween.cancel();
				}
			windowMove = true;
			windowTween.push(FlxTween.tween(opponentWindow, {x: customXOpp, y: Std.int(display.height / customYOpp)}, instaTween, {
					ease: FlxEase.circOut,
					onComplete: function(twn:FlxTween) {
						windowMove = false; // evita la emotiza insana
					}
				}));

		}

	
		opponentScrollWin.x = centerX - (framess.width * opponentScrollWin.scaleX) / 2;
		opponentScrollWin.y = centerY - (framess.height * opponentScrollWin.scaleY) / 2;


		/////////////////////////////////////////////////////////////////////////////////////////////////////////


		@:privateAccess
        var oppFrame2 = boyfriend._frame;
        
        if (oppFrame2 == null || oppFrame2.frame == null) return; // prevents crashes (i think???)

		var framess2 = oppFrame2.frame;
            
        var rect = new Rectangle(framess2.x, framess2.y, framess2.width, framess2.height);
        
        playerScrollWin.scrollRect = rect;

		var centerX2:Float = 0;
		var centerY2:Float = 0;

		if (playerWindow != null) {
			centerX2 = playerWindow.width / 2;
			centerY2 = playerWindow.height / 2;
		}	

		if(customXPla == 0){
			customXPla = -10;
		}
		if (playerWindow != null && !windowMovePla)
		{		
			windowMovePla = true;
			FlxTween.tween(playerWindow, {x: customXPla, y: Std.int(display.height / customYPla)}, instaTween, {
					ease: FlxEase.circOut,
					onComplete: function(twn:FlxTween) {
						windowMovePla = false; 
					}
				});

		}

		playerScrollWin.x = centerX2 - (framess2.width * playerScrollWin.scaleX) / 2;
		playerScrollWin.y = centerY2 - (framess2.height * playerScrollWin.scaleY) / 2;	
				  
	}

	function openPauseMenu()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		// 1 / 1000 chance for Gitaroo Man easter egg
		/*if (FlxG.random.bool(0.1))
		{
			// gitaroo man easter egg
			cancelMusicFadeTween();
			MusicBeatState.switchState(new GitarooPause());
		}
		else {*/
		if(FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			vocals.pause();
		}
	if (mp3Nativo != null) {
        mp3Nativo.pause();
    }

		if (bgVideo != null)
		{
			bgVideo.canResume = false;
			bgVideo.pause();
		}
	
		if(!cpuControlled)
		{
			for (note in playerStrums)
				if(note.animation.curAnim != null && note.animation.curAnim.name != 'static')
				{
					note.playAnim('static');
					note.resetAnim = 0;
				}
		}
		openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		//}

		#if desktop
		DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function openChartEditor()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		DiscordClient.resetClientID();
		#end
		
		MusicBeatState.switchState(new ChartingState());
	}

	function openCharacterEditor()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		#if desktop DiscordClient.resetClientID(); #end
		MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnScripts('onGameOver', null, true);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;
				//Malius.apagarComputadora(); //chao PC

				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				#if LUA_ALLOWED
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}
				#end
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollow.x, camFollow.y));

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				return;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEvent(eventNotes[0].event, value1, value2, leStrumTime);
			eventNotes.shift();
		}
	}

	public function triggerEvent(eventName:String, value1:String, value2:String, strumTime:Float) {
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		if(Math.isNaN(flValue1)) flValue1 = null;
		if(Math.isNaN(flValue2)) flValue2 = null;

		switch(eventName) {
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				if(flValue2 == null || flValue2 <= 0) flValue2 = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = flValue2;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = flValue2;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = flValue2;
				}

			case 'Set GF Speed':
				if(flValue1 == null || flValue1 < 1) flValue1 = 1;
				gfSpeed = Math.round(flValue1);

			case 'Add Camera Zoom':
				if(ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.35) {
					if(flValue1 == null) flValue1 = 0.015;
					if(flValue2 == null) flValue2 = 0.03;

					FlxG.camera.zoom += flValue1;
                    camHUD.zoom += flValue2;

				}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						if(flValue2 == null) flValue2 = 0;
						switch(Math.round(flValue2)) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				if(camFollow != null)
				{
					isCameraOnForcedPos = false;
					if(flValue1 != null || flValue2 != null)
					{
						isCameraOnForcedPos = true;
						if(flValue1 == null) flValue1 = 0;
						if(flValue2 == null) flValue2 = 0;
						camFollow.x = flValue1;
						camFollow.y = flValue2;
					}
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}


			case 'Change Character':
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnScripts('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf-') || dad.curCharacter == 'gf';
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf-') && dad.curCharacter != 'gf') {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnScripts('dadName', dad.curCharacter);

					case 2:
						if(gf != null)
						{
							if(gf.curCharacter != value2)
							{
								if(!gfMap.exists(value2)) {
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
							setOnScripts('gfName', gf.curCharacter);
						}
				}
				reloadHealthBarColors();

			case 'Change Scroll Speed':
				if (songSpeedType != "constant")
				{
					if(flValue1 == null) flValue1 = 1;
					if(flValue2 == null) flValue2 = 0;

					var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed') * flValue1;
					if(flValue2 <= 0)
						songSpeed = newValue;
					else
						songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, flValue2 / playbackRate, {ease: FlxEase.linear, onComplete:
							function (twn:FlxTween)
							{
								songSpeedTween = null;
							}
						});
				}

			case 'Set Property':
				try
				{
					var split:Array<String> = value1.split('.');
					if(split.length > 1) {
						LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1], value2);
					} else {
						LuaUtils.setVarInArray(this, value1, value2);
					}
				}
				catch(e:Dynamic)
				{
					addTextToDebug('ERROR ("Set Property" Event) - ' + e.message.substr(0, e.message.indexOf('\n')), FlxColor.RED);
				}
			
			case 'Play Sound':
				if(flValue2 == null) flValue2 = 1;
				FlxG.sound.play(Paths.sound(value1), flValue2);

			case 'LightCam':
			 var LightCams:FlxSprite = new FlxSprite(0, 0).makeGraphic(1280, 720);
				if(value1 != '' && value1 != null) {
                    //WAZAAA
			    } else {
				    LightCams.color = FlxColor.BLACK;
					add(LightCams);
					LightCams.scrollFactor.set();
					LightCams.cameras = [camCounter];
				}
				if (value1 == 'WHITE') {
					LightCams.color = 0x521309;
					add(LightCams);
					LightCams.scrollFactor.set();
					LightCams.cameras = [camCounter];
				}

				if(value2 != '' && value2 != null) {
					var LightCamTween:FlxTween = FlxTween.tween(LightCams, {alpha: 0}, Std.parseFloat(value1), {
						ease: FlxEase.linear
					});	
				} else {
					var LightCamTween:FlxTween = FlxTween.tween(LightCams, {alpha: 0}, 0.7, {
						ease: FlxEase.linear
					});	
				}	


			case 'Cam Boom Speed':
			    boomSpeed = flValue1;
				bamZoom = flValue2;

			case 'Set Cam Zoom':
				if(value2 != '' && value2 != null) {
					if(zoomHUDTween != null)
						zoomHUDTween.cancel();

					zoomHUDTween = FlxTween.tween(camGame, {zoom: Std.parseFloat(value1)}, Std.parseFloat(value2), {
						ease: FlxEase.sineInOut,
						onComplete: function(twn:FlxTween) {
							zoomHUDTween = null;
							defaultCamZoom = camGame.zoom;
						}
					});
				} else {
					defaultCamZoom = Std.parseFloat(value1);
				}

			case 'Bad Apple Liar':
                switch(value1.toLowerCase().trim()) 
				{
					case 'a':
					    CppAPI.invertScreenColors();
						boyfriend.setColorTransform(0, 0, 0, 1, 82, 19, 9, 0);
						//gf.color = FlxColor.BLACK;
					case 'b':
					    CppAPI.restoreScreenColors();
						boyfriend.setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);	
						boyfriend.color = FlxColor.fromRGB(60, 60, 60);	
				}

			case 'Bad Apple':
                switch(value1.toLowerCase().trim()) 
				{
					case 'a':
					    blackRar.visible = true;
						boyfriend.setColorTransform(0, 0, 0, 1, 255, 255, 255, 0);
						gf.setColorTransform(0, 0, 0, 1, 255, 255, 255, 0);
						dad.setColorTransform(0, 0, 0, 1, 255, 255, 255, 0);
					case 'b':
					    blackRar.visible = false;
						boyfriend.setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);	
						gf.setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
						dad.setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
				}

			case 'Bopping HUD':			
					camGame.flash(FlxColor.WHITE, 1, null, true);
					camHUD.flash(FlxColor.WHITE, 1, null, true);
					var bop:Float = Std.parseFloat(value1);
					if(!Math.isNaN(bop))
						boppingHUD = bop;
					else
						boppingHUD = 0;	

            case "Change BPM": // no me sirves 
				var newBpm:Float = Std.parseFloat(value1);
				if (!Math.isNaN(newBpm))
				{
					Conductor.bpm = newBpm;
					trace("BPM cambiado a: " + newBpm);
				}

				Conductor.songPosition = FlxG.sound.music.time - ClientPrefs.data.noteOffset;

			case "Change Scroll Speed Step":

				var newBPM:Float = Std.parseFloat(value1);

				if (baseScrollBPM <= 0)
					baseScrollBPM = newBPM;

				var multiplier:Float = newBPM / baseScrollBPM;
                var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * multiplier;

				var maxSpeed:Float = 7.5; // evitar que el charting se rompa XD
				if (newValue > maxSpeed) 
				{
					newValue = maxSpeed;
				}

				songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, 0.04 / playbackRate, {ease: FlxEase.linear, onComplete:
					function (twn:FlxTween)
					{
						songSpeedTween = null;
					}
				});

				trace("Nuevo BPM: " + newBPM);
				trace("Multiplicador: " + multiplier);
				trace("SongSpeed: " + songSpeed);


            case "Stop Scroll":
				var duration:Float = Std.parseFloat(value1);
				startStop(duration);

			case "BG Change":

			    trace("Event 'BG Change' Archivo: " + value1);

				var videoPath = smFolder+"/"+ value1;
				
				if (sys.FileSystem.exists(videoPath)) {
				} else {
					trace("ERROR Archivo " + videoPath);
					trace(smFolder);
				}

				var assetName:String = value1;
				var ext:String = assetName.substring(assetName.lastIndexOf(".") + 1).toLowerCase();

				if (ext == "mp4" || ext == "avi" || ext == "mov")
				{
					playBackgroundVideo(assetName);
				}
				else 
				{
					trace("imagen");
					changeBackgroundImage(assetName);
				}
				//changeBackground(value1);

		    case 'windowGif':
			    gifWindow(value1);						
		}
		
		stagesFunc(function(stage:BaseStage) stage.eventCalled(eventName, value1, value2, flValue1, flValue2, strumTime));
		callOnScripts('onEvent', [eventName, value1, value2, strumTime]);
	}

	private var stopDurationLeft:Float = 0; 

	private function startStop(duration:Float) 
	{
		if (stopActive) return; 

		stopActive = true;

		stopDurationLeft = duration * 1000;
		
		songPositionAtStop = Conductor.songPosition;

		var currentAudioTime:Float = 0;
		var hasAudio:Bool = false;
		#if VIDEOS_ALLOWED
		if (mp3Nativo != null && mp3Nativo.bitmap != null) {
			currentAudioTime = mp3Nativo.bitmap.time;
			hasAudio = true;
		}
		#end
		if (!hasAudio && FlxG.sound.music != null) {
			currentAudioTime = FlxG.sound.music.time;
			hasAudio = true;
		}
		if (hasAudio) songLastAudioTime = currentAudioTime;

		stopOffset += (duration * 1000);
	}


	function moveCameraSection(?sec:Null<Int>):Void {
		if(sec == null) sec = curSection;
		if(sec < 0) sec = 0;

		if(SONG.notes[sec] == null) return;

		if (gf != null && SONG.notes[sec].gfSection)
		{
			camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
			callOnScripts('onMoveCamera', ['gf']);
			return;
		}

		var isDad:Bool = (SONG.notes[sec].mustHitSection != true);
		moveCamera(isDad);
		callOnScripts('onMoveCamera', [isDad ? 'dad' : 'boyfriend']);
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if(isDad)
		{
			camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			tweenCamIn();
		}
		else
		{
			camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}

	public function tweenCamIn() {
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if (isSM)
		{
			if (mp3Nativo != null)
			{
				mp3Nativo.bitmap.stop();
				mp3Nativo.destroy();
				mp3Nativo = null;
			}
		}

		if(ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset) {
			endCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
				endCallback();
			});
		}
	}
 
    var seenResults:Bool = false;
	var resultsNoStop:Bool = false;

	public var transitioning = false;
	public function endSong()
	{
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if(doDeathCheck()) {
				return false;
			}
		}

		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if(achievementObj != null)
			return false;
		else
		{
			var noMissWeek:String = WeekData.getWeekFileName() + '_nomiss';
			var achieve:String = checkForAchievement([noMissWeek, 'r_ubad', 'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);
			if(achieve != null) {
				startAchievement(achieve);
				return false;
			}
		}
		#end
         
		if (!seenResults)
		{
			seenResults = true;

			var sicks:Int = this.sicks;
			var goods:Int = this.goods;
			var bads:Int = this.bads;
			var shits:Int = Reflect.hasField(this, "shits") ? Reflect.field(this, "shits") : 0;
			var misses:Int = this.songMisses;
			var maxCombo:Int = this.songMaxCombo; 
			var score:Int = this.songScore;
			
			// Cálculo general de precisión estándar de Psych Engine (o puedes usar ratingsPercent si existe)
			var totalNotesHit:Float = sicks + goods + bads + shits;
			var totalNotesTotal:Float = totalNotesHit + misses;
			var accuracy:Float = (totalNotesTotal > 0) ? (totalNotesHit / totalNotesTotal) * 100 : 0;
			
			var ratingFc:String = (misses == 0) ? (bads == 0 && shits == 0 ? "MFC" : "SFC") : (misses < 10 ? "FC" : "Clear");

			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
			}
			persistentUpdate = false;
			persistentDraw = true;

			openSubState(new SMResultsSubState(sicks, goods, bads, shits, misses, maxCombo, score, accuracy, ratingFc, function() {
				// Callback al presionar Enter en los resultados: procedemos a salir al menú normal
				endSong();
				//resultsNoStop = false;
			}));

			return false; // Detenemos temporalmente el flujo original de endSong
		}


		var ret:Dynamic = callOnScripts('onEndSong', null, true);
		if(ret != FunkinLua.Function_Stop && !transitioning)
		{
			#if !switch
			if(!isSM)
			{
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
			} else {
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				var songFormat:String = Paths.formatToSongPath(PlayState.SONG.song);
				if (Reflect.field(PlayState, "isSM") == true)
				{
					var diffsArray:Array<String> = Reflect.field(PlayState, "smDifficulties"); 
					var currentDiffName:String = FreeplayState.songs[FreeplayState.curSelected].smDifficulties[PlayState.storyDifficulty];
					songFormat = songFormat + "-" + currentDiffName.toLowerCase();
				}

				Highscore.saveScore(songFormat, songScore, 0, percent);
			}

			#end
			playbackRate = 1;

			if (chartingMode)
			{
				openChartEditor();
				return false;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					Mods.loadTopMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					#if desktop DiscordClient.resetClientID(); #end

					cancelMusicFadeTween();
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new StoryMenuState());

					// if ()
					if(!ClientPrefs.getGameplaySetting('practice') && !ClientPrefs.getGameplaySetting('botplay')) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
						Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = Difficulty.getFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					prevCamFollow = camFollow;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					cancelMusicFadeTween();
					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				Mods.loadTopMod();
				#if desktop DiscordClient.resetClientID(); #end

				cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				if(!isSM) 
				    MusicBeatState.switchState(new FreeplayStateFNF());
				else
				    MusicBeatState.switchState(new FreeplayState());

				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
			}
			transitioning = true;
		}
		return true;
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementPopup = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementPopup(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	// stores the last judgement object
	var lastRating:FlxSprite;
	// stores the last combo sprite object
	var lastCombo:FlxSprite;
	// stores the last combo score objects in an array
	var lastScore:Array<FlxSprite> = [];

	private function cachePopUpScore()
	{
		var uiPrefix:String = '';
		var uiSuffix:String = '';
		if (stageUI != "normal")
		{
			uiPrefix = '${stageUI}UI/';
			if (PlayState.isPixelStage) uiSuffix = '-pixel';
		}

		for (rating in ratingsData)
			Paths.image(uiPrefix + rating.image + uiSuffix);
		for (i in 0...10)
			Paths.image(uiPrefix + 'num' + i + uiSuffix);
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		vocals.volume = 1;

		var placement:Float =  FlxG.width * 0.35;
		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.hits++;
		note.rating = daRating.name;
		score = daRating.score;

		if(daRating.noteSplash && !note.noteSplashData.disabled)
			spawnNoteSplashOnNote(note);

		if(!practiceMode && !cpuControlled) {
			songScore += score;
			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
			}
		}

		var uiPrefix:String = "";
		var uiSuffix:String = '';
		var antialias:Bool = ClientPrefs.data.antialiasing;

		if (stageUI != "normal")
		{
			uiPrefix = '${stageUI}UI/';
			if (PlayState.isPixelStage) uiSuffix = '-pixel';
			antialias = !isPixelStage;
		}

		rating.loadGraphic(Paths.image(uiPrefix + daRating.image + uiSuffix));
		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = placement - 40;
		rating.y -= 60;
		rating.visible = (!ClientPrefs.data.hideHud && showRating);
		rating.x += ClientPrefs.data.comboOffset[0];
		rating.y -= ClientPrefs.data.comboOffset[1];
		rating.antialiasing = antialias;

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'combo' + uiSuffix));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = placement;
		comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
		comboSpr.x += ClientPrefs.data.comboOffset[0];
		comboSpr.y -= ClientPrefs.data.comboOffset[1];
		comboSpr.antialiasing = antialias;
		comboSpr.y += 60;

		insert(members.indexOf(strumLineNotes), rating);
		
		if (!ClientPrefs.data.comboStacking)
		{
			if (lastRating != null) lastRating.kill();
			lastRating = rating;
		}

		var baseRatingScale:Float = (!PlayState.isPixelStage) ? 0.7 : (daPixelZoom * 0.85);
		var baseComboScale:Float = (!PlayState.isPixelStage) ? 0.7 : (daPixelZoom * 0.85);

		rating.setGraphicSize(Std.int(rating.width * baseRatingScale));
		comboSpr.setGraphicSize(Std.int(comboSpr.width * baseComboScale));

		comboSpr.updateHitbox();
		rating.updateHitbox();

		rating.scale.set(baseRatingScale * 1.3, baseRatingScale * 1.3);
		FlxTween.tween(rating.scale, {x: baseRatingScale, y: baseRatingScale}, 0.15, {ease: FlxEase.backOut});

		comboSpr.scale.set(baseComboScale * 1.3, baseComboScale * 1.3);
		FlxTween.tween(comboSpr.scale, {x: baseComboScale, y: baseComboScale}, 0.15, {ease: FlxEase.backOut});

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo)
		{
			insert(members.indexOf(strumLineNotes), comboSpr);
		}
		if (!ClientPrefs.data.comboStacking)
		{
			if (lastCombo != null) lastCombo.kill();
			lastCombo = comboSpr;
		}
		if (lastScore != null)
		{
			while (lastScore.length > 0)
			{
				lastScore[0].kill();
				lastScore.remove(lastScore[0]);
			}
		}

		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'num' + Std.int(i) + uiSuffix));
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = placement + (43 * daLoop) - 90 + ClientPrefs.data.comboOffset[2];
			numScore.y += 80 - ClientPrefs.data.comboOffset[3];
			
			if (!ClientPrefs.data.comboStacking)
				lastScore.push(numScore);

			var baseNumScale:Float = (!PlayState.isPixelStage) ? 0.5 : daPixelZoom;
			numScore.setGraphicSize(Std.int(numScore.width * baseNumScale));
			numScore.updateHitbox();

			numScore.visible = !ClientPrefs.data.hideHud;
			numScore.antialiasing = antialias;

			if(showComboNum)
				insert(members.indexOf(strumLineNotes), numScore);

			numScore.scale.set(baseNumScale * 1.4, baseNumScale * 1.4);
			FlxTween.tween(numScore.scale, {x: baseNumScale, y: baseNumScale}, 0.15, {ease: FlxEase.backOut});

			FlxTween.tween(numScore, {alpha: 0}, 0.3 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.003 / playbackRate
			});

			daLoop++;
			if(numScore.x > xThing) xThing = numScore.x;
		}
		comboSpr.x = xThing + 50;

		FlxTween.tween(rating, {alpha: 0}, 0.3 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.003 / playbackRate
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.3 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				comboSpr.destroy();
			},
			startDelay: Conductor.crochet * 0.003 / playbackRate
		});
	}

	public var strumsBlocked:Array<Bool> = [];
	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);
		if (!controls.controllerMode && FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) keyPressed(key);
	}

	private function keyPressed(key:Int)
	{
		if (!cpuControlled && startedCountdown && !paused && key > -1)
		{
			if(notes.length > 0 && !boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				if (!isSM) if(Conductor.songPosition >= 0) Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.data.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				var notesStopped:Bool = false;
				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (strumsBlocked[daNote.noteData] != true && daNote.canBeHit && daNote.mustPress &&
						!daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && !daNote.blockHit)
					{
						if(daNote.noteData == key) sortedNotesList.push(daNote);
						canMiss = true;
					}
				});
				sortedNotesList.sort(sortHitNotes);

				if (sortedNotesList.length > 0) {
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) {
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							} else
								notesStopped = true;
						}

						// eee jack detection before was not super good
						if (!notesStopped) {
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}

					}
				}
				else {
					callOnScripts('onGhostTap', [key]);
					if (canMiss && !boyfriend.stunned) noteMissPress(key);
				}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				if(!keysPressed.contains(key)) keysPressed.push(key);

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if(strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnScripts('onKeyPress', [key]);
		}
	}

	public static function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);
		//trace('Pressed: ' + eventKey);

		if(!controls.controllerMode && key > -1) keyReleased(key);
	}

	private function keyReleased(key:Int)
	{
		if(!cpuControlled && startedCountdown && !paused)
		{
			var spr:StrumNote = playerStrums.members[key];
			if(spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			callOnScripts('onKeyRelease', [key]);
		}
	}

	public static function getKeyFromEvent(arr:Array<String>, key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...arr.length)
			{
				var note:Array<FlxKey> = Controls.instance.keyboardBinds[arr[i]];
				for (noteKey in note)
					if(key == noteKey)
						return i;
			}
		}
		return -1;
	}

	// Hold notes
	private function keysCheck():Void
	{
		// HOLDING
		var holdArray:Array<Bool> = [];
		var pressArray:Array<Bool> = [];
		var releaseArray:Array<Bool> = [];
		for (key in keysArray)
		{
			holdArray.push(controls.pressed(key));
			pressArray.push(controls.justPressed(key));
			releaseArray.push(controls.justReleased(key));
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(controls.controllerMode && pressArray.contains(true))
			for (i in 0...pressArray.length)
				if(pressArray[i] && strumsBlocked[i] != true)
					keyPressed(i);

		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			if(notes.length > 0)
			{
				notes.forEachAlive(function(daNote:Note)
				{
					// hold note functions
					if (strumsBlocked[daNote.noteData] != true && daNote.isSustainNote && holdArray[daNote.noteData] && daNote.canBeHit
					&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
						goodNoteHit(daNote);
					}
				});
			}

			if (holdArray.contains(true) && !endingSong) {
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			}
			else if (boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.dance();
				if (enableGifAnim) gifCharacterNoteBf('Idle',gifXIB,gifYIB);
				//boyfriend.animation.curAnim.finish();
			}
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if((controls.controllerMode || strumsBlocked.contains(true)) && releaseArray.contains(true))
			for (i in 0...releaseArray.length)
				if(releaseArray[i] || strumsBlocked[i] == true)
					keyReleased(i);
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
		
		noteMissCommon(daNote.noteData, daNote);
		var result:Dynamic = callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		if(result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll) callOnHScript('noteMiss', [daNote]);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.data.ghostTapping) return; //fuck it

		noteMissCommon(direction);
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		callOnScripts('noteMissPress', [direction]);
	}

	function noteMissCommon(direction:Int, note:Note = null)
	{
		// score and data
		var subtract:Float = 0.05;
		if(note != null) subtract = note.missHealth;
		health -= subtract * healthLoss;

		if(instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}

		combo = 0;

		if(!practiceMode) songScore -= 10;
		if(!endingSong) songMisses++;
		totalPlayed++;
		RecalculateRating(true);

		// play character anims
		var char:Character = boyfriend;
		if((note != null && note.gfNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection)) char = gf;
		
		if(char != null && char.hasMissAnimations)
		{
			var suffix:String = '';
			if(note != null) suffix = note.animSuffix;

			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, direction)))] + 'miss' + suffix;
			char.playAnim(animToPlay, true);
			
			if(char != gf && combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
				gf.specialAnim = true;
			}
		}
		vocals.volume = 0;
	}

	function opponentNoteHit(note:Note):Void
	{
		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;

		if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		} else if(!note.noAnimation) {
			var altAnim:String = note.animSuffix;

			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection) {
					altAnim = '-alt';
				}
			}

			var char:Character = dad;
			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, note.noteData)))] + altAnim;
			if(note.gfNote) {
				char = gf;
				if(enableGifAnim)
				{
					if (!gf.stunned)
						{
							switch(Std.int(Math.abs(note.noteData)))
							{
								case 0: //LEFT
									gifCharacterNoteGf('Left',gifXLG,gifYLG);
								case 1: //DOWN
									gifCharacterNoteGf('Down',gifXDG,gifYDG);
								case 2: //UP
									gifCharacterNoteGf('Up',gifXUG,gifYUG);
								case 3:	//RIGHT						
									gifCharacterNoteGf('Right',gifXRG,gifYRG);
							}                   
						}
				} 
	
			} else {
				if(enableGifAnim)
				{
					if (!dad.stunned)
						{
							switch(Std.int(Math.abs(note.noteData)))
							{
								case 0: //LEFT
									gifCharacterNoteDad('Left',gifXL,gifYL);
								case 1: //DOWN
									gifCharacterNoteDad('Down',gifXD,gifYD);
								case 2: //UP
									gifCharacterNoteDad('Up',gifXU,gifYU);
								case 3:	//RIGHT						
									gifCharacterNoteDad('Right',gifXR,gifYR);
							}                   
						}
				} 
			}

			if(char != null)
			{
				char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}

        if(note.noteType == 'Shoot') {
			var shootAnim:String = note.animSuffix;

			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection) {
					shootAnim = '-shoot';
				}
			}

			var char:Character = dad;
			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, note.noteData)))] + shootAnim;
			if(note.gfNote) {
				char = gf;
			}

			if(char != null)
			{
				char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}		
		}		

		if (SONG.needsVoices)
			vocals.volume = 1;

		strumPlayAnim(true, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
		note.hitByOpponent = true;
	

		var result:Dynamic = callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		if(result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll) callOnHScript('opponentNoteHit', [note]);

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}

		/*var directions:Array<String> = ['Left', 'Down', 'Up', 'Right']; //FUNCIONA PERO DA MUCHO LAG (NO LO RECOMIENDO)
			imagePoses = directions[note.noteData];
                
			if (image != null) {
				image.loadGif('assets/images/' + imagePoses + '.gif');
			}*/		

		/*createWindowOnce();

		var directions:Array<String> = ['Left', 'Down', 'Up', 'Right'];
		posess = directions[note.noteData];

		if(frames != null) {
			setPose(posess);
		}*/
		
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if(cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			note.wasGoodHit = true;
			if (ClientPrefs.data.hitsoundVolume > 0 && !note.hitsoundDisabled)
				FlxG.sound.play(Paths.sound(note.hitsound), ClientPrefs.data.hitsoundVolume);

			if(note.hitCausesMiss) {
				noteMiss(note);
				if(!note.noteSplashData.disabled && !note.isSustainNote)
					spawnNoteSplashOnNote(note);

				if(!note.noMissAnimation)
				{
					switch(note.noteType) {
						case 'Hurt Note': //Hurt note
							if(boyfriend.animation.getByName('hurt') != null) {
								boyfriend.playAnim('hurt', true);
								boyfriend.specialAnim = true;
							}
					}
				}

				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo++;
				if(combo > 9999) combo = 9999;
				popUpScore(note);
				health += note.hitHealth * healthGain;
			}

			if(!note.noAnimation) {
				var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, note.noteData)))];

				var char:Character = boyfriend;
				var animCheck:String = 'hey';
				if(note.gfNote)
				{
					char = gf;
					animCheck = 'cheer';
				}
				
				if(char != null)
				{
					char.playAnim(animToPlay + note.animSuffix, true);
					char.holdTimer = 0;
					
					if(note.noteType == 'Hey!') {
						if(char.animOffsets.exists(animCheck)) {
							char.playAnim(animCheck, true);
							char.specialAnim = true;
							char.heyTimer = 0.6;
						}
					}
				}
			}

			if(!cpuControlled)
			{
				var spr = playerStrums.members[note.noteData];
				if(spr != null) spr.playAnim('confirm', true);
			}
			else strumPlayAnim(false, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
			vocals.volume = 1;

			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;

			switch(SONG.song.toLowerCase())
			{
				case 'liar':
				if (winMoveNote)
				{
					if(SONG.notes[Math.floor(curStep / 16)].mustHitSection == true && !note.isSustainNote)
					{
						if (!boyfriend.stunned)
							{
								switch(Std.int(Math.abs(note.noteData)))
								{
									case 0: //LEFT
										winx = changex - 20;
									case 1: //DOWN
										winy = changey + 20;
									case 2: //UP
										winy = changey - 20;
									case 3:	//RIGHT						
										winx = changex + 20;
								}                   
							}
					} 
				}
					
				switch(curStep)
					{
						case 1717:
							switch (dad.curCharacter)
							{
								case 'pico-pre':
									triggerEvent("Add Camera Zoom", '0.3', '0', Conductor.songPosition);
					}	
				}
			}

			if(enableGifAnim)
			{
				if (!boyfriend.stunned)
					{
						switch(Std.int(Math.abs(note.noteData)))
						{
							case 0: //LEFT
								gifCharacterNoteBf('Right',gifXLB,gifYLB);
							case 1: //DOWN
								gifCharacterNoteBf('Down',gifXDB,gifYDB);
							case 2: //UP
								gifCharacterNoteBf('Up',gifXUB,gifYUB);
							case 3:	//RIGHT						
								gifCharacterNoteBf('Left',gifXRB,gifYRB);
						}                   
					}
			} 		
			
			var result:Dynamic = callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
			if(result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll) callOnHScript('goodNoteHit', [note]);

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	public function spawnNoteSplashOnNote(note:Note) {
		if(note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null)
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, note);
		grpNoteSplashes.add(splash);
	}

	override function destroy() {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			var lua:FunkinLua = luaArray[0];
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];
		FunkinLua.customFunctions.clear();
		#end

		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
			if(script != null)
			{
				script.call('onDestroy');
				script.destroy();
			}

		while (hscriptArray.length > 0)
			hscriptArray.pop();
		#end

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		FlxAnimationController.globalSpeed = 1;
		FlxG.sound.music.pitch = 1;
		Note.globalRgbShaders = [];
		if (mp3Nativo != null) mp3Nativo.destroy();
		backend.NoteTypesConfig.clearNoteTypesData();
		instance = null;

		switch (curStage)
		{
			case 'liesStage':
				CppAPI.restoreTaskbar();
				CppAPI.restoreDesktopIcons();
				CppAPI.reset();
				stopRewind();
				CppAPI.restoreTime();
				WindowColorMode.setWindowBorderColor([32, 32, 32], true, true);
				WindowColorMode.setDarkMode();
				Lib.application.window.borderless = false;
				Lib.application.window.resizable = true;
				if (opponentWindow != null)
				{
					opponentWindow.close();
				} 
				if (playerWindow != null)
				{
					playerWindow.close();
				}

				FlxG.autoPause = true;

				tweenWindowSize(1280, 720, 1);

				finishDesktopEffect();
				MaliusDestrok.disableEffect();
				CppAPI.restoreScreenColors();
				CppAPI.restoreWindowIcon();

				CppAPI.setWallpaper('old');
		}

		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		if(!isSM)
		{
		    if(FlxG.sound.music.time >= -ClientPrefs.data.noteOffset)
			{
				if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
					|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
				{
					resyncVocals();
				}
			}
		}


		super.stepHit();

		if(curStep == lastStepHit) {
			return;
		}

		switch(SONG.song.toLowerCase())
		{
			case 'liar':
			    switch(curStep)
				{
					case 1:
						for (strum in opponentStrums) strum.alpha = 0;
						for (strum in playerStrums) strum.alpha = 0;

						for (playerStrum in playerStrums) playerStrum.x = ((FlxG.width/2) - (Note.swagWidth * 2)) + (Note.swagWidth * playerStrums.members.indexOf(playerStrum));
						var targetY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;

						for (strum in opponentStrums) {
							strum.x = ((FlxG.width / 1.3) - (Note.swagWidth * 1.3)) + (Note.swagWidth * opponentStrums.members.indexOf(strum));
							strum.y = ClientPrefs.data.downScroll ? (FlxG.height / 1.46) : 120; 
						}

						for (strum in opponentStrums) strum.scale.x = 0.7; 
						for (strum in opponentStrums) strum.scale.y = 0.7; 	

					case 151:
					 	for (strum in opponentStrums) strum.alpha = 0.4;
						for (strum in playerStrums) strum.alpha = 1;
						dad.alpha = 0.5;
						dad.color = FlxColor.fromRGB(60, 60, 60);

					case 415:
						difi.alpha = 0.53; 

						for (playerStrum in playerStrums) playerStrum.x = ((FlxG.width/1.4) - (Note.swagWidth * 1.4)) + (Note.swagWidth * playerStrums.members.indexOf(playerStrum)); 
						for (strum in opponentStrums) {
							strum.x = ((FlxG.width / 3) - (Note.swagWidth * 3)) + (Note.swagWidth * opponentStrums.members.indexOf(strum));
							strum.y = ClientPrefs.data.downScroll ? (FlxG.height / 1.29) : 50;
						}

						for (strum in opponentStrums) strum.scale.x = 0.71; 
						for (strum in opponentStrums) strum.scale.y = 0.71;   

						for (strum in opponentStrums) strum.alpha = 1; 

						for (spr in [healthBar, iconP1, iconP2, scoreTxt])
                        spr.visible = true; 

						dad.alpha = 1;
							
						if (ClientPrefs.data.windowsModding)
						{
							CppAPI.setOld();
							var relPath:String = FileSystem.absolutePath("assets\\images\\wallpaper\\1.png");
							relPath = relPath.replace("/", "\\");
							CppAPI.setWallpaper(relPath);
							CppAPI.darkMode();
						}

						states.stages.StageLiar.bgLies.alpha = 1;
						states.stages.StageLiar.blackLies.alpha = 0.3; 

					case 417:
						remove(trailunderdad);
						trailunderdad = new FlxTrail(dad, null, 4, 5, 0.2, 0.067);
						trailunderdad.members[0].x += FlxG.random.float(-1, 4);
						trailunderdad.members[0].y += FlxG.random.float(-1, 4);
						insert(members.indexOf(dadGroup), trailunderdad);

					case 543: 

					if(!optimizeMod && ClientPrefs.data.windowsModding)
					{
						remove(states.stages.StageLiar.bgLies);
						remove(states.stages.StageLiar.blackLies);
						triggerEvent("Change Character", "dad", "fishFil", Conductor.songPosition);
						triggerEvent("Change Character", "bf", "picoScale", Conductor.songPosition);
						boyfriendGroup.visible = false;
						difi.alpha = 0;
						
						Lib.application.window.borderless = true;
						Lib.application.window.fullscreen = false;
						Lib.application.window.maximized = false;
 
                        @:privateAccess
						{
	                        camGame._filters = null;
					        camHUD._filters = null;
						}

						trailunderdad.visible = trailunderdad.active = false;

						for (strum in playerStrums) strum.alpha = 0;
						for (strum in opponentStrums) strum.x = ((FlxG.width/2) - (Note.swagWidth * 2)) + (Note.swagWidth * opponentStrums.members.indexOf(strum)); 

						for (spr in [healthBar, iconP1, iconP2, scoreTxt])
                        spr.visible = false; 

						//Lib.application.window.resize(1780, 990);
                        
						if(!optimizeMod)
						{
							tweenWindowSize(Std.int(display.width * 0.999), Std.int(display.height * 0.999), 0.3);
						}
						
						FlxTransWindow.getWindowsTransparent(); 
						CppAPI.hideTaskbar();
					}


					case 605:
						if(!optimizeMod && ClientPrefs.data.windowsModding)
						{
							cpuControlled = true; //ayudita xd
							for (strum in opponentStrums) strum.alpha = 0;
							for (strum in playerStrums) strum.alpha = 1;
							for (strum in playerStrums) strum.x = ((FlxG.width/2) - (Note.swagWidth * 2)) + (Note.swagWidth * playerStrums.members.indexOf(strum)); // ACUTTALY CENTERED BOZOS!!!!
						}

                    case 614 | 678:
					    if(!optimizeMod && ClientPrefs.data.windowsModding) cpuControlled = startAutoplay;

					case 670: 
					   if(!optimizeMod && ClientPrefs.data.windowsModding) cpuControlled = true; //ayudita xd

					case 671:
					if(!optimizeMod && ClientPrefs.data.windowsModding)
					{
						CppAPI.restoreTaskbar();
						FlxTransWindow.getWindowsbackward(); 
						Lib.application.window.borderless = false;
	                     tweenWindowSize(1280, 720, 0.2);

						add(states.stages.StageLiar.bgLies);
						add(states.stages.StageLiar.blackLies);

						for (playerStrum in playerStrums) playerStrum.x = ((FlxG.width/1.4) - (Note.swagWidth * 1.4)) + (Note.swagWidth * playerStrums.members.indexOf(playerStrum)); 
						for (strum in opponentStrums) {
							strum.x = ((FlxG.width / 3) - (Note.swagWidth * 3)) + (Note.swagWidth * opponentStrums.members.indexOf(strum));
							strum.y = ClientPrefs.data.downScroll ? (FlxG.height / 1.29) : 50;
						}
						for (strum in opponentStrums) strum.alpha = 1; 

						@:privateAccess
						{

							var currentFiltersGameStatic = camGame._filters;
							if (currentFiltersGameStatic == null) currentFiltersGameStatic = [];
							currentFiltersGameStatic.push(filtersStatic);

							camGame._filters = currentFiltersGameStatic;


							var currentFiltersGameBlur = camHUD._filters;
							if (currentFiltersGameBlur == null) currentFiltersGameBlur = [];
							currentFiltersGameBlur.push(filtersBlur);

							camHUD._filters = currentFiltersGameBlur;

							//Game
							var currentFiltersGameBlurZoom = camGame._filters;
							if (currentFiltersGameBlurZoom == null) currentFiltersGameBlurZoom = [];
							currentFiltersGameBlurZoom.push(shaderFilterZoomBlur);

							camGame._filters = currentFiltersGameBlurZoom;

							//HUD
							var currentFiltersHUDZoomBlur = camHUD._filters;
							if (currentFiltersHUDZoomBlur == null) currentFiltersHUDZoomBlur = [];
							currentFiltersHUDZoomBlur.push(shaderFilterZoomBlur);

							camHUD._filters = currentFiltersHUDZoomBlur;

							var currentFiltersGamePixel = camGame._filters;
							if (currentFiltersGamePixel == null) currentFiltersGamePixel = [];
							currentFiltersGamePixel.push(pixelFilters);

							camGame._filters = currentFiltersGameStatic;

						}

						trailunderdad.visible = trailunderdad.active = true;

						triggerEvent("Alt Idle Animation", "bf", "-alt", Conductor.songPosition);
						triggerEvent("Change Character", "dad", "fish", Conductor.songPosition);
						triggerEvent("Change Character", "bf", "pico-pre", Conductor.songPosition);

						difi.alpha = 0.53; 
						dadGroup.visible = true;
						boyfriendGroup.visible = true;
					}

						if (ClientPrefs.data.windowsModding) CppAPI.setTemporaryTime(1692, 6, 10, 3, 33, 0);
						mueveteBro = true;
						if (ClientPrefs.data.windowsModding)
						{
							winx = changex - 20;
						    winy = changey + 50;
						}


					case 679 | 697 | 720 | 728 | 791 | 844 | 855 | 913 | 1150 | 1183 | 1204 | 1215 | 1263 | 1280 | 1303:
						if (ClientPrefs.data.windowsModding)
						{
							winx = changex + 20;
							winy = changey - 50;
						}
					    triggerEvent("Add Camera Zoom", "0.050", "0.07", Conductor.songPosition);

					case 687 | 703 | 723 | 744 | 767 | 847 | 908 | 1191 | 1208 | 1231 | 1256 | 1270:
					    if (ClientPrefs.data.windowsModding)
						{
							winx = changex + 100;
						    winy = changey + 100;
						}

						triggerEvent("Add Camera Zoom", "0.050", "0.07", Conductor.songPosition);

					case 692 | 735 | 784 | 838 | 849 | 902 | 924 | 1158 | 1199 | 1224 | 1276:
						if (ClientPrefs.data.windowsModding)
						{
							winx = changex - 20;
							winy = changey + 50;
						}
						triggerEvent("Add Camera Zoom", "0.050", "0.07", Conductor.songPosition);

					case 712 | 766 | 910 | 917 | 1236 | 1278:
						if (ClientPrefs.data.windowsModding)
						{
							winx = changex + 100;
							winy = changey - 100;	
						}
						triggerEvent("Add Camera Zoom", "0.050", "0.07", Conductor.songPosition);

					case 751 | 1169 | 1240 | 1295:
						if (ClientPrefs.data.windowsModding)
						{
							winx = changex + 10;
							winy = changey - 50;
						}
						triggerEvent("Add Camera Zoom", "0.050", "0.07", Conductor.songPosition);	

					case 758 | 776 | 1163 | 1288:
						if (ClientPrefs.data.windowsModding)
						{
							winx = changex - 10;
							winy = changey + 50;
						}
						triggerEvent("Add Camera Zoom", "0.050", "0.07", Conductor.songPosition);

					case 795:
						if (ClientPrefs.data.windowsModding)
						{
							winx = normalWinX;
							winy = normalWinY;
						}
		
					case 797:
						if (ClientPrefs.data.windowsModding)
						{
							for (tween in windowTween)
							{
								tween.cancel();
							}
							windowTween.push(FlxTween.tween(this, {winy: changey}, 0.5, {ease: FlxEase.expoOut}));
							windowTween.push(FlxTween.tween(this, {winx: changex}, 0.5, {ease: FlxEase.expoOut}));
							windowTween.push(FlxTween.tween(this, {winx: changex + 100, winy: changey + 80}, 3.5, {ease: FlxEase.sineInOut, type: PINGPONG}));

						}

                    case 799:
						for (strum in playerStrums) strum.alpha = 0;
						for (strum in opponentStrums) strum.x = ((FlxG.width/2) - (Note.swagWidth * 2)) + (Note.swagWidth * opponentStrums.members.indexOf(strum)); 
						/*var winRisize = Lib.application.window;
						winRisize.resize(800, 798);
						var camm:Array<FlxCamera> = [camHUD];
						for (camera in camm)
						{
							camera.x = -320;
							FlxG.camera.x = -320;

							camera.y = -390;
							FlxG.camera.y = -390;
						}
						Lib.current.scaleX = 2;
						Lib.current.scaleY = 2.2;*/
						boyfriendGroup.visible = false;
						isCameraOnForcedPos = true;
						camFollow.x += -340;

					case 831: 
					    for (tween in windowTween)
						{
							tween.cancel();
						}
						dadGroup.visible = false;
						trailunderdad.visible = trailunderdad.active = false;
						boyfriendGroup.visible = true;
						isCameraOnForcedPos = false;
					    if (ClientPrefs.data.windowsModding) winx = normalWinX; winy = normalWinY;	
						for (strum in opponentStrums) strum.alpha = 0;
					    for (strum in playerStrums) strum.alpha = 1;
						for (strum in playerStrums) strum.x = ((FlxG.width/2) - (Note.swagWidth * 2)) + (Note.swagWidth * playerStrums.members.indexOf(strum)); 

					case 861:
						if (ClientPrefs.data.windowsModding)
						{
							winx = normalWinX;
							winy = normalWinY;
							windowTween.push(FlxTween.tween(this, {winy: changey}, 0.5, {ease: FlxEase.expoOut}));
							windowTween.push(FlxTween.tween(this, {winx: changex}, 0.5, {ease: FlxEase.expoOut}));
							windowTween.push(FlxTween.tween(this, {winx: changex + -100, winy: changey + -80}, 3.5, {ease: FlxEase.sineInOut, type: PINGPONG}));
						}

						
					case 895:
						if (ClientPrefs.data.windowsModding)
						{
							for (tween in windowTween)
							{
								tween.cancel();
							}
							winx = normalWinX;
							winy = normalWinY;	
						}

  
					case 927:
					    if (ClientPrefs.data.windowsModding)
						{
							for (tween in windowTween)
							{
								tween.cancel();
							}

							var relPath:String = FileSystem.absolutePath("assets\\images\\wallpaper\\3.png");
							relPath = relPath.replace("/", "\\");
							CppAPI.setWallpaper(relPath);
							windowTween.push(FlxTween.tween(this, {winx: normalWinX}, 0.2, {ease: FlxEase.cubeInOut}));
							windowTween.push(FlxTween.tween(this, {winy: normalWinY}, 0.2, {ease: FlxEase.cubeInOut}));
						}


						/*var winRisize = Lib.application.window; // just to make this following line shorter
						winRisize.resize(1280, 720);
						var camm:Array<FlxCamera> = [camHUD];
						for (camera in camm)
						{
							camera.x = 0;
							FlxG.camera.x = -0;

							camera.y = 0;
							FlxG.camera.y = -0;

                        }
						Lib.current.scaleX = 1;
			            Lib.current.scaleY = 1;*/
						
						var win = Application.current.window;
						var display = win.display.currentMode;

						dadGroup.visible = true;
						trailunderdad.visible = trailunderdad.active = true;

						for (spr in [healthBar, iconP1, iconP2, scoreTxt])
                        spr.visible = true; 

						for (playerStrum in playerStrums) playerStrum.x = ((FlxG.width/1.4) - (Note.swagWidth * 1.4)) + (Note.swagWidth * playerStrums.members.indexOf(playerStrum)); 
						for (strum in opponentStrums) {
							strum.x = ((FlxG.width / 3) - (Note.swagWidth * 3)) + (Note.swagWidth * opponentStrums.members.indexOf(strum));
							strum.y = ClientPrefs.data.downScroll ? (FlxG.height / 1.29) : 50;
						}
						for (strum in opponentStrums) strum.alpha = 1; 

					case 1151:
						if (ClientPrefs.data.windowsModding)
						{
							for (tween in windowTween)
							{
								tween.cancel();
							}
						}

						for (spr in [healthBar, iconP1, iconP2, scoreTxt])
                        spr.visible = false;

					case 1175 | 1212 | 1247 | 1310:
					    if (ClientPrefs.data.windowsModding) winx = normalWinX; winy = normalWinY;

					case 1311:
						if (ClientPrefs.data.windowsModding)
						{
							var relPath:String = FileSystem.absolutePath("assets\\images\\wallpaper\\5.png");
							relPath = relPath.replace("/", "\\");
							CppAPI.setWallpaper(relPath);
							mueveteBro = false;
						    CppAPI.setTemporaryTime(1999, 12, 31, 23, 59, 26);
						}

                        blackCam.alpha = 1;
						for (strum in playerStrums) strum.alpha = 0; 
						trailunderdad.visible = trailunderdad.active = false;
						boyfriendGroup.visible = false;

					case 1335:
                        if(!optimizeMod && ClientPrefs.data.windowsModding) tweenWindowSize(Std.int(display.width * 1), Std.int(display.height * 1), 0.9);
						defaultCamZoom = 0.61;
						isCameraOnForcedPos = true;
						camFollow.x = 0;
						camFollow.x += -140;

					case 1343:
						states.stages.StageLiar.bgLies.alpha = 0;
						difi.alpha = 0.7;
						blackCam.alpha = 0; 

					case 1455:
						for (strum in playerStrums) strum.alpha = 1; 

					case 1458:
					    //isCameraOnForcedPos = false;

					case 1471:
						boyfriendGroup.visible = true;
						isCameraOnForcedPos = true;
						camFollow.x += 580;
                    case 1679:
					if (ClientPrefs.data.windowsModding) startRewind();
                    case 1686:
					    if(!optimizeMod && ClientPrefs.data.windowsModding) tweenWindowSize(1280, 720, 3.2);
					    startPixelTransition(4);
					
					case 1695:
					if (ClientPrefs.data.windowsModding) CppAPI.showNotification("LIES", "ONE DAY YOU WILL ALL UNDERSTAND.");

                    case 1710:
					    blackCam.alpha = 1;
						isCameraOnForcedPos = false;
						for (strum in opponentStrums) strum.alpha = 0;
						for (playerStrum in playerStrums) playerStrum.x = ((FlxG.width/2) - (Note.swagWidth * 2)) + (Note.swagWidth * playerStrums.members.indexOf(playerStrum)); 
                        @:privateAccess
						{
	                        camGame._filters = null;
						}

					case 1712:
					if (ClientPrefs.data.windowsModding) setRewindSpeed(0.1, 60);
					if (ClientPrefs.data.windowsModding) CppAPI.invertScreenColors();

					case 1776 | 1777 | 1778 | 1779 | 1780 | 1781:
					    if (ClientPrefs.data.windowsModding) MaliusDestrok.glitcherPositions();

					case 1782:
					    if (ClientPrefs.data.windowsModding) activeDesktopEffect = true;
					
					case 1839:
					    if (ClientPrefs.data.windowsModding) activeDesktopEffect = false;
					case 1840 | 1841 | 1842 | 1843 | 1844 | 1845: 
					 if (ClientPrefs.data.windowsModding) MaliusDestrok.glitcherPositions();

					case 1846:
					 	if (ClientPrefs.data.windowsModding) activeDesktopEffect = true;

						
					case 1716:
						if (ClientPrefs.data.windowsModding)
						{
							var relPath:String = FileSystem.absolutePath("assets\\images\\wallpaper\\4.png");
							relPath = relPath.replace("/", "\\");
							CppAPI.setWallpaper(relPath);
							stopRewind();
							CppAPI.hideTaskbar();
							CppAPI.restoreScreenColors();
							MaliusDestrok.activateEffect();
							CppAPI.removeWindowIcon();
							WindowColorMode.setWindowBorderColor([0, 0, 0], true, true);
							mueveteBro = true;
							winMoveNote = true;
						}

						blackCam.alpha = 0;
					    dadGroup.visible = false;
						vgRed.visible = true;

						@:privateAccess
						{

							var currentFiltersGameStatic = camGame._filters;
							if (currentFiltersGameStatic == null) currentFiltersGameStatic = [];
							currentFiltersGameStatic.push(filtersStatic);

							camGame._filters = currentFiltersGameStatic;
							
							//Game
							var currentFiltersGameBlurZoom = camGame._filters;
							if (currentFiltersGameBlurZoom == null) currentFiltersGameBlurZoom = [];
							currentFiltersGameBlurZoom.push(shaderFilterZoomBlur);

							camGame._filters = currentFiltersGameBlurZoom;
						}

					case 1718:
					if (ClientPrefs.data.windowsModding) CppAPI.setTemporaryTime(2038, 1, 19, 3, 14, 0);
					case 1967:
					if (ClientPrefs.data.windowsModding) activeDesktopEffect = false; 
					case 2095:
					if (ClientPrefs.data.windowsModding) activeDesktopEffect = false; 
					case 2096:
					if (ClientPrefs.data.windowsModding) MaliusDestrok.glitcherPositions();
					case 2097 | 2098 | 2099 | 2100:
					if (ClientPrefs.data.windowsModding) MaliusDestrok.glitcherPositions(); 
					case 1974:
					if (ClientPrefs.data.windowsModding) beatApp = 1;
					if (ClientPrefs.data.windowsModding) activeDesktopEffect = true; 
					case 2101:
					if (ClientPrefs.data.windowsModding) activeDesktopEffect = true; 

					case 2172:
					if (ClientPrefs.data.windowsModding) activeDesktopEffect = false; 

					case 2173 | 2174 | 2175 | 2176 | 2177:
					if (ClientPrefs.data.windowsModding) MaliusDestrok.glitcherPositions();
 
					case 2178:
					if (ClientPrefs.data.windowsModding) activeDesktopEffect = true;

					case 2187:
					if (ClientPrefs.data.windowsModding) activeDesktopEffect = false; 

					case 2188 | 2189 | 2190 | 2191 | 2192 | 2196 | 2197 | 2198 | 2199 | 2200 | 2204 | 2205 | 2206 | 2207 | 2208 | 2209:
					if (ClientPrefs.data.windowsModding) MaliusDestrok.glitcherPositions();

					case 2210:
                    if (ClientPrefs.data.windowsModding) activeDesktopEffect = true;
				}

			case 'dead-hope' | 'dead hope':
			if (curStep == 720)
			{
				visibleGif = 1;
				iconP2.changeIcon("facepixel");
			} 

			case 'fresh':
			    if (curStep == 12)
				{
					activeDesktopEffect = true;
					MaliusDestrok.activateEffect();
					MaliusDestrok.glitcherPositions(); 
				}
			

		}				

		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit');
	}

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
			notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));
			
		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (gf != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
		{
			gf.dance(); 
			if (enableGifAnim) gifCharacterNoteGf('Idle',gifXIG,gifYIG);
		}
			
		if (curBeat % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
		{
			boyfriend.dance();
			if (enableGifAnim) gifCharacterNoteBf('Idle',gifXIB,gifYIB);
		}

		if (curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
		{
			dad.dance(); 
			if (enableGifAnim) gifCharacterNoteDad('Idle',gifXI,gifYI);
		}

        if (curBeat % beatApp == 0)
		{
			if (activeDesktopEffect) {
				MaliusDestrok.glitcherPositions();
			}
		}

			


		if(curBeat % 2 == 0) {
			camGame.angle = boppingHUD * -12;
			if(boppingGameTween != null)
				boppingGameTween.cancel();

			boppingGameTween = FlxTween.tween(camGame, {angle: 0}, 0.5, {
				ease: FlxEase.backOut,
				onComplete: function(twn:FlxTween) {
					boppingGameTween = null;
				}
			});

			if(boppingHUDTween != null)
				boppingHUDTween.cancel();
				
			camHUD.angle = boppingHUD * -12;
			boppingHUDTween = FlxTween.tween(camHUD, {angle: 0}, 0.5, {
				ease: FlxEase.backOut,
				onComplete: function(twn:FlxTween) {
					boppingHUDTween = null;
				}
			});	

		} else {
			camGame.angle = boppingHUD * 12;
			if(boppingGameTween != null)
				boppingGameTween.cancel();

			boppingGameTween = FlxTween.tween(camGame, {angle: 0}, 0.5, {
				ease: FlxEase.backOut,
				onComplete: function(twn:FlxTween) {
					boppingGameTween = null;
				}
			});

			if(boppingHUDTween != null)
				boppingHUDTween.cancel();

			camHUD.angle = boppingHUD * 12;
			boppingHUDTween = FlxTween.tween(camHUD, {angle: 0}, 0.5, {
				ease: FlxEase.backOut,
				onComplete: function(twn:FlxTween) {
					boppingHUDTween = null;
				}
			});						
		}


		if (curBeat % boomSpeed == 0)
		{
			triggerEvent("Add Camera Zoom", Std.string(0.015*bamZoom), Std.string(0.03*bamZoom), Conductor.songPosition);
		}

		super.beatHit();
		lastBeatHit = curBeat;

		setOnScripts('curBeat', curBeat);
		callOnScripts('onBeatHit');
	}

	public static function activarSustoEscritorio() {
    activeDesktopEffect = true;
    MaliusDestrok.activateEffect();
}

	override function sectionHit()
	{
		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
				moveCameraSection();

			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.data.camZooms)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.bpm = SONG.notes[curSection].bpm;
				setOnScripts('curBpm', Conductor.bpm);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
			}
			setOnScripts('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnScripts('altAnim', SONG.notes[curSection].altAnim);
			setOnScripts('gfSection', SONG.notes[curSection].gfSection);
		}
		super.sectionHit();
		
		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit');
	}

	#if LUA_ALLOWED
	public function startLuasNamed(luaFile:String)
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if(!FileSystem.exists(luaToLoad))
			luaToLoad = Paths.getPreloadPath(luaFile);
		
		if(FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getPreloadPath(luaFile);
		if(OpenFlAssets.exists(luaToLoad))
		#end
		{
			for (script in luaArray)
				if(script.scriptName == luaToLoad) return false;
	
			new FunkinLua(luaToLoad);
			return true;
		}
		return false;
	}
	#end
	
	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String)
	{
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getPreloadPath(scriptFile);
		
		if(FileSystem.exists(scriptToLoad))
		{
			if (SScript.global.exists(scriptToLoad)) return false;
	
			initHScript(scriptToLoad);
			return true;
		}
		return false;
	}

	public function initHScript(file:String)
	{
		try
		{
			var newScript:HScript = new HScript(null, file);
			@:privateAccess
			if(newScript.parsingExceptions != null && newScript.parsingExceptions.length > 0)
			{
				@:privateAccess
				for (e in newScript.parsingExceptions)
					if(e != null)
						addTextToDebug('ERROR ON LOADING ($file): ${e.message.substr(0, e.message.indexOf('\n'))}', FlxColor.RED);
				newScript.destroy();
				return;
			}

			hscriptArray.push(newScript);
			if(newScript.exists('onCreate'))
			{
				var callValue = newScript.call('onCreate');
				if(!callValue.succeeded)
				{
					for (e in callValue.exceptions)
						if (e != null)
							addTextToDebug('ERROR ($file: onCreate) - ${e.message.substr(0, e.message.indexOf('\n'))}', FlxColor.RED);

					newScript.destroy();
					hscriptArray.remove(newScript);
					trace('failed to initialize sscript interp!!! ($file)');
				}
				else trace('initialized sscript interp successfully: $file');
			}
			
		}
		catch(e)
		{
			addTextToDebug('ERROR ($file) - ' + e.message.substr(0, e.message.indexOf('\n')), FlxColor.RED);
			var newScript:HScript = cast (SScript.global.get(file), HScript);
			if(newScript != null)
			{
				newScript.destroy();
				hscriptArray.remove(newScript);
			}
		}
	}
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = psychlua.FunkinLua.Function_Continue;
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [psychlua.FunkinLua.Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [FunkinLua.Function_Continue];

		var len:Int = luaArray.length;
		var i:Int = 0;
		while(i < len)
		{
			var script:FunkinLua = luaArray[i];
			if(exclusions.contains(script.scriptName))
			{
				i++;
				continue;
			}

			var myValue:Dynamic = script.call(funcToCall, args);
			if((myValue == FunkinLua.Function_StopLua || myValue == FunkinLua.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
			{
				returnVal = myValue;
				break;
			}
			
			if(myValue != null && !excludeValues.contains(myValue))
				returnVal = myValue;

			if(!script.closed) i++;
			else len--;
		}
		#end
		return returnVal;
	}
	
	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = psychlua.FunkinLua.Function_Continue;

		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();
		excludeValues.push(psychlua.FunkinLua.Function_Continue);

		var len:Int = hscriptArray.length;
		if (len < 1)
			return returnVal;
		for(i in 0...len)
		{
			var script:HScript = hscriptArray[i];
			if(script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
				continue;

			var myValue:Dynamic = null;
			try
			{
				var callValue = script.call(funcToCall, args);
				if(!callValue.succeeded)
				{
					var e = callValue.exceptions[0];
					if(e != null)
						FunkinLua.luaTrace('ERROR (${script.origin}: ${callValue.calledFunction}) - ' + e.message.substr(0, e.message.indexOf('\n')), true, false, FlxColor.RED);
				}
				else
				{
					myValue = callValue.returnValue;
					if((myValue == FunkinLua.Function_StopHScript || myValue == FunkinLua.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
					{
						returnVal = myValue;
						break;
					}
					
					if(myValue != null && !excludeValues.contains(myValue))
						returnVal = myValue;
				}
			}
		}
		#end

		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		if(exclusions == null) exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in hscriptArray) {
			if(exclusions.contains(script.origin))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	function strumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = opponentStrums.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating(badHit:Bool = false) {
		setOnScripts('score', songScore);
		setOnScripts('misses', songMisses);
		setOnScripts('hits', songHits);
		setOnScripts('combo', combo);

		var ret:Dynamic = callOnScripts('onRecalculateRating', null, true);
		if(ret != FunkinLua.Function_Stop)
		{
			ratingName = '?';
			if(totalPlayed != 0) //Prevent divide by 0
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				if(ratingPercent < 1)
					for (i in 0...ratingStuff.length-1)
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
			}
			fullComboFunction();
		}
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost
		setOnScripts('rating', ratingPercent);
		setOnScripts('ratingName', ratingName);
		setOnScripts('ratingFC', ratingFC);
	}

	public var sicks:Int = 0;
    public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;
	public var songMaxCombo:Int = 0;

	function fullComboUpdate()
	{
		sicks = ratingsData[0].hits;
		goods = ratingsData[1].hits;
		bads = ratingsData[2].hits;
		shits = ratingsData[3].hits;

		ratingFC = 'Clear';
		if(songMisses < 1)
		{
			if (bads > 0 || shits > 0) ratingFC = 'FC';
			else if (goods > 0) ratingFC = 'GFC';
			else if (sicks > 0) ratingFC = 'SFC';
		}
		else if (songMisses < 10)
			ratingFC = 'SDCB';
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if(chartingMode) return null;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice') || ClientPrefs.getGameplaySetting('botplay'));
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled && Achievements.getAchievementIndex(achievementName) > -1) {
				var unlock:Bool = false;
				if (achievementName == WeekData.getWeekFileName() + '_nomiss') // any FC achievements, name should be "weekFileName_nomiss", e.g: "week3_nomiss";
				{
					if(isStoryMode && campaignMisses + songMisses < 1 && Difficulty.getString().toUpperCase() == 'HARD'
						&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						unlock = true;
				}
				else
				{
					switch(achievementName)
					{
						case 'ur_bad':
							unlock = (ratingPercent < 0.2 && !practiceMode);

						case 'ur_good':
							unlock = (ratingPercent >= 1 && !usedPractice);

						case 'roadkill_enthusiast':
							unlock = (Achievements.henchmenDeath >= 50);

						case 'oversinging':
							unlock = (boyfriend.holdTimer >= 10 && !usedPractice);

						case 'hype':
							unlock = (!boyfriendIdled && !usedPractice);

						case 'two_keys':
							unlock = (!usedPractice && keysPressed.length <= 2);

						case 'toastie':
							unlock = (/*ClientPrefs.data.framerate <= 60 &&*/ !ClientPrefs.data.shaders && ClientPrefs.data.lowQuality && !ClientPrefs.data.antialiasing);

						case 'debugger':
							unlock = (Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice);
					}
				}

				if(unlock) {
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end

    /*var win:Window;
    var spr:Sprite;

    var frames:Array<Bitmap> = [];
    var cur:Int = 0;	
	var windowCreated:Bool = false;
	var currentPose:String = "";

	function createWindowOnce()
    {
		if (windowCreated) return;

		win = Lib.application.createWindow({
			width: 500,
			height: 500,
			title: "Opponent Window",
			borderless: false,
			alwaysOnTop: true
		});

		spr = new Sprite();
		win.stage.addChild(spr);

		win.onRender.add(function(_)
		{
			updateAnim();
		});

		windowCreated = true;
	}
	
	function setPose(pose:String)
	{
		if (pose == currentPose) return; 

		currentPose = pose;

		frames = [];
		cur = 0;

		frames.push(new Bitmap(openfl.Assets.getBitmapData("assets/images/secu/" + pose + ".png")));
		frames.push(new Bitmap(openfl.Assets.getBitmapData("assets/images/secu/" + pose + "1.png")));

		spr.removeChildren();

		spr.addChild(frames[0]);
	}	

	var frameDelay:Int = 2; 
	var frameCounter:Int = 0;

	function updateAnim()
	{
    if (frames.length == 0) return;

	frameCounter++;

	if (frameCounter < frameDelay) return;

	frameCounter = 0;

    cur++;
    if (cur >= frames.length) cur = 0;

    spr.removeChildren();
    spr.addChild(frames[cur]);
	}*/


	function gifWindow(posee:String)
	{
		var app = Lib.application.createWindow({
				title: "Liarrr",
				width: 500,
				height: 500,
				borderless: false,
				alwaysOnTop: false,
		});
			image = new FlxGifSprite(0, 0).loadGif('assets/images/'+posee+'.gif');	

			var rect = new Rectangle(image.x, image.y, image.width, image.height);

			app.stage.color = 0xFF010101;

			imageCool.scrollRect = rect;
			imageCool.graphics.beginBitmapFill(image.pixels);
			imageCool.graphics.drawRect(0, 0, image.pixels.width, image.pixels.height);
			imageCool.graphics.endFill();

			app.stage.addChild(imageCool);
			Application.current.window.focus();
			FlxG.autoPause = false;

	}

	// SI ESTO FUNCIONA POR GIF (Experimental)

	public function gifCharacterNoteDad(posee:String, gifx:Int = 0, gify:Int = 0)
	{
		if (imageGifDad != null) {
			remove(imageGifDad);
		}

		if (gifCacheDad.exists(posee)) {
			imageGifDad = gifCacheDad.get(posee);
		} else {
			var nuevoGif = new FlxGifSprite(gifx, gify).loadGif('assets/images/deadHope/sponge/' + posee + '.gif');
			gifCacheDad.set(posee, nuevoGif);
			imageGifDad = nuevoGif;
	    }

		imageGifDad.setGraphicSize(Std.int(imageGifDad.width * gifScaleX));
		imageGifDad.alpha = visibleGif;

		insert(members.indexOf(dadGroup), imageGifDad);
	}

	public var imageGifBf:FlxGifSprite; 
	public var visibleGif:Int = 0;
	public function gifCharacterNoteBf(posee:String, gifx:Int = 0, gify:Int = 0)
	{
		if (imageGifBf != null) {
			remove(imageGifBf);
		}

		if (gifCacheBf.exists(posee)) {
			imageGifBf = gifCacheBf.get(posee);
		} else {
			var nuevoGif = new FlxGifSprite(gifx, gify).loadGif('assets/images/deadHope/bf/' + posee + '.gif');
			gifCacheBf.set(posee, nuevoGif);
			imageGifBf = nuevoGif;
		}

		imageGifBf.setGraphicSize(Std.int(imageGifBf.width * 3));
		imageGifBf.alpha = visibleGif;

		insert(members.indexOf(boyfriendGroup), imageGifBf);
	}

	public var imageGifGf:FlxGifSprite; 
	public function gifCharacterNoteGf(posee:String, gifx:Int = 0, gify:Int = 0)
	{
		if (imageGifGf != null) {
			remove(imageGifGf);
		}

		if (gifCacheGf.exists(posee)) {
			imageGifGf = gifCacheGf.get(posee);
		} else {
			var nuevoGif = new FlxGifSprite(gifx, gify).loadGif('assets/images/deadHope/pat/' + posee + '.gif');
			gifCacheGf.set(posee, nuevoGif);
			imageGifGf = nuevoGif;
		}

		imageGifGf.setGraphicSize(Std.int(imageGifGf.width * 2));
		imageGifGf.alpha = visibleGif;

		insert(members.indexOf(gfGroup), imageGifGf);
	}

    public function popupWindowOpponent(customWidth:Int, customHeight:Int, ?customName:String) {
        // PlayState.defaultCamZoom = 0.5;

		if(customName == '' || customName == null){
			customName = 'Mymy';
		}

        opponentWindow = Lib.application.createWindow({
            title: customName,
            width: customWidth,
            height: customHeight,
			borderless: true,
			alwaysOnTop: false

        });
        opponentWindow.stage.color = 0xFF010101;
        @:privateAccess
        opponentWindow.stage.addEventListener("keyDown", FlxG.keys.onKeyDown);
        @:privateAccess
        opponentWindow.stage.addEventListener("keyUp", FlxG.keys.onKeyUp);

        var m = new Matrix();

		// Application.current.window.x = Std.int(display.width / 2) - 640;
        // Application.current.window.y = Std.int(display.height / 2);

        var bg = Paths.image("Lies/Stage1").bitmap;
        var spr = new Sprite();


        spr.graphics.beginBitmapFill(bg, m);
        spr.graphics.drawRect(0, 0, bg.width, bg.height);
        spr.graphics.endFill();
        FlxG.mouse.useSystemCursor = true;

        //Application.current.window.resize(640, 480);


        opponentWin.graphics.beginBitmapFill(dad.pixels, m);
        opponentWin.graphics.drawRect(0, 0, dad.pixels.width, dad.pixels.height);
        opponentWin.graphics.endFill();
        opponentScrollWin.scrollRect = new Rectangle();
	    opponentWindow.stage.addChild(spr);
        opponentWindow.stage.addChild(opponentScrollWin);
        opponentScrollWin.addChild(opponentWin);
        opponentScrollWin.scaleX = 0.7;
        opponentScrollWin.scaleY = 0.7;
        dadGroup.visible = false;
        Application.current.window.focus();
	    FlxG.autoPause = false;
    }	

    public function popupWindowPlayer(customWidth:Int, customHeight:Int, ?customName:String) {
        // PlayState.defaultCamZoom = 0.5;

		if(customName == '' || customName == null){
			customName = 'Maya';
		}

        playerWindow = Lib.application.createWindow({
            title: customName,
            width: customWidth,
            height: customHeight,
			borderless: true,
			alwaysOnTop: false

        });
        playerWindow.stage.color = 0xFF010101;
        @:privateAccess
        playerWindow.stage.addEventListener("keyDown", FlxG.keys.onKeyDown);
        @:privateAccess
        playerWindow.stage.addEventListener("keyUp", FlxG.keys.onKeyUp);

        var m = new Matrix();

		// Application.current.window.x = Std.int(display.width / 2) - 640;
        // Application.current.window.y = Std.int(display.height / 2);

        var bg = Paths.image("Lies/Stage1").bitmap;
        var spr = new Sprite();


        spr.graphics.beginBitmapFill(bg, m);
        spr.graphics.drawRect(0, 0, bg.width, bg.height);
        spr.graphics.endFill();
        FlxG.mouse.useSystemCursor = true;

        //Application.current.window.resize(640, 480);

        playerWin.graphics.beginBitmapFill(boyfriend.pixels, m);
        playerWin.graphics.drawRect(0, 0, boyfriend.pixels.width, boyfriend.pixels.height);
        playerWin.graphics.endFill();
        playerScrollWin.scrollRect = new Rectangle();
		playerWindow.stage.addChild(spr);
        playerWindow.stage.addChild(playerScrollWin);
        playerScrollWin.addChild(playerWin);
        playerScrollWin.scaleX = 0.7;
        playerScrollWin.scaleY = 0.7;
        boyfriendGroup.visible = false;
        // uncomment the line above if you want it to hide the dad ingame and make it visible via the windoe
        Application.current.window.focus();
	    FlxG.autoPause = false;
    }	

	public static function closePopupWindowOpp()
	{
		if (opponentWindow != null) {
			@:privateAccess
			opponentWindow.stage.removeEventListener("keyDown", FlxG.keys.onKeyDown);
			@:privateAccess
			opponentWindow.stage.removeEventListener("keyUp", FlxG.keys.onKeyUp);

			if (opponentWin != null) {
				opponentWin.graphics.clear();
			}
			
			while (opponentWindow.stage.numChildren > 0) {
				opponentWindow.stage.removeChildAt(0);
			}

			opponentWindow.close();
			
			opponentWindow = null;
		}
	}

	public static function closePopupWindowPla()
	{
		if (playerWindow != null) {
			@:privateAccess
			playerWindow.stage.removeEventListener("keyDown", FlxG.keys.onKeyDown);
			@:privateAccess
			playerWindow.stage.removeEventListener("keyUp", FlxG.keys.onKeyUp);

			if (playerWin != null) {
				playerWin.graphics.clear();
			}
			
			while (playerWindow.stage.numChildren > 0) {
				playerWindow.stage.removeChildAt(0);
			}

			playerWindow.close();
			
			playerWindow = null;
		}
	}
	
	function tweenWindowSize(targetWidth:Int, targetHeight:Int, time:Float)
	{
		var win = Application.current.window;
		var display = win.display.currentMode;

		targetWidth = Std.int(Math.min(targetWidth, display.width));
		targetHeight = Std.int(Math.min(targetHeight, display.height));

		var startWidth:Int = win.width;
		var startHeight:Int = win.height;

		FlxTween.num(0.0, 1.0, time, {
			ease: FlxEase.quadOut
		}, function(progress:Float)
		{
			var currentWidth:Int = Std.int(startWidth + (targetWidth - startWidth) * progress);
			var currentHeight:Int = Std.int(startHeight + (targetHeight - startHeight) * progress);

			win.resize(currentWidth, currentHeight);

			var centerX:Int = Std.int((display.width - currentWidth) / 2);
			var centerY:Int = Std.int((display.height - currentHeight) / 2);
			
			win.x = centerX;
			win.y = centerY;
		});
	}

	function startPixelTransition(time:Float = 2)
	{
		if(!optimizeMod)
		{
			progressTrans = 0;

			FlxTween.num(0, 1, time, {
					ease: FlxEase.linear
				}, function(v:Float)
				{
					progressTrans = v;

					pixelShaders.setFloat("progress_trans", progressTrans);
				}
			);
		}

	}

	public static function finishDesktopEffect() {
		activeDesktopEffect = false;
		MaliusDestrok.disableEffect();
	}
	

	public static function onWinClose()
	{
		switch (curStage)
		{
			case 'liesStage':
				trace('OH NOO');
				CppAPI.setWallpaper('old');

				CppAPI.restoreTaskbar();
				CppAPI.restoreDesktopIcons();
				WindowColorMode.setWindowBorderColor([32, 32, 32], true, true);
				WindowColorMode.setDarkMode();
				Lib.application.window.borderless = false;
				
				if (opponentWindow != null)
				{
					opponentWindow.close();
				} 
				if (playerWindow != null)
				{
					playerWindow.close();
				}
				finishDesktopEffect();
				MaliusDestrok.disableEffect();
				CppAPI.restoreWindowIcon();
				stopRewind();
				CppAPI.restoreTime();
		}
	}	

	public static var timerRewind:FlxTimer;
    
    public static var rewindSpeedSeconds:Float = 0.5; 
    public static var minutesPerJump:Int = 5;    

    public static function startRewind():Void { // no funciona para todas las PCs
        stopRewind(); 
        
        timerRewind = new FlxTimer().start(rewindSpeedSeconds, onRewindTick, 0);
    }

    private static function onRewindTick(tmr:FlxTimer):Void {
        CppAPI.subtractMinutes(minutesPerJump);
    }

    public static function setRewindSpeed(newDelaySeconds:Float, newMinutesPerJump:Int):Void {
        rewindSpeedSeconds = newDelaySeconds;
        minutesPerJump = newMinutesPerJump;

        if (timerRewind != null && timerRewind.active) {
            startRewind();
        }
    }

    public static function stopRewind():Void {
        if (timerRewind != null) {
            timerRewind.cancel();
            timerRewind.destroy();
            timerRewind = null;
        }
    }

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if(!ClientPrefs.data.shaders) return new FlxRuntimeShader();

		#if (!flash && MODS_ALLOWED && sys)
		if(!runtimeShaders.exists(name) && !initLuaShader(name))
		{
			FlxG.log.warn('Shader $name is missing!');
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		return new FlxRuntimeShader(arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!ClientPrefs.data.shaders) return false;

		#if (MODS_ALLOWED && !flash && sys)
		if(runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Mods.currentModDirectory + '/shaders/'));

		for(mod in Mods.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));
		
		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if(FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else frag = null;

				if(FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else vert = null;

				if(found)
				{
					runtimeShaders.set(name, [frag, vert]);
					//trace('Found shader $name!');
					return true;
				}
			}
		}
		FlxG.log.warn('Missing shader $name .frag AND .vert files!');
		#else
		FlxG.log.warn('This platform doesn\'t support Runtime Shaders!', false, false, FlxColor.RED);
		#end
		return false;
	}
	#end


	function playBackgroundVideo(fileName:String)
	{
		#if VIDEOS_ALLOWED
		if (bgVideo != null) {
			bgVideo.stop();
			remove(bgVideo);
		}

		var videoPath = smFolder+"/"+ fileName;
		bgVideo = new FlxVideoSprite(0, 0);
		//bgVideo.load(videoPath);
		bgVideo.forceMute = true;
		bgVideo.color = 0xFFBBBBBB;
		bgVideo.play(videoPath, false);
		bgVideo.cameras = [camHUD];
		insert(members.indexOf(bgSprite) + 1, bgVideo); 
		#end
	}

	function changeBackgroundImage(fileName:String)
	{
		if (bgVideo != null)
		{
			bgVideo.stop();
			remove(bgVideo);
			bgVideo = null;
		}

		if (bgSprite != null)
		{
			var imagePath:String = smFolder + "/" + fileName;
			var bitmap = openfl.display.BitmapData.fromFile(imagePath);
			bgSprite.loadGraphic(bitmap);
			bgSprite.setGraphicSize(FlxG.width, FlxG.height);
			bgSprite.updateHitbox();


			bgSprite.cameras = [camHUD];
			bgSprite.screenCenter();
			insert(members.indexOf(blackStage) + 1, bgSprite);
			trace(imagePath);
		}
	}

	function getDefaultBackground(smFolder:String, smHeader:Dynamic):String
	{
		if (smHeader != null && smHeader.BACKGROUND != null && smHeader.BACKGROUND.trim() != "")
		{
			var bgPath = smFolder + "/" + smHeader.BACKGROUND;
			if (sys.FileSystem.exists(bgPath))
				return smHeader.BACKGROUND;
		}

		if (!sys.FileSystem.exists(smFolder))
			return "";

		var imageFiles:Array<String> = [];

		for (file in sys.FileSystem.readDirectory(smFolder))
		{
			var lower = file.toLowerCase();

			if (lower.endsWith(".png")
				|| lower.endsWith(".jpg")
				|| lower.endsWith(".jpeg")
				|| lower.endsWith(".bmp"))
			{
				imageFiles.push(file);
			}
		}

		if (imageFiles.length == 0)
			return "";

		var priorities = [
			"background",
			"-bg",
			" bg",
			"_bg",
			"bg"
		];

		for (priority in priorities)
		{
			for (file in imageFiles)
			{
				if (file.toLowerCase().indexOf(priority) != -1)
					return file;
			}
		}

		for (file in imageFiles)
		{
			var lower = file.toLowerCase();

			if (lower.indexOf("banner") != -1) continue;
			if (lower.indexOf("cdtitle") != -1) continue;
			if (lower.indexOf("jacket") != -1) continue;
			if (lower.indexOf("disc") != -1) continue;
			if (lower.indexOf("preview") != -1) continue;

			return file;
		}

		return imageFiles[0];
	}

}

class StepManiaPlay
{ 
    public static var resyncRestart:Float = 20;
}