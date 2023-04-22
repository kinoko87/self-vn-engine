package engine;

import flixel.FlxG;

typedef SaveData = {
    var moment:String;
    var variables:Map<String, Dynamic>;
}

class Save {

    public static var currentSave:String;

    public static var data:SaveData;

    public inline static function bind(?cSave:String) {
        currentSave = cSave;
        FlxG.save.bind("m78", "save-"+Std.string(save));
        
        if (FlxG.save.data.saveData == null) {
            var saveData:SaveData = {
                        //chapter;scene
                moment: "Chapter 0;Start",
                variables: new Map<String, Dynamic>()
            };
            saveData.variables["test"] = true;
            FlxG.save.data.saveData = saveData;
            save();
        }

        data = FlxG.save.data.saveData;
    }

    public inline static function save() {
        FlxG.save.flush();
    }

    public inline static function close() {
        FlxG.save.close();
    }

    public inline static function clear() {
        FlxG.save.erase();
        save();
    }
}