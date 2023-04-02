package engine;

import flixel.group.FlxGroup.FlxTypedGroup;
import haxe.Json;
import lime.utils.Assets;
import engine.dialogue.DialogueParser;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.FlxSprite;
import engine.dialogue.DialogueBox;
import flixel.addons.transition.TransitionData;
import flixel.math.FlxRect;
import flixel.addons.transition.FlxTransitionableState;

typedef SceneFile = {
	var initialBackground:{x:Float, y:Float, image:String}
	var initialBGM:String;
	var initialDialogue:String;
	var transIn:{type: TransitionType, duration: Float, color: Int};
	var transOut:{type: TransitionType, duration: Float, color: Int};
	var spritePresets:Array<{name:String, image:String, rect:{x:Float, y:Float, w:Float, h:Float}}>;
}

class Scene extends FlxTransitionableState
{

	var sceneFile:SceneFile;

	public var background:FlxSprite;
	public var backgroundSprites:FlxTypedGroup<FlxSprite>;
	public var foregroundSprites:FlxTypedGroup<FlxSprite>;
	public var UI:FlxTypedGroup<FlxSprite>;

	public var dialogue:Array<Array<Dynamic>>;
	public var dialogueBox:DialogueBox;

	public var spritePresets:Map<String, {img:String, clipRect:FlxRect}> = [];

	public function new(sceneFilePath:String)
	{
		super();
		sceneFile = cast Json.parse(Assets.getText(sceneFilePath));
		transIn = new TransitionData(sceneFile.transIn.type, sceneFile.transIn.color, sceneFile.transIn.duration);
		transOut = new TransitionData(sceneFile.transIn.type, sceneFile.transIn.color, sceneFile.transIn.duration);
		dialogue = DialogueParser.parse(Assets.getText(sceneFile.initialDialogue));

		if (sceneFile.spritePresets != null) {
			for (i in sceneFile.spritePresets) {
				var r = new FlxRect(i.rect.x, i.rect.y, i.rect.w, i.rect.h);
				spritePresets.set(i.name, {img: i.image, clipRect: r});
			}
		}
	}

	public override function create() {

		backgroundSprites = new FlxTypedGroup<FlxSprite>();
		foregroundSprites = new FlxTypedGroup<FlxSprite>();
		UI = new FlxTypedGroup<FlxSprite>();

		UI.memberAdded.add(function(s) {
			s.scrollFactor.set();
		});

		add(backgroundSprites);
		add(foregroundSprites);
		add(UI);


		background = new FlxSprite(sceneFile.initialBackground.x, sceneFile.initialBackground.y);
		if (sceneFile.initialBackground.image != null && sceneFile.initialBGM.length > 0)
			background.loadGraphic(sceneFile.initialBackground.image);	

		backgroundSprites.add(background);

		if (sceneFile.initialBGM != null && sceneFile.initialBGM.length > 0)
			FlxG.sound.playMusic(sceneFile.initialBGM);
		dialogueBox = new DialogueBox(60, 420, dialogue, this);

		UI.add(dialogueBox);

		super.create();
	}

	public override function update(elapsed:Float) {
		if (FlxG.keys.justPressed.R)
			FlxG.switchState(new Scene("assets/level.json"));
		super.update(elapsed);
	}
}
