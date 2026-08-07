//Test para probar lo archivos .mp3

package;

import flixel.FlxState;
import flixel.FlxG;
import sys.FileSystem;

#if VIDEOS_ALLOWED
import hxcodec.flixel.FlxVideoSprite;
#end

class PruebaAudioState extends FlxState
{
    #if VIDEOS_ALLOWED
    var mp3Nativo:FlxVideoSprite; // es la unica forma para hacer funcionar los .mp3
    #end

    var rutaAudio:String = "assets/sm/drop-out/DROP_OUT.mp3";

    override public function create():Void
    {
        super.create();

        var rutaAbsoluta:String = Sys.getCwd() + rutaAudio;

        if (FileSystem.exists(rutaAbsoluta))
        {
            #if VIDEOS_ALLOWED
                try {
                    mp3Nativo = new FlxVideoSprite(0, 0);
                    
                    mp3Nativo.bitmap.onEndReached.add(function() {
                        trace("El audio MP3 ha finalizado.");
                    });

                    add(mp3Nativo);

                    mp3Nativo.play(rutaAbsoluta, true);
                    
                    FlxG.sound.music.volume = 0; 

                    trace("SI FUNCIONOOOOOO TE AMOO SANDI");
                } 
                catch(e:Dynamic) {
                    trace("VALE VRG" + e);
                }
            #else
                trace("CR7");
            #end
        }
        else
        {
            trace("Error:" + rutaAbsoluta);
        }
    }

    override public function destroy():Void
    {
        #if VIDEOS_ALLOWED
        if (mp3Nativo != null) {
            mp3Nativo.stop();
            mp3Nativo.destroy();
        }
        #end
        super.destroy();
    }
}