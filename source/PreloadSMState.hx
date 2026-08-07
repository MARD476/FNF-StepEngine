package;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import smTools.SMFile;
import sys.FileSystem;
import backend.Song.SwagSong;
import states.FreeplayState.SongMetadata;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

class PreloadSMState extends MusicBeatState {

    var loadingText:FlxText;
    var subText:FlxText;
    var loadStep:Int = 0;
    var foldersList:Array<String> = [];
    var currentFolderIndex:Int = 0;
    var filesInFolder:Array<String> = [];
    var currentFileIndex:Int = 0;
    var finishedLoading:Bool = false;
    var waitTimer:Float = 0;

    override public function create() {
        super.create();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set();
		bg.color = 0xFF222222;
		add(bg);

        loadingText = new FlxText(0, FlxG.height / 2 - 40, FlxG.width, "LOADING SM FILES...", 32);
        loadingText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(loadingText);

        subText = new FlxText(0, FlxG.height / 2 + 10, FlxG.width, "Please wait...", 16);
        subText.setFormat("VCR OSD Mono", 16, FlxColor.GRAY, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(subText);

        var folderTarget = "assets/sm";
        if (FileSystem.exists(folderTarget)) {
            for (folder in FileSystem.readDirectory(folderTarget)) {
                var path = folderTarget + "/" + folder;
                if (FileSystem.isDirectory(path)) {
                    foldersList.push(path);
                }
            }
        }
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (finishedLoading) {
            waitTimer += elapsed;
            if (waitTimer >= 0.8) {
                states.FreeplayState.loadedStepmaniaOnce = true;
                FlxG.switchState(new states.FreeplayState());
            }
            return;
        }

        switch (loadStep)
        {
            case 0:
                SMManager.loadAllSongs();
                loadStep = 1;

            case 1:
                if (currentFolderIndex < foldersList.length) {
                    var path = foldersList[currentFolderIndex];
                    var folderName = path.split("/").pop();
                    subText.text = "Reading folder: " + folderName;
                    
                    if (FileSystem.exists(path)) {
                        for (file in FileSystem.readDirectory(path)) {
                            if (file.endsWith(".sm")) {
                                var info = SMFile.loadFile(path + "/" + file);
                                if (info != null && info.header.TITLE != null) {
                                    var title = info.header.TITLE.toLowerCase().trim();
                                    var musicPath = path + "/" + info.header.MUSIC;
                                    
                                    CacheSongsSM.songPaths.set(title, musicPath);
                                    CacheSongsSM.songSampleStarts.set(title, Std.int(Std.parseFloat(info.header.SAMPLESTART) * 1000));
                                }
                            }
                        }
                    }
                    currentFolderIndex++;
                } else {
                    loadStep = 2; // Cache phase finished
                }

            case 2:
                loadingText.text = "READY!";
                loadingText.color = FlxColor.GREEN;
                subText.text = "Entering main menu...";
                finishedLoading = true;
                waitTimer = 0;
        }
    }
}

class CacheSongsSM {
    public static var songPaths:Map<String, String> = new Map<String, String>();
    public static var songTypes:Map<String, String> = new Map<String, String>(); 
    public static var songSampleStarts:Map<String, Int> = new Map<String, Int>();
}

class SMManager {
    public static var songs:Array<SongMetadata> = [];
    public static var songData:Map<String, Array<SwagSong>> = new Map<String, Array<SwagSong>>();
    public static var smPreviewCache:Map<String, String> = new Map<String, String>();
    public static var isLoaded:Bool = false;

    public static function loadAllSongs() {
        if (isLoaded) return;

        trace("--- LOADING SM FILES ---");

        #if FEATURE_STEPMANIA
        trace("tryin to load sm files");
        if (FileSystem.exists("assets/sm/")) {
            for (i in FileSystem.readDirectory("assets/sm/"))
            {
                trace(i);
                if (FileSystem.isDirectory("assets/sm/" + i))
                {
                    trace("Reading SM file dir " + i);
                    for (file in FileSystem.readDirectory("assets/sm/" + i))
                    {
                        if (file.endsWith(".sm"))
                        {
                            trace("reading " + file);
                            var folderPath:String = "assets/sm/" + i;
                            var pathCompleto:String = folderPath + "/" + file;
                            
                            var contenidoTexto:String = File.getContent(pathCompleto);
                            var seccionesNotes:Array<String> = contenidoTexto.split("#NOTES:");
                            
                            var headerTexto:String = seccionesNotes[0];
                            
                            var smFile:SMFile = SMFile.loadFile(pathCompleto);
                            if (smFile == null || smFile.header == null) continue;
                            
                            var formatoNombre:String = Paths.formatToSongPath(smFile.header.TITLE);
                            trace("Converting " + smFile.header.TITLE + " (" + formatoNombre + ")");
                            
                            var meta = new SongMetadata(smFile.header.TITLE, 0, "sm", 0xFF5A449C, null, folderPath);
                            meta.smPath = pathCompleto;
                            meta.isSMFile = true;
                            meta.smDifficulties = [];
                            
                            var songArray:Array<SwagSong> = [];
                            var mapDifficulties:Map<String, String> = new Map<String, String>();
                            
                            try {
                                if (seccionesNotes.length > 1)
                                {
                                    for (k in 1...seccionesNotes.length)
                                    {
                                        var lineasDificultad:Array<String> = seccionesNotes[k].split(":");
                                        if (lineasDificultad.length >= 4)
                                        {
                                            var typeGame:String = lineasDificultad[0].trim().toLowerCase();
                                            
                                            if (typeGame != "dance-single") {
                                                continue;
                                            }

                                            var rawDiff:String = lineasDificultad[2].trim().toLowerCase();
                                            if (rawDiff == "" || rawDiff == null) rawDiff = "normal";
                                            
                                            var llaveDiff:String = "NORMAL";
                                            if (rawDiff == "beginner") llaveDiff = "BEGINNER";
                                            else if (rawDiff == "easy") llaveDiff = "EASY";
                                            else if (rawDiff == "hard" || rawDiff == "heavy") llaveDiff = "HARD";
                                            else if (rawDiff == "challenge" || rawDiff == "challenger") llaveDiff = "CHALLENGE";
                                            
                                            mapDifficulties.set(llaveDiff, seccionesNotes[k]);
                                        }
                                    }
                                    
                                    var orden:Array<String> = ["BEGINNER", "EASY", "NORMAL", "HARD", "CHALLENGE"];
                                    
                                    for (nameDifficulties in orden)
                                    {
                                        if (mapDifficulties.exists(nameDifficulties))
                                        {
                                            var fijoJson:String = "";
                                            if (nameDifficulties == "BEGINNER") fijoJson = "-beginner";
                                            else if (nameDifficulties == "EASY") fijoJson = "-easy";
                                            else if (nameDifficulties == "HARD") fijoJson = "-hard";
                                            else if (nameDifficulties == "CHALLENGE") fijoJson = "-challenge";
                                            else fijoJson = "";
                                            
                                            var rutaSmTemporal:String = folderPath + "/_temp_convert.sm";
                                            var textoSmTemporal:String = headerTexto + "#NOTES:" + mapDifficulties.get(nameDifficulties);
                                            File.saveContent(rutaSmTemporal, textoSmTemporal);
                                            
                                            var ruteJsonDifficulties:String = folderPath + "/" + formatoNombre + fijoJson + ".json";
                                            var dataJson:String = "";
                                            
                                            try {
                                                var neerlandMymy:SMFile = SMFile.loadFile(rutaSmTemporal);
                                                if(neerlandMymy.isValid) {
                                                    dataJson = neerlandMymy.convertToFNF(ruteJsonDifficulties);
                                                }
                                            } catch(e:Dynamic) {
                                                if (FileSystem.exists(ruteJsonDifficulties)) {
                                                    dataJson = File.getContent(ruteJsonDifficulties);
                                                }
                                            }
                                            
                                            if(FileSystem.exists(rutaSmTemporal)) {
                                                FileSystem.deleteFile(rutaSmTemporal);
                                            }
                                            
                                            if (dataJson != null && dataJson.trim() != "") 
                                            {
                                                var parsedData:Dynamic = haxe.Json.parse(dataJson);
                                                if (parsedData != null && parsedData.song != null) {
                                                    var chartValid:backend.Song.SwagSong = parsedData.song;
                                                    if (chartValid.events == null) chartValid.events = [];
                                                    
                                                    songArray.push(chartValid);
                                                    meta.smDifficulties.push(nameDifficulties);
                                                }
                                            }
                                        }
                                    }
                                }
                            } catch(e:Dynamic) {
                                trace("Error loading notes: " + e);
                            }
                            
                            if (songArray.length == 0 || meta.smDifficulties.length == 0) 
                            {
                                var backupPath:String = folderPath + "/converted.json";
                                try {
                                    var backupData = smFile.convertToFNF(backupPath);
                                    var parsedData:Dynamic = haxe.Json.parse(backupData);
                                    if (parsedData != null && parsedData.song != null) {
                                        var baseSong:backend.Song.SwagSong = parsedData.song;
                                        if (baseSong.events == null) baseSong.events = [];
                                        songArray.push(baseSong);
                                        meta.smDifficulties.push("NORMAL");
                                    }
                                } catch(e:Dynamic) {
                                    trace("Error backup: " + e);
                                }
                            }
                            
                            while (songArray.length < backend.Difficulty.list.length) {
                                if (songArray.length > 0)
                                    songArray.push(Reflect.copy(songArray[0]));
                                else
                                    break;
                            }
                            
                            if (songArray.length > 0) {
                                songData.set(smFile.header.TITLE, songArray);
                                SMManager.songs.push(meta);
                            }
                            break;
                        }
                    }
                }
            }
        }

        for (song in songs)
        {
            if (song.isSMFile || song.songCharacter == "sm")
            {
                var folderPath:String = song.path;
                var finalAudioPath:String = "";

                if (sys.FileSystem.exists(folderPath))
                {
                    for (file in sys.FileSystem.readDirectory(folderPath))
                    {
                        var fileLower = file.toLowerCase();

                        if (fileLower.endsWith(".mp3") || fileLower.endsWith(".ogg"))
                        {
                            finalAudioPath = sys.FileSystem.absolutePath(folderPath + "/" + file);
                            break;
                        }
                    }
                }

                if (finalAudioPath != "")
                {
                    smPreviewCache.set(song.songName, finalAudioPath);
                }
            }
        }
        isLoaded = true;
        #end
    }
}