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
        FlxG.save.bind("m78", cSave);

        #if debug
        Debug.log("Bound to save: " + cSave, "save");
        #end
        
        if (FlxG.save.data.saveData == null) {
            #if debug
            Debug.log("Creating new save: " + cSave, "save");
            #end
            var saveData:SaveData = {
                        //chapter;scene
                moment: "Chapter 0;Start",
                variables: new Map<String, Dynamic>()
            };
            FlxG.save.data.saveData = saveData;
            save();
        }

        data = FlxG.save.data.saveData;
    }

    public inline static function save() {
        #if debug
        Debug.log("Writing data to: " + currentSave, "save");
        #end
        FlxG.save.flush();
    }

    public inline static function close() {
        #if debug
        Debug.log("Closing save: " + currentSave, "save");
        #end
        FlxG.save.close();
    }

    public inline static function clear() {
        #if debug
        Debug.log("Clearing save: " + currentSave, "save");
        #end
        FlxG.save.erase();
        save();
    }
}