package mods.inspector;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

/** A text panel at the top right. */
class Panel extends Sprite {
	static inline final WIDTH = 420;

	var text:TextField;

	/** The text's height when the background was last drawn. */
	var textHeight:Float = -1;

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
		var height:Float = text.textHeight + 6;
		// The background is drawn again only when the text takes another height.
		if (height != textHeight) {
			textHeight = height;
			text.height = height;
			graphics.clear();
			graphics.beginFill(0x000000, 0.7);
			graphics.drawRect(0, 0, WIDTH, height + 8);
			graphics.endFill();
		}
		x = Math.round(viewWidth - WIDTH - 8);
		y = 8;
	}
}
