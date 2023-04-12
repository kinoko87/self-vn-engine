package engine.dialogue;

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
	
	public var ifMap:Map<String, Dynamic> = ["debug" => #if debug true #else false #end, "true"=>true, "null"=>null];

	//							 id      sprite
	public var activeSprites:Map<String, FlxSprite> = [];
	//							id		sound
	public var activeSounds:Map<String, FlxSound> = [];

	private var currentFadeOutDuration:Float = 0;

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
		on("ChangeBG", onChangeBG);
		on("AddSprite", onAddSprite);
		on("RemoveSprite", onRemoveSprite);
		on("PlayAnim", onPlayAnim);
		on("StopAnim", onStopAnim);
		on("PlaySound", onPlaySound);
		on("ApplyEffect", onApplyEffect);
		on("Set", _ -> {FlxG.save.data.stuff[_["variable"]] = _["to"];});
		on("Custom", onCustom);

		autoprogressables = Assets.getText("assets/engine/data/autoprogressables.txt").split('\n');

		currentFadeOutDuration = scene.sceneFile.initialBGM.fadeOutDuration;

		activeSprites["background"] = scene.background;

		performActions();
	}

	function initializeObjects() {
		box = new FlxSprite(0, 0).makeGraphic(660, Std.int(640 / 4), FlxColor.GRAY);
		nameText = new FlxText(box.x, box.y - 38, 0, "", 30);
		dialogueText = new FlxTypeText(box.x + 20, box.y + 20, Std.int(box.width - 20), "");

		add(box);
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
		trace("Balls");
		isTalking = true;
		nameText.text = elm["name"];
		dialogueText.size = elm["size"];
		dialogueText.resetText(elm["text"]);
		dialogueText.start(elm["speed"]);
		trace(elm["speed"], elm["text"], elm["skip"]);
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


		if (curChoice.goto != null) {
			for (i in data) {
				if (i.elm["id"] != null && i.elm["id"] == curChoice.goto) {
					index = data.indexOf(i);
					currentData = data[index];
					performActions();

					while (choiceSprites.length > 0) {
						remove(choiceSprites[0]);
						choiceSprites[0].destroy();
						choiceSprites.remove(choiceSprites[0]);
					}

					trace('ok');

					isSelectingChoice = false;
					choiceIndex = 0;
					return;
				}
			}
		}

		trace('yea');
		index++;
		currentData = data[index];
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
		performActions();
	}

	function onChangeBGM(elm:Map<String, Dynamic>) {
		var file = elm["file"];
		if (!Assets.exists(file)) {
			throw "[onChangeBGM] Could not find file: " + file;
		}

		var song = new FlxSound().loadEmbedded(file);
		song.looped = !elm["oneshot"];
		FlxG.sound.music.fadeOut(currentFadeOutDuration, 0, _ -> {
			FlxG.sound.music = song;
			song.play();
			song.fadeIn(elm["fadeInDuration"], elm["initialVolume"], elm["volume"]);
		});
		
		currentFadeOutDuration = elm["fadeOutDuration"];
	}

	function onStopBGM(elm:Map<String, Dynamic>) {
		FlxG.sound.music.fadeOut(elm["fadeOutDuration"], 0, _ -> {FlxG.sound.music.stop();});
	}

	function onChangeBG(elm:Map<String, Dynamic>) {
		var file = elm["file"];
		if (file != "$same") {
			if (!Assets.exists(file)) {
				throw "[onChangeBG] Could not find file: " + file;
			}

			scene.background.loadGraphic(elm["file"]);
		}

		trace(elm);

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
		trace(Assets.exists(file));
		trace(!Assets.exists(file));
		if (Assets.exists(file) == false /*|| !scene.spritePresets.exists(file)*/) {
			throw "[onAddSprite] Could not find file/preset: " + file;
		}

		var sprite:FlxSprite = new FlxSprite(elm["x"], elm["y"]);

		if (scene.spritePresets.exists(file)) {
			var presetData = scene.spritePresets.get(file);
			sprite.loadGraphic(presetData.img);
			sprite.clipRect = presetData.clipRect;
			sprite.width = clipRect.width;
			sprite.height = clipRect.height;

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
			trace("[onAddSprite] Sprite with ID " + elm["id"] + " already exists! Overwriting it.");
		}
		#end
		activeSprites.set(elm["id"], sprite);

		trace(elm["effectArgs"]);


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
			trace("[onRemoveSprite] Sprite with id of \"" + elm["spriteID"] + "\" not found"); 
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

	function onApplyEffect(elm:Map<String, Dynamic>) {
		if (!activeSprites.exists(elm["spriteID"])) {
			throw "Sprite with ID of \"" + elm["spriteID"] + "\" does not exist!";
		}

		var sprite = activeSprites.get(elm["spriteID"]);
		
		switch (elm["effect"]) {
			default:
				sprite.shader = null;
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

	function onCustom(elm:Map<String, Dynamic>) {
	}



	public override function update(elapsed:Float) {
		if (!isActive)
			return;

		super.update(elapsed);
		
		var up:Bool = FlxG.keys.justPressed.UP;
		var down:Bool = FlxG.keys.justPressed.DOWN;
		var accept:Bool = FlxG.keys.justPressed.ENTER;
		var speedUp:Bool = FlxG.keys.pressed.SHIFT;

		if (isSelectingChoice && choiceSprites.length > 0) {
			if (up) {
				trace("EEEEEYP");
				if (--choiceIndex < 0)
					choiceIndex = choices.length - 1;
			} else if (down) {
				trace("DDDDDDYP");
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
			trace("Autoprogressable");
			trace('autoprogressable: ', currentData.type);
			index++;
			currentData = data[index];
			trace('new', currentData.type);
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
		if (currentData.type == "Choices"){
			onChoices(currentData.elm);
			return;
		}
		trace(currentData.type, actionCallbacks.get(currentData.type));
		if (actionCallbacks.exists(currentData.type))
			actionCallbacks.get(currentData.type)(currentData.elm);
	}

	function completeCallback()
	{
		isTalking = false;

		var next = data[index + 1];

		if (next != null && autoprogressables.contains(next.type)) {
			trace('okbuddy sex');
			currentData= data[++index];
			next = data[index+1];
			performActions();
		}

		while (next != null && autoprogressables.contains(next.type)) {
			trace('autoprogressable: ', currentData.type);
			index++;
			currentData = data[index];
			next = data[index+1];
			performActions();
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
