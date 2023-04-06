package;

import engine.Scene;
import flixel.FlxG;
import engine.dialogue.DialogueBox;
import engine.dialogue.DialogueParser;
import flixel.FlxSprite;
import flixel.FlxState;
import openfl.Assets;


class PlayState extends FlxState
{
	override public function create()
	{
		trace([for (x in DialogueParser.parse(Assets.getText("assets/test.xml"))) x.type]);
		FlxG.switchState(new Scene("assets/level.json"));
		super.create();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
