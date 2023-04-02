package engine.dialogue;

import flixel.math.FlxRect;
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
import openfl.utils.Assets;

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

	public var scene:Scene;

	public var isActive:Bool = true;

	public var isTalking:Bool = false;

	public var isSelectingChoice:Bool = false;

	public var isDone:Bool = false;
	
	public var ifMap:Map<String, Dynamic> = ["debug" => #if debug true #else false #end, "num" => 12];

	//							 id      sprite
	public var activeSprites:Map<String, FlxSprite> = [];

	public function new(?x:Float = 0, ?y:Float = 0, data:Array<Array<Dynamic>>, scene:Scene)
	{
		super(x, y);
		this.data = data;
		this.scene = scene;

		box = new FlxSprite(0, 0).makeGraphic(660, Std.int(640 / 4), FlxColor.GRAY);
		nameText = new FlxText(box.x, box.y - 38, 0, "", 30);
		dialogueText = new FlxTypeText(box.x + 20, box.y + 20, Std.int(box.width - 20), "");

		add(box);
		add(nameText);
		add(dialogueText);

		dialogueText.completeCallback = completeCallback;

		currentData = data[index];

		doActions();
	}

	public override function update(elapsed:Float)
	{
		if (!isActive)
			return;


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

		if (FlxG.keys.pressed.SHIFT && !isDone && currentData[0] == "talk")
		{
			var speed = 1 / 120;
			if (currentData[1].speed < speed)
			{
				speed = currentData[1].speed / 3;
			}
			dialogueText.delay = speed;
		}
		else
		{
			if (isTalking)
				dialogueText.delay = currentData[1].speed;
		}

		super.update(elapsed);

		while (currentData[0] == "changebgm" || currentData[0] == "changebg" || currentData[0] == "show" || currentData[0] == "hide") {
			index++;
			currentData = data[index];
			trace("HEYHEY", currentData[1]);
			doActions();

		}

		if (index < data.length - 1 && !isDone && !isTalking && !isSelectingChoice && FlxG.keys.justPressed.ENTER)
		{
			index++;
			currentData = data[index];

			doActions();
		}
	}

	function ifCheck()
	{
		var isTrue = false;

		if (currentData[1].check == "lt" || currentData[1].check == "<")
		{
			isTrue = ifMap[currentData[1].value] < Std.parseFloat(currentData[1].is_);
		}
		else if (currentData[1].check == "lte" || currentData[1].check == "<=")
		{
			isTrue = ifMap[currentData[1].value] <= Std.parseFloat(currentData[1].is_);
		}
		else if (currentData[1].check == "gt" || currentData[1].check == ">")
		{
			isTrue = ifMap[currentData[1].value] > Std.parseFloat(currentData[1].is_);
		}
		else if (currentData[1].check == "gte" || currentData[1].check == ">=")
		{
			isTrue = ifMap[currentData[1].value] >= Std.parseFloat(currentData[1].is_);
		}
		else if (currentData[1].check == "not" || currentData[1].check == "!")
		{
			isTrue = Std.string(ifMap[currentData[1].value]) != currentData[1].is_;
		}
		else
		{
			isTrue = Std.string(ifMap[currentData[1].value]) == currentData[1].is_;
		}

		if (isTrue)
		{
			index = getIndexFromID(currentData[1].goto);
			currentData = data[index];
			doActions();
		}
	}

	function doActions()
	{
		if (currentData[0] == "talk")
			talk();
		else if (currentData[0] == "choices")
			initChoices();
		else if (currentData[0] == "if")
			ifCheck();
		else if (currentData[0] == "gotofile")
			gotoFile();
		else if (currentData[0] == "changebgm")
			FlxG.sound.playMusic(currentData[1].file);
		else if (currentData[0] == "changebg") {
			trace(currentData[1]);
			scene.background.loadGraphic(currentData[1].file);
			scene.background.x = currentData[1].x;
			scene.background.y = currentData[1].y;
		} else if (currentData[0] == "show") {
			if (scene.spritePresets.exists(currentData[1].sprite)) {
				var stuff = scene.spritePresets.get(currentData[1].sprite);
				var sprite = new FlxSprite(currentData[1].x, currentData[1].y).loadGraphic(stuff.img);
				sprite.clipRect = stuff.clipRect;
				scene.foregroundSprites.add(sprite);
				if (currentData[1].id != null)
					activeSprites.set(currentData[1].id, sprite);
			} else {
				var sprite = new FlxSprite(currentData[1].x, currentData[1].y).loadGraphic(currentData[1].sprite);
				scene.foregroundSprites.add(sprite);
				if (currentData[1].id != null)
					activeSprites.set(currentData[1].id, sprite);
			}
		}
		else if (currentData[0] == "end")
			isDone = true;
	}

	function gotoFile()
	{
		index = 0;
		var file = currentData[1].file;
		trace("DA FILE is ", file);
		this.data = DialogueParser.parse(Assets.getText(file));
		currentData = data[index];
		doActions();
	}


	function talk()
	{
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
		if (cc.goto != null)
		{
			for (i in data)
			{
				if (i[1] != null && i[1].id != null && i[1].id != null && i[1].id == cc.goto)
				{
					index = data.indexOf(i);
					currentData = data[index];
					doActions();

					while (choiceSprites.length > 0)
					{
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
		doActions();

		for (c in choiceSprites)
		{
			remove(c);
			c.destroy();
		}

		isSelectingChoice = false;
	}

	function completeCallback()
	{
		isTalking = false;
		var next = data[index + 1];

		if (next != null && next[0] == "choices")
		{
			index++;
			currentData = data[index];
			initChoices();
		}
	}

	function getIndexFromID(id:String)
	{
		for (i in data)
		{
			if (i[0] != "choices" && i[0] != "if" && i[0] != "end" && i[1].id == id)
			{
				return data.indexOf(i);
			}
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
