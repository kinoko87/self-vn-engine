package engine;

import flixel.input.keyboard.FlxKey;
import flixel.FlxG;
import haxe.Json;
import openfl.Assets;

typedef ControlsJson = Array<{control:String, keys:Array<FlxKey>}>;

enum abstract Control(String) from String to String {
    var UP:String = "UP";
    var DOWN:String = "DOWN";
    var LEFT:String = "LEFT";
    var RIGHT:String = "RIGHT";

    var ACCEPT:String = "ACCEPT";
    var SPEED_UP:String = "SPEED_UP";

    var BACK:String = "BACK";
}

class Controls {

    public static var binds:Map<Control, Array<FlxKey>> = []; 

    public static function init() {
        trace("lex", FlxG.save.data.binds==null);
        FlxG.save.data.binds=null;
        if (FlxG.save.data.binds == null) {
            FlxG.save.data.binds = getControlsFile();
            Save.save();
            for (b in 0...FlxG.save.data.binds.length) {
                var controlThing = FlxG.save.data.binds[b];
                binds.set(controlThing.control, [for (i in 0...controlThing.keys.length) FlxKey.fromStringMap.get(controlThing.keys[i])]);
            }
            return;
        }

        trace("binds from SAVE: ", FlxG.save.data.binds);

        if (!binds.exists(UP)) {
            for (b in 0...FlxG.save.data.binds.length) {
                var controlThing = FlxG.save.data.binds[b];
                binds.set(controlThing.control, [for (i in 0...controlThing.keys.length) FlxKey.fromStringMap.get(controlThing.keys[i])]);
                
                trace(binds);
            }

            trace("actual binds Map: ", binds);
        }
    }

    private static function getControlsFile() {
        var f = "assets/engine/data/controls.json";

        if (!Assets.exists(f))
            throw "Could not find controls file \"" + f + "\"";

        var controls:ControlsJson = cast Json.parse(Assets.getText(f));
        trace(controls);

        return controls;
    }
}