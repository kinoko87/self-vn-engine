package engine;

import flixel.FlxG;
import haxe.Json;
import openfl.Assets;

typedef ControlsJson = Array<{name:String, keys:Array<String>}>;

class Controls {

    public function new() {
        
    }

    public static function getDefaultControls() {
        var f = "assets/data/default_controls.json";

        if (!Assets.exists(f))
            throw "Could not find default controls file \"" + f + "\"";

        var controls:ControlsJson = Json.parse(Assets.getText(f));
        for (c in controls)
            for (b in c.keys) b = b.toUpperCase();
    
        return controls;
    }
}