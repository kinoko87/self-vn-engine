package engine;

import flixel.input.keyboard.FlxKey;
import flixel.FlxG;
import haxe.Json;
import openfl.Assets;

typedef ControlsJson = Array<{name:String, keys:Array<FlxKey>}>;

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

    public var binds:Map<Control, Array<FlxKey>>; 

    public function new() {
        if (FlxG.save.data.binds == null) {
            FlxG.save.data.binds = getControlsFile();
        }

        binds = FlxG.save.data.binds;
    }

    private function getControlsFile() {
        var f = "assets/data/engine/controls.json";

        if (!Assets.exists(f))
            throw "Could not find controls file \"" + f + "\"";

        var controls:ControlsJson = Json.parse(Assets.getText(f));
    
        return controls;
    }
}