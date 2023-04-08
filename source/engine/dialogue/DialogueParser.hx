package engine.dialogue;

import openfl.Assets;
import haxe.Json;
import Xml;
import haxe.xml.Access;

using StringTools;

typedef ParserRule = Array<{attribute:String, as:String, ?from:String, ?defaultValue:Dynamic}>;
typedef Action = {type:String, elm:Map<String, Dynamic>};

class DialogueParser
{
	public static var DEFAULT_SPEED:Float = 1 / 12;
	public static var DEFAULT_SIZE:Int = 24;

	private static var parserRules:Map<String, ParserRule> = [];

	public static function init() {
		#if debug
		trace("[PARSER RULE ENTRIES]");
		trace("---------------------");
		#end
		var ruleJson:Array<{name:String, rule:ParserRule}> = Json.parse(Assets.getText('assets/data/engine/parser_rules.json'));
		for (r in 0...ruleJson.length) {
			for (c in ruleJson[r].rule) {
				if (c.from == null) {
					c.from = c.attribute;
				}
			}
			parserRules.set(ruleJson[r].name, cast ruleJson[r].rule);
			#if debug
			trace(ruleJson[r].name + ' (${ruleJson[r].rule.length} attributes)');
			#end
		}
	}

	public static function parse(text:String) {
		var actions:Array<Action> = [];
		var xml:Xml = Xml.parse(text);

		for (e in xml.firstElement().elements()) {
			var element = new Access(e);

			if (element.name == "Choices") {
				var choices:Array<{text:String, id:String, goto:String}> = [];

				for (c in element.nodes.resolve("Choice"))
				{
					var id:String = c.has.id ? c.att.id : null;
					var goto:String = c.has.goto ? c.att.goto : "";
					choices.push({text: c.innerData, id: id, goto: goto});
				}

				actions.push({type: "Choices", elm: ["choices" => choices]});
				continue;
			}

			if (parserRules.exists(element.name)) {
				var action:Map<String, Dynamic> = [];
				var rule = parserRules.get(element.name);


				for (a in rule) {
					switch (a.as) {
						case "string", null:
							if (a.from != "innerData")
								action.set(a.attribute, element.has.resolve(a.from) ? element.att.resolve(a.from) : a.defaultValue);
							else
								action.set(a.attribute, element.innerData);
						case "float":
							if (a.defaultValue == null)
								a.defaultValue = 0;
							if (a.from != "innerData")
								action.set(a.attribute, element.has.resolve(a.from)
								? Std.parseFloat(element.att.resolve(a.from)) : a.defaultValue);
							else
								action.set(a.attribute, Std.parseFloat(element.innerData));

						case "int", "integer":
							if (a.defaultValue == null)
								a.defaultValue = 0;
							if (a.from != "innerData")
								action.set(a.attribute, element.has.resolve(a.from)
								? Std.parseInt(element.att.resolve(a.from)) : a.defaultValue);
							else
								action.set(a.attribute, Std.parseInt(element.innerData));
						case "bool", "boolean":
							if (a.from != "innerData")
								action.set(a.attribute, element.has.resolve(a.from)
								? element.att.resolve(a.from) == "true" : false);
							else
								action.set(a.attribute, element.innerData == "true" ? true : false);
						case "array", "arr":
							if (a.defaultValue == null)
								a.defaultValue = [];
							if (a.from != "innerData")
								action.set(a.attribute, element.has.resolve(a.from) ? [for (i in element.att.resolve(a.from).split(',')) i.trim()] : cast a.defaultValue);
							else
								action.set(a.attribute, [for (i in element.innerData.split(',')) i.trim()]);
					}
				}

				actions.push({type: element.name, elm: action});
			}
		}

		return actions;
	}
}
