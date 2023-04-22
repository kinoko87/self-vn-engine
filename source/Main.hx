package;

import engine.dialogue.DialogueParser;
import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		DialogueParser.init();
		addChild(new FlxGame(0, 0, InitState));
	}
}
