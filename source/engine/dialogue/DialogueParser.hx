package engine.dialogue;

import Xml;
import haxe.xml.Access;

typedef TalkAction =
{
	var name:String;
	var text:String;
	var id:String;
	var speed:Float;
	var size:Int;
}

typedef GotoFileAction =
{
	var id:String;
	var file:String;
}

typedef IfAction =
{
	var value:String;
	var is_:String;
	var goto:String;
	var check:String;
}

typedef ChoicesAction = Array<ChoiceData>;

typedef ChoiceData =
{
	var text:String;
	var id:String;
	var goto:String;
}

class DialogueParser
{
	public static var DEFAULT_SPEED:Float = 1 / 12;
	public static var DEFAULT_SIZE:Int = 24;

	public static function parse(text:String)
	{
		var actions:Array<Array<Dynamic>> = [];
		var xml:Xml = Xml.parse(text);
		for (e in xml.firstElement().elements())
		{
			var element = new Access(e);

			if (element.name == "Talk")
			{
				var name:String = element.has.name ? element.att.name : "";
				var id:String = element.has.id ? element.att.id : null;
				var speed:Float = element.has.speed ? Std.parseFloat(element.att.speed) : DEFAULT_SPEED;
				var size:Int = element.has.size ? Std.parseInt(element.att.size) : DEFAULT_SIZE;

				actions.push([
					"talk",
					{
						name: name,
						text: element.innerData,
						id: id,
						speed: speed,
						size: size
					}
				]);
			}
			else if (element.name == "Choices")
			{
				var choices:ChoicesAction = [];

				for (c in element.nodes.resolve("Choice"))
				{
					var id = c.has.id ? c.att.id : null;
					var goto = c.has.goto ? c.att.goto : "";
					choices.push({text: c.innerData, id: id, goto: goto});
				}

				actions.push(["choices", choices]);
			}
			else if (element.name == "If")
			{
				var value = element.has.value ? element.att.value : null;
				var is_ = element.has.resolve("is") ? element.att.resolve("is") : null;
				var goto = element.has.goto ? element.att.goto : null;
				var check = element.has.check ? element.att.check : null;

				actions.push([
					"if",
					{
						value: value,
						is_: is_,
						goto: goto,
						check: check.toLowerCase()
					}
				]);
			}
			else if (element.name == "End")
			{
				actions.push(["end", null]);
			}
			else if (element.name == "GotoFile")
			{
				var file = element.has.file ? element.att.file : null;
				var id = element.has.id ? element.att.id : null;

				actions.push(["gotofile", {file: file, id: id}]);
			}
		}

		return actions;
	}
}
