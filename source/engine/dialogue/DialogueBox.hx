package engine.dialogue;

import hxcodec.VideoSprite;
import hxcodec.VideoHandler;
import openfl.filters.ShaderFilter;
import flixel.input.keyboard.FlxKey;
import engine.dialogue.DialogueParser.Action;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;
import flixel.math.FlxRect;
import engine.dialogue.interfaces.IDialogueBox;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.text.FlxTypeText;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.app.Application;
import openfl.utils.Assets;
import engine.Controls.Control;

// There are some limitations to making choices a seperate element
// But I'm too lazy to implement choices as apart of the Talk element
// so the engine's going to have to have an issue with choices not
// showing up when the next element is an autoprogressable that has
// the waitForAccept attribute set as true

// TODO: Polishing and possible optimizations
class DialogueBox extends FlxSpriteGroup implements IDialogueBox
{
	public var nameBox:FlxSprite;
	public var box:FlxSprite;
	public var nameText:FlxText;
	public var dialogueText:FlxTypeText;

	public var data:Array<Action>;
	public var currentData:Action;

	public var choices:Array<{text:String, id:String, goto:String}> = [];
	public var choiceSprites:Array<ChoiceSprite> = [];

	public var index:Int = 0;
	public var choiceIndex:Int = 0;

	public var scene:Scene;

	public var isActive:Bool = true;

	public var isTalking:Bool = false;

	public var isSelectingChoice:Bool = false;

	public var isDone:Bool = false;
	
	public var ifMap:Map<String, Dynamic> = ["debug" => #if debug true #else false #end, "true"=>true, "null"=>null, "test" => true];

	//							 id      sprite
	public var activeSprites:Map<String, FlxSprite> = [];
	//							id		sound
	public var activeSounds:Map<String, FlxSound> = [];

	public var currentFadeOutDuration:Float = 0;

		/**
	 * Actions that that don't need user input to run. Achieved by checking if
	 * an action is in the autoprogressables array and if so to run the action
	 * and then increment the index until there is a manually progressable action.
	**/
	public var autoprogressables:Array<String> = [];

	public function new(?x:Float = 0, ?y:Float = 0, data:Array<Action>, scene:Scene)
	{
		super(x, y);
		this.data = data;
		this.scene = scene;
		currentData = data[index];

		initializeObjects();
	
		on("Talk", onTalk);
		on("End", _->{isDone=true;});
		on("If", onIf);
		on("GotoFile", onGotoFile);
		on("ChangeBGM", onChangeBGM);
		on("StopBGM", onStopBGM);
		on("PauseBGM", _ -> {FlxG.sound.music?.pause();});
		on("ResumeBGM", _ -> {FlxG.sound.music?.resume();});
		on("ChangeBG", onChangeBG);
		on("AddSprite", onAddSprite);
		on("RemoveSprite", onRemoveSprite);
		on("PlayAnim", onPlayAnim);
		on("StopAnim", onStopAnim);
		on("PauseAnim", _ -> {activeSprites.get(_["spriteID"]).animation.pause();});
		on("ResumeAnim", _ -> {activeSprites.get(_["spriteID"]).animation.resume();});
		on("PlaySound", onPlaySound);
		on("ApplyEffect", onApplyEffect);
		#if desktop
		on("PlayVideo", onPlayVideo);
		#end
		on("Set", _ -> {Save.data.variables[_["variable"]] = _["to"];});
		on("ChangeScene", onChangeScene);
		on("Custom", onCustom);

		autoprogressables = Assets.getText("assets/engine/data/autoprogressables.txt").split('\n');

		currentFadeOutDuration = scene.sceneFile.initialBGM.fadeOutDuration;

		activeSprites["background"] = scene.background;

		performActions();
		while (autoprogressables.contains(currentData.type)) {
			index++;
			currentData = data[index];
			performActions();
		}
	}

	function initializeObjects() {
		box = new FlxSprite(0, 0).makeGraphic(660, Std.int(640 / 4), FlxColor.GRAY);
		nameBox = new FlxSprite(box.x - 20, box.y - 54).makeGraphic(Std.int(box.width/4), 46, FlxColor.GRAY);
		nameText = new FlxText(nameBox.x+10, nameBox.y + 8, 0, "", 30);
		dialogueText = new FlxTypeText(box.x + 20, box.y + 20, Std.int(box.width - 20), "");


		add(box);
		add(nameBox);
		add(nameText);
		add(dialogueText);

	dialogueText.completeCallback = completeCallback;

	}


	/** 
	 * Stores action names and the corresponding callbacks that will run
	 * when the `DialogueBox` reaches an action with a name contained in the map.
	**/
	public var actionCallbacks:Map<String, Map<String, Dynamic>->Void> = [];

	public inline function on(action:String, callback:Map<String, Dynamic>->Void) {
		actionCallbacks.set(action, callback);
	}

	function onTalk(elm:Map<String, Dynamic>)
	{
		isTalking = true;
		nameText.text = elm["name"];
		dialogueText.size = elm["size"];
		dialogueText.resetText(elm["text"]);
		dialogueText.start(elm["speed"]);
		if (elm["skip"])
			dialogueText.skip();
	}

	function onChoices(elm:Map<String, Dynamic>) {

		choices = elm["choices"];

		isSelectingChoice = true;

		if (choiceSprites.length == 0)
			createChoiceSprites(choices);
	}

	function createChoiceSprites(choices:Array<{id:String, text:String, goto:String}>) {
		for (i in 0...choices.length) {
			var c = choices[i];
			var cs = new ChoiceSprite(680, 34 * i, c.text);
			choiceSprites.push(cs);
			add(cs);
		}
	}

	function onChoiceAccept() {
		var curChoice = choices[choiceIndex];

		#if debug
		Debug.log("Selected choice " + '"${curChoice.text}" (id: ${curChoice.id})', "controls");
		#end

		if (curChoice.goto != null) {
			for (i in data) {
				if (i.elm["id"] != null && i.elm["id"] == curChoice.goto) {
					index = data.indexOf(i);
					currentData = data[index];
					if (!autoprogressables.contains(currentData.type))
						performActions();

					while (choiceSprites.length > 0) {
						remove(choiceSprites[0]);
						choiceSprites[0].destroy();
						choiceSprites.remove(choiceSprites[0]);
					}
					isSelectingChoice = false;
					choiceIndex = 0;
					return;
				}
			}
		}

		index++;
		currentData = data[index];
		if (!autoprogressables.contains(currentData.type))
			performActions();

		while (choiceSprites.length > 0) {
			remove(choiceSprites[0]);
			choiceSprites[0].destroy();
			choiceSprites.remove(choiceSprites[0]);
		}

		isSelectingChoice = false;
		choiceIndex = 0;
	}

	function onIf(elm:Map<String, Dynamic>) {

		var isTrue:Bool = false;
	
		if (elm["check"] == "lt" || elm["check"] == "<") {
			isTrue = ifMap[elm["value"]] < Std.parseFloat(elm["is"]);
		} else if (elm["check"] == "lte" || elm["check"] == "<=") {
			isTrue = ifMap[elm["value"]] <= Std.parseFloat(elm["is"]);
		} else if (elm["check"] == "gt" || elm["check"] == ">") {
			isTrue = ifMap[elm["value"]] > Std.parseFloat(elm["is"]);
		} else if (elm["check"] == "gte" || elm["check"] == ">=") {
			isTrue = ifMap[elm["value"]] >= Std.parseFloat(elm["is"]);
		} else if (elm["check"] == "not" || elm["check"] == "!") {
			isTrue = Std.string(ifMap[elm["value"]]) != elm["is"];
		} else {
			isTrue = Std.string(ifMap[elm["value"]]) == elm["is"];
		}
	
		if (!isTrue)
			return;
	
		var tempIndex = getIndexFromID(elm["goto"]);
		if (tempIndex != -1)
			index = tempIndex;
		currentData = data[index];
		if (!autoprogressables.contains(currentData.type))
			performActions();
	}

	function onGotoFile(elm:Map<String, Dynamic>) {
		var file = elm["file"];
		if (!Assets.exists(file)) {
			throw "[onGotoFile] Could not find file: " + file;
		}

		index = 0;
		data = DialogueParser.parse(Assets.getText(file));
		currentData = data[0];
		if (!autoprogressables.contains(currentData.type))
			performActions();
	}

	function onChangeBGM(elm:Map<String, Dynamic>) {
		var file = elm["file"];
		if (!Assets.exists(file)) {
			throw "[onChangeBGM] Could not find file: " + file;
		}

		var song = new FlxSound().loadEmbedded(file);
		song.looped = !elm["oneshot"];
		if (FlxG.sound.music != null) {
			FlxG.sound.music.fadeOut(currentFadeOutDuration, 0, _ -> {
				FlxG.sound.music = song;
				song.play();
				song.fadeIn(elm["fadeInDuration"], elm["initialVolume"], elm["volume"]);
			});
		} else {
			FlxG.sound.music = song;
			song.play();
			song.fadeIn(elm["fadeInDuration"], elm["initialVolume"], elm["volume"]);
		}
		
		currentFadeOutDuration = elm["fadeOutDuration"];
	}

	function onStopBGM(elm:Map<String, Dynamic>) {
		if (currentFadeOutDuration == 0){
			FlxG.sound.music.stop();
			return;
		}
		FlxG.sound.music.fadeOut(currentFadeOutDuration, 0, _ -> {FlxG.sound.music.stop();});
	}

	function onChangeBG(elm:Map<String, Dynamic>) {
		var file = elm["file"];
		if (file != "$same") {
			if (!Assets.exists(file)) {
				throw "[onChangeBG] Could not find file: " + file;
			}

			scene.background.loadGraphic(elm["file"]);
		}

		if (elm["x"] == "none") {
			if (file != "$same")
				elm["x"] = 0;
			else
				elm["x"] = scene.background.x;
		}
		if (elm["y"] == "none") {
			if (file != "$same")
				elm["y"] = 0;
			else
				elm["y"] = scene.background.y;
		}
		scene.background.setPosition(elm["x"], elm["y"]);

		switch (elm["effect"]) {
			case "fade":
					var fadeFrom:Float = 0;
					var fadeTo:Float = 1;
					if (elm.exists("effectArgs")) {
					if (elm["effectArgs"].length > 0)
						fadeFrom = Std.parseFloat(elm["effectArgs"][0]);
					if (elm["effectArgs"].length > 1)
						fadeTo = Std.parseFloat(elm["effectArgs"][1]);
					scene.background.alpha = fadeFrom;
				}
				FlxTween.tween(scene.background, {alpha: fadeTo}, elm["effectDuration"]);
		}
	}

	function onAddSprite(elm:Map<String, Dynamic>) {
		var file = elm["file"];

		if (Assets.exists(file) == false && !scene.spritePresets.exists(file)) {
			throw "[onAddSprite] Could not find file/preset: " + file;
		}

		
		var sprite:FlxSprite = new FlxSprite(elm["x"], elm["y"]);


		if (scene.spritePresets.exists(file)) {
			var presetData = scene.spritePresets.get(file);
			sprite.loadGraphic(presetData.image, true, Std.int(presetData.width), Std.int(presetData.height));
			// sprite.width = presetData.width;
			// sprite.height = presetData.height;

			for (anim in scene.spritePresets.get(file).anims) {
				sprite.animation.add(anim.name, anim.frames, anim.framerate, anim.looped);
				if (anim.name == "idle")
					sprite.animation.play("idle");
			}
		} else {
			sprite.loadGraphic(file);
		}


		scene.foregroundSprites.add(sprite);

		#if debug
		if (activeSprites.exists(elm["id"])){
			Debug.log("[onAddSprite] Sprite with ID " + elm["id"] + " already exists! Overwriting it.", 'scene');
		}
		#end
		activeSprites.set(elm["id"], sprite);


		switch (elm["effect"]) {
			case "fade":
					var fadeFrom:Float = 0;
					var fadeTo:Float = 1;
					if (elm.exists("effectArgs")) {
					if (elm["effectArgs"].length > 0)
						fadeFrom = Std.parseFloat(elm["effectArgs"][0]);
					if (elm["effectArgs"].length > 1)
						fadeTo = Std.parseFloat(elm["effectArgs"][1]);
					sprite.alpha = fadeFrom;
				}
				FlxTween.tween(sprite, {alpha: fadeTo}, elm["effectDuration"]);
		}
	}

	function onPlayAnim(elm:Map<String, Dynamic>) {
		var sprite = activeSprites.get(elm["spriteID"]);

		if (sprite.animation.exists(elm["name"])) {
			sprite.animation.play(elm["name"], elm["force"], elm["reversed"]);
		}
	}

	function onStopAnim(elm:Map<String, Dynamic>) {
		activeSprites.get(elm["spriteID"]).animation.stop();
	}

	function onRemoveSprite(elm:Map<String, Dynamic>) {
		if (activeSprites.get(elm["spriteID"]) == null) {
			Debug.log("[onRemoveSprite] Sprite with id of \"" + elm["spriteID"] + "\" not found", 'scene'); 
			return;
		}

		var sprite = activeSprites.get(elm["spriteID"]);

		switch (elm["effect"]) {
			case "fade":
					var fadeFrom:Float = sprite.alpha;
					var fadeTo:Float = 0;
					if (elm.exists("effectArgs")) {
					if (elm["effectArgs"].length > 0)
						fadeFrom = Std.parseFloat(elm["effectArgs"][0]);
					if (elm["effectArgs"].length > 1)
						fadeTo = Std.parseFloat(elm["effectArgs"][1]);
					sprite.alpha = fadeFrom;
				}

				FlxTween.tween(sprite, {alpha: fadeTo}, elm["effectDuration"], {onComplete: _ -> {
					activeSprites.remove(elm["spriteID"]);
					scene.foregroundSprites.remove(sprite);
					sprite.kill();
				}});
			default:
				activeSprites.remove(elm["spriteID"]);
				scene.foregroundSprites.remove(sprite);
				sprite.kill();
		}
	}

	public var cameraEffects:Array<String> = [];
	public var effectBank:Map<String, (FlxSprite, Map<String,Dynamic>) -> Void> = [];

	function onApplyEffect(elm:Map<String, Dynamic>) {
		if (!activeSprites.exists(elm["spriteID"]) && !cameraEffects.contains(elm["effect"])) {
			throw "Sprite with ID of \"" + elm["spriteID"] + "\" does not exist!";
		}

		var sprite = activeSprites.get(elm["spriteID"]);
		
		switch (elm["effect"]) {
			case "fade":
				var fadeFrom:Float = 0;
				var fadeTo:Float = 1;
				if (elm.exists("effectArgs")) {
				if (elm["effectArgs"].length > 0)
					fadeFrom = Std.parseFloat(elm["effectArgs"][0]);
				if (elm["effectArgs"].length > 1)
					fadeTo = Std.parseFloat(elm["effectArgs"][1]);
				sprite.alpha = fadeFrom;
			}
			FlxTween.tween(sprite, {alpha: fadeTo}, elm["effectDuration"]);
			default:
				var fn = effectBank.get(elm["effect"]);
				fn != null ? fn(sprite, elm) : sprite.shader=null;
				
		}
	}

	function onPlaySound(elm:Map<String, Dynamic>) {
		var file = elm["file"];
		if (!Assets.exists(file)) {
			throw "[onPlaySound] Could not find file: " + file;
		}

		var sound = new FlxSound().loadEmbedded(file, elm["looped"], true);
		sound.volume = elm["volume"];

		sound.play();
		sound.autoDestroy = true;
	}

	#if desktop
	var activeVideo:VideoSprite;
	var videoPausesGame:Bool = false;

	function onPlayVideo(elm:Map<String, Dynamic>) {
		var v:VideoSprite;
		v = new VideoSprite(elm["x"], elm["y"]);

		scene.UI.add(v);
		activeVideo = v;

		v.playVideo(elm["file"]);
		videoPausesGame = elm["pauseGame"];

		v.bitmap.finishCallback = () -> {
			activeVideo.bitmap.stop();
			scene.UI.remove(activeVideo);
			activeVideo.destroy();
			activeVideo=null;
			videoPausesGame= false;
		}
	}
	#end
	// TODO: debug class

	function onChangeScene(elm:Map<String, Dynamic>) {
		var file = elm["file"];
		if (!Assets.exists(file))
			throw "[onChangeScene] Could not find file: " + file;
		
			switch (elm["effect"]) {
				default: // default is fade
					// Do some transition shit later. idk how FlxTransState works
					FlxG.switchState(new Scene(file));
			
		}		
	}

	function onCustom(elm:Map<String, Dynamic>) {
	}



	public override function update(elapsed:Float) {
		if (!isActive)
			return;


		#if desktop
		if (videoPausesGame&&activeVideo!=null) {
			var skip = FlxG.keys.anyJustPressed(Controls.binds[ACCEPT]);
			if (skip) {
				activeVideo.bitmap.stop();
				scene.remove(activeVideo);
				activeVideo.destroy();
				activeVideo=null;
				videoPausesGame= false;
			}

			return;
		}
		#end

		super.update(elapsed);

		var up:Bool = FlxG.keys.anyJustPressed(Controls.binds[UP]);
		var down:Bool = FlxG.keys.anyJustPressed(Controls.binds[DOWN]);
		var accept:Bool = FlxG.keys.anyJustPressed(Controls.binds[ACCEPT]);
		var speedUp:Bool = FlxG.keys.anyPressed(Controls.binds[SPEED_UP]);

		if (isSelectingChoice && choiceSprites.length > 0) {
			if (up) {
				if (--choiceIndex < 0)
					choiceIndex = choices.length - 1;
			} else if (down) {
				if (++choiceIndex > choices.length - 1)
					choiceIndex = 0;
			}

			choiceSprites[choiceIndex].color = FlxColor.WHITE;

			for (i in 0...choiceSprites.length) {
				if (i != choiceIndex)
					choiceSprites[i].color = FlxColor.GRAY;
			}

			if (accept) {
				onChoiceAccept();
			}
		}

		while (autoprogressables.contains(currentData.type)) {
			performActions();
			index++;
			currentData = data[index];
			if (autoprogressables.contains(currentData.type)) {
				performActions();
			} else {
				if (currentData.type=="Talk") index--;
				performActions();
				break;
			}
		}

		if (currentData.type == "End") {
			performActions();
		}

		if (speedUp && isTalking && currentData.type == "Talk")
		{
			var speed = 1 / 120;
			if (currentData.elm["speed"] < speed)
			{
				speed = currentData.elm["speed"] / 3;
			}
			dialogueText.delay = speed;
		}
		else
		{
			if (isTalking)
				dialogueText.delay = currentData.elm["speed"];
		}

		if (index >= data.length - 1)
			isDone = true;


		if (!isDone && !isTalking && !isSelectingChoice && accept) {
			index++;
			currentData = data[index];

			performActions();
		}
	}

	public inline function performActions() {

		#if debug
		Debug.log("Running corresponding callback for " + currentData.type + " action", "dialogue");
		#end

		if (currentData.type == "Choices"){
			onChoices(currentData.elm);
			return;
		}
		if (actionCallbacks.exists(currentData.type))
			actionCallbacks.get(currentData.type)(currentData.elm);
	}

	function completeCallback()
	{
		isTalking = false;

		var next = data[index + 1];

		if (next != null && autoprogressables.contains(next.type)) {
			if (next.elm["waitForAccept"] != null && next.elm["waitForAccept"] == true) {
				return;
			}
			currentData= data[++index];
		}

		if (next != null && next.type == "Choices")
		{
			index++;
			currentData = data[index];
			createChoiceSprites(next.elm["choices"]);
			onChoices(next.elm);
		}
	}
	function getIndexFromID(id:String)
	{
		for (i in data) {
			if (i.elm.exists("id") && i.elm["id"] == id)
				return data.indexOf(i);
		}

		return -1;
	}
}

class ChoiceSprite extends FlxSpriteGroup
{
	public var box:FlxSprite;
	public var text:FlxText;

	public function new(x:Float, y:Float, choice:String)
	{
		super(x, y);
		box = new FlxSprite(0, 0).makeGraphic(14 * 10, 24, FlxColor.GRAY);
		text = new FlxText(6, 6, box.width, choice, 10);

		add(box);
		add(text);
	}
}
