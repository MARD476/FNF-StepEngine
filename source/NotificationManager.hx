
package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

class NotificationManager {
    public static function show(title:String, text:String) {
        var boxWidth = 300;
        var boxHeight = 80;
        
        var box = new FlxSprite(FlxG.width, FlxG.height - boxHeight - 20).makeGraphic(boxWidth, boxHeight, FlxColor.BLACK);
        box.alpha = 0.8;
        box.scrollFactor.set();
        FlxG.state.add(box);

        var txt = new FlxText(FlxG.width + 10, box.y + 10, boxWidth - 20, title + "\n" + text, 16);
        txt.scrollFactor.set();
        FlxG.state.add(txt);

        // Animación suave de entrada y salida
        FlxTween.tween(box, {x: FlxG.width - boxWidth - 20}, 0.5, {ease: FlxEase.quartOut});
        FlxTween.tween(txt, {x: FlxG.width - boxWidth + 10}, 0.5, {ease: FlxEase.quartOut, onComplete: function(twn) {
            FlxTween.tween(box, {x: FlxG.width}, 0.5, {ease: FlxEase.quartIn, startDelay: 3});
            FlxTween.tween(txt, {x: FlxG.width + 10}, 0.5, {ease: FlxEase.quartIn, startDelay: 3, onComplete: function(twn2) {
                box.destroy();
                txt.destroy();
            }});
        }});
    }
}