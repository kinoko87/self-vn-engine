package;

import engine.dialogue.DialogueBox;
import engine.dialogue.DialogueParser;
import flixel.FlxSprite;
import flixel.FlxState;
import openfl.Assets;

class PlayState extends FlxState
{
	override public function create()
	{
		var sex = DialogueParser.parse(Assets.getText("assets/test.xml"));
		var ok = new DialogueBox(60, 420, sex);
		add(ok);
		var x = new FlxSprite(660).makeGraphic(64, 64);
		add(x);
		super.create();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
