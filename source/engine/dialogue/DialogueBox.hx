package engine.dialogue;

import engine.dialogue.DialogueParser.ChoicesAction;
import engine.dialogue.DialogueParser.TalkAction;
import engine.dialogue.interfaces.IDialogueBox;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.text.FlxTypeText;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.app.Application;

// TODO: Polishing and possible optimizations
class DialogueBox extends FlxSpriteGroup implements IDialogueBox
{
	public var nameBox:FlxSprite;
	public var box:FlxSprite;
	public var nameText:FlxText;
	public var dialogueText:FlxTypeText;

	public var data:Array<Array<Dynamic>>;
	public var currentData:Array<Dynamic>;

	public var choices:ChoicesAction;
	public var choiceSprites:Array<ChoiceSprite> = [];

	public var index:Int = 0;
	public var choiceIndex:Int = 0;

	public var isActive:Bool = true;

	public var isTalking:Bool = false;

	public var isSelectingChoice:Bool = false;

	public var isDone:Bool = false;

	public function new(?x:Float = 0, ?y:Float = 0, data:Array<Array<Dynamic>>)
	{
		super(x, y);
		this.data = data;

		box = new FlxSprite(0, 0).makeGraphic(660, Std.int(640 / 4), FlxColor.GRAY);
		nameText = new FlxText(box.x, box.y - 38, 0, "", 30);
		dialogueText = new FlxTypeText(box.x + 20, box.y + 20, Std.int(box.width - 20), "");

		add(box);
		add(nameText);
		add(dialogueText);

		dialogueText.completeCallback = function()
		{
			isTalking = false;
		}

		currentData = data[index];

		trace(currentData);
		if (currentData[0] == "talk")
		{
			trace(currentData);
			talk();
		}
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!isActive)
			return;

		var next = data[index + 1];

		if (FlxG.keys.justPressed.R)
			FlxG.resetState();

		if (isSelectingChoice)
		{
			if (FlxG.keys.justPressed.UP)
			{
				choiceIndex--;
				if (choiceIndex < 0)
					choiceIndex = choices.length - 1;
			}
			else if (FlxG.keys.justPressed.DOWN)
			{
				choiceIndex++;
				if (choiceIndex > choices.length - 1)
					choiceIndex = 0;
			}

			choiceSprites[choiceIndex].box.color = FlxColor.WHITE;

			for (i in 0...choiceSprites.length)
			{
				if (i != choiceIndex)
					choiceSprites[i].box.color = FlxColor.GRAY;
			}

			if (FlxG.keys.justPressed.ENTER)
			{
				doChoice();
			}
		}

		if (index > data.length - 1)
			isDone = true;

		if (!isDone && !isTalking && !isSelectingChoice && FlxG.keys.justPressed.ENTER)
		{
			index++;
			currentData = data[index];

			if (currentData[0] == "end")
			{
				isDone = true;
				return;
			}
			else if (currentData[0] == "talk")
			{
				talk();
			}
			else if (currentData[0] == "choices")
			{
				initChoices();
			}
		}

		if (!isTalking && currentData[0] != "choices" && next != null && next[0] == "choices")
		{
			index++;
			currentData = data[index];
			initChoices();
		}
	}

	function talk()
	{
		trace("is talk");
		isTalking = true;
		nameText.text = currentData[1].name;
		dialogueText.size = currentData[1].size;
		dialogueText.resetText(currentData[1].text);
		dialogueText.start(currentData[1].speed);
	}

	function initChoices()
	{
		isSelectingChoice = true;
		choices = currentData[1];
		trace(choices);
		for (i in 0...choices.length)
		{
			var c = choices[i];
			var cs = new ChoiceSprite(680, 34 * i, c.text);
			choiceSprites.push(cs);
			add(cs);
		}
	}

	function doChoice()
	{
		var cc = choices[choiceIndex];
		trace("FUCK");
		if (cc.goto != null)
		{
			for (i in data)
			{
				if (i[1] != null && i[1].id != null && i[1].id == cc.goto)
				{
					trace("SHIT");
					index = data.indexOf(i);
					currentData = data[index];
					if (currentData[0] == "talk")
						talk();
					else if (currentData[0] == "choices")
						initChoices();
					else if (currentData[0] == "end")
						isDone = true;

					for (c in choiceSprites)
					{
						remove(c);
						c.destroy();
					}

					isSelectingChoice = false;
					return;
				}
			}
		}

		index++;
		currentData = data[index];
		if (currentData[0] == "talk")
			talk();
		else if (currentData[0] == "choices")
			initChoices();
		else if (currentData[0] == "end")
			isDone = true;

		for (c in choiceSprites)
		{
			remove(c);
			c.destroy();
		}

		isSelectingChoice = false;
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
