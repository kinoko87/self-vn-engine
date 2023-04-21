package engine;

import flixel.FlxG;

typedef SaveData = {
    var level:Int;
    var variables:Map<String, Dynamic>;
}

class Save {

    public static var currentSave:Int = 0;

    public static var data:SaveData;

    public inline static function bind(?cSave:Int) {
        currentSave = cSave;
        FlxG.save.bind("m78", "save-"+Std.string(save));
        
        if (FlxG.save.data.saveData == null) {
            var saveData:SaveData = {
                level: 0,
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