package;

import engine.Controls;
import engine.Scene;
import flixel.FlxG;
import engine.dialogue.DialogueBox;
import engine.dialogue.DialogueParser;
import flixel.FlxSprite;
import flixel.FlxState;
import openfl.Assets;


class InitState extends FlxState
{
	override public function create()
	{
		Controls.init();
		FlxG.switchState(new Scene("assets/level.json"));
		super.create();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
