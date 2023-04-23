package engine;

import haxe.Timer;
import flixel.FlxG;


#if debug
class Debug {
    public static inline function log(info:String, category:String) {
       var timestamp = Timer.stamp()*1000;
       trace('[timestamp ~ $category] $info');
    }
}
#end