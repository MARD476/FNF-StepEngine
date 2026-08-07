package;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import openfl.display.Loader;
import openfl.net.URLRequest;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.events.Event;
import haxe.Http;
import flixel.group.FlxSpriteGroup;

class CountryGame extends FlxSprite
{
    public static var flagGroup:FlxSpriteGroup;

    public static function createFlagAndName(x:Float, y:Float, inState:flixel.FlxState)
    {
        if (flagGroup != null) {
            flagGroup.destroy();
        }

        flagGroup = new FlxSpriteGroup(x, y);
        inState.add(flagGroup);

        var http = new Http("http://ip-api.com/json/");
        
        http.onData = function(data:String) {
            var json = haxe.Json.parse(data);
            var codigo = Std.string(json.countryCode).toLowerCase();
            var nombrePais = Std.string(json.country);
            
            var textoPais = new FlxText(95, 5, 200, nombrePais, 40);
            textoPais.setFormat(Paths.font("troika.otf"), 40, 0xFFFFFF, LEFT, OUTLINE, 0xFF000000);
            textoPais.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2, 1);
            flagGroup.add(textoPais);

            FlxTween.tween(textoPais.scale, {x: 1.08, y: 1.08}, 0.8, {
                type: PINGPONG,
                ease: FlxEase.sineInOut
            });

            downloadFlag(codigo);
        };

        http.onError = function(error) {
            trace("No se pudo " + error);
        };
        
        http.request();
    }

    public static function downloadFlag(codigo:String)
    {
        var url = "https://flagcdn.com/w80/" + codigo + ".png";
        var loader = new Loader();
        
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e) {
            var bitmap:BitmapData = cast(loader.content, Bitmap).bitmapData;
            
            var sprite = new FlxSprite(0, 0);
            sprite.loadGraphic(FlxGraphic.fromBitmapData(bitmap));
            sprite.setGraphicSize(80);
            sprite.updateHitbox();
            flagGroup.add(sprite);

            FlxTween.tween(sprite.scale, {x: 1.1, y: 1.1}, 0.8, {
                type: PINGPONG,
                ease: FlxEase.sineInOut
            });

            FlxTween.angle(sprite, -6, 6, 1.2, {
                type: PINGPONG,
                ease: FlxEase.sineInOut
            });

            trace("TU PAIS " + codigo);
        });
        
        loader.load(new URLRequest(url));
    }
}