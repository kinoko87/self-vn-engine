package engine.dialogue.interfaces;

import flixel.FlxSprite.IFlxSprite;
import flixel.FlxSprite;
import flixel.addons.text.FlxTypeText;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;

interface IDialogueBox
{
	public var box:FlxSprite;
	public var nameText:FlxText;
	public var dialogueText:FlxTypeText;
}
