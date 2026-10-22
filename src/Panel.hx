package mods.inspector;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

/** A text panel at the top right. */
class Panel extends Sprite {
	static inline final WIDTH = 420;

	var text:TextField;

	public function new() {
		super();
		mouseEnabled = false;
		mouseChildren = false;

		text = new TextField();
		text.defaultTextFormat = new TextFormat("_typewriter", 12, 0xE0E0E0);
		text.selectable = false;
		text.multiline = true;
		text.width = WIDTH - 12;
		text.x = 6;
		text.y = 4;
		addChild(text);
	}

	public function show(lines:Array<String>, viewWidth:Float):Void {
		text.text = lines.join("\n");
		text.height = text.textHeight + 6;
		graphics.clear();
		graphics.beginFill(0x000000, 0.7);
		graphics.drawRect(0, 0, WIDTH, text.height + 8);
		graphics.endFill();
		x = Math.round(viewWidth - WIDTH - 8);
		y = 8;
	}
}
