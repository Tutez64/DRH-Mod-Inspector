package mods.inspector;

import actor.ActorGameObject;
import actor.player.input.dBMouseEvents.DBMouseEvent;
import actor.stateMachine.ActorStateMachine;
import brain.gameObject.GameObject;
import brain.stateMachine.State;
import brain.stateMachine.StateMachine;
import mods.api.Context;
import mods.api.Mod;
import openfl.events.Event;

/**
 * An `extends` mod: it shows the game itself, which the `api` keeps behind stable readings, so a
 * modder sees what is there to build on. The core's generic events (`context.core`) report every object,
 * state and server field; the game's own event bus reports the actor under the cursor. F8 shows or
 * hides the panel.
 */
class Main extends Mod {
	static inline final F8 = 119;

	/** How many lines each list keeps. */
	static inline final KEPT = 8;

	var context:Context;

	var panel:Panel;

	/** The current state of each machine of the game but the actors', by the machine's class. */
	var states:Map<String, String> = new Map();

	var actorStateChanges:Int = 0;

	/** Ready objects by class. */
	var objects:Map<String, Int> = new Map();

	var arrivals:Array<String> = [];

	/** Times each object class received each field, most recent first. */
	var fields:Map<String, Int> = new Map();

	var recentFields:Array<String> = [];

	var hovered:Null<ActorGameObject>;

	var listening:Bool = false;

	override public function init(context:Context):Void {
		this.context = context;
		panel = new Panel();
		context.overlay.addChild(panel);
		// Redrawn on the panel's own frames: they stop with the overlay layer if the mod fails.
		panel.addEventListener(Event.ENTER_FRAME, refresh);
		context.onKeyDown(function(key) {
			if (key != F8)
				return false;
			panel.visible = !panel.visible;
			return true;
		});
		var core = context.core;
		core.onObjectReady(function(object) {
			count(objects, nameOf(object), 1);
			remember(arrivals, "+ " + label(object));
		});
		core.onObjectGone(function(object) {
			count(objects, nameOf(object), -1);
			remember(arrivals, "- " + label(object));
			if (object == hovered)
				hovered = null;
		});
		core.onFieldReceived(function(object, field) {
			var key = nameOf(object) + " field " + field;
			count(fields, key, 1);
			remember(recentFields, key);
		});
		core.onStateEnter(stateEntered);
	}

	override public function ready(context:Context):Void {
		// The game's own bus: its listeners are not the core's, so they are removed in `dispose`.
		var events = context.core.facade.eventManager;
		events.addEventListener("MouseOverOnActorEvent", hover);
		events.addEventListener("MouseOutOnActorEvent", leave);
		listening = true;
	}

	override public function dispose():Void {
		var facade = context == null ? null : context.core.facade;
		if (!listening || facade == null)
			return;
		facade.eventManager.removeEventListener("MouseOverOnActorEvent", hover);
		facade.eventManager.removeEventListener("MouseOutOnActorEvent", leave);
	}

	function stateEntered(machine:StateMachine, state:State):Void {
		if (Std.isOfType(machine, ActorStateMachine))
			actorStateChanges++;
		else
			states.set(nameOf(machine), state.name);
	}

	function hover(event:DBMouseEvent):Void {
		hovered = event.actor;
	}

	function leave(event:DBMouseEvent):Void {
		if (event.actor == hovered)
			hovered = null;
	}

	function refresh(_):Void {
		if (!panel.visible || !context.core.alive)
			return;
		var lines = ["INSPECTOR (F8)", "", "States:"];
		for (machine in sorted(states.keys()))
			lines.push("  " + machine + ": " + states.get(machine));
		lines.push("  actors: " + actorStateChanges + " changes");
		lines.push("");
		lines.push("Under the cursor:");
		var actor = hovered;
		lines.push(actor == null || actor.isDestroyed ? "  nothing" : "  " + label(actor) + ", hp " + actor.hitPoints + "/"
			+ Math.round(actor.maxHitPoints) + ", " + (actor.stateMachine == null ? "" : actor.stateMachine.currentStateName));
		lines.push("");
		lines.push("Objects ready:");
		for (name in sorted(objects.keys()))
			if (objects.get(name) > 0)
				lines.push("  " + objects.get(name) + " " + name);
		lines.push("Last arrived or gone:");
		for (line in arrivals)
			lines.push("  " + line);
		lines.push("");
		lines.push("Fields last received (times):");
		for (key in recentFields)
			lines.push("  " + key + " (" + fields.get(key) + ")");
		panel.show(lines, context.viewWidth);
	}

	static function count(counts:Map<String, Int>, key:String, by:Int):Void {
		var value = counts.get(key);
		counts.set(key, (value == null ? 0 : value) + by);
	}

	/** Puts `line` first, once, keeping the most recent ones. */
	static function remember(list:Array<String>, line:String):Void {
		list.remove(line);
		list.unshift(line);
		if (list.length > KEPT)
			list.pop();
	}

	static function sorted(keys:Iterator<String>):Array<String> {
		var keys = [for (key in keys) key];
		keys.sort(function(a, b) return a < b ? -1 : a > b ? 1 : 0);
		return keys;
	}

	/** The class name without its package. */
	static function nameOf(object:Dynamic):String {
		var name = Type.getClassName(Type.getClass(object));
		return name.substr(name.lastIndexOf(".") + 1);
	}

	static function label(object:GameObject):String {
		return nameOf(object) + "#" + object.id;
	}
}
