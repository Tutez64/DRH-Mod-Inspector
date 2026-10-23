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
 * state and server field; the game's own event bus reports the actor under the cursor, whose fields it
 * reads by reflection. The last actor hovered stays watched until another is, and F7 pins it. Every
 * actor has the same fields, hero or prop, so the panel shows first those that changed since it was
 * first watched, then its public ones; F10 writes it to the mod's `data` folder with every field. F8
 * shows or hides the panel, F9 freezes it.
 */
class Main extends Mod {
	static inline final F7 = 118;

	static inline final F8 = 119;

	static inline final F9 = 120;

	static inline final F10 = 121;

	/** How many lines each list keeps. */
	static inline final KEPT = 8;

	/** At most how many of the watched actor's fields the panel shows; a written snapshot has them all. */
	static inline final SHOWN_FIELDS = 16;

	/** Frames between two readings of the watched actor's fields, which call its getters. */
	static inline final READ_EVERY = 15;

	var context:Context;

	var panel:Panel;

	/** The current state of each machine of the game but the actors', by the machine's class. */
	var states:Map<String, String> = new Map();

	var actorStateChanges:Int = 0;

	/** Ready objects by class. */
	var objects:Map<String, Int> = new Map();

	var arrivals:Array<String> = [];

	/** Times each field was received, by its name. */
	var fields:Map<String, Int> = new Map();

	var recentFields:Array<String> = [];

	/** The last actor hovered, until another is, unless it is pinned. */
	var watched:Null<ActorGameObject>;

	var pinned:Bool = false;

	/** The watched actor's fields, as last read: changed ones first, then public ones, then internal ones. */
	var watchedFields:Array<String> = [];

	/** How many of them the panel shows: changed and public ones. */
	var watchedShown:Int = 0;

	/** Each actor's field values when it was first watched, to tell those that changed since. */
	var baselines:haxe.ds.ObjectMap<ActorGameObject, Map<String, String>> = new haxe.ds.ObjectMap();

	var frames:Int = 0;

	var frozen:Bool = false;

	/** What the panel shows, and the watched actor's fields in full, for F10. */
	var shown:Array<String> = [];

	var listening:Bool = false;

	override public function init(context:Context):Void {
		this.context = context;
		panel = new Panel();
		context.overlay.addChild(panel);
		// Redrawn on the panel's own frames: they stop with the overlay layer if the mod fails.
		panel.addEventListener(Event.ENTER_FRAME, refresh);
		context.onKeyDown(function(key) {
			switch (key) {
				case F7:
					pinned = watched != null && !pinned;
				case F8:
					panel.visible = !panel.visible;
				case F9:
					frozen = !frozen;
				case F10:
					write();
				default:
					return false;
			}
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
			if (object == watched) {
				watched = null;
				pinned = false;
			}
			baselines.remove(cast object);
		});
		core.onFieldReceived(function(object, field, name) {
			var key = name != "" ? name : nameOf(object) + " field " + field;
			count(fields, key, 1);
			remember(recentFields, key);
		});
		core.onStateEnter(stateEntered);
	}

	override public function ready(context:Context):Void {
		// The game's own bus: its listeners are not the core's, so they are removed in `dispose`.
		var events = context.core.facade.eventManager;
		events.addEventListener("MouseOverOnActorEvent", hover);
				listening = true;
	}

	override public function dispose():Void {
		var facade = context == null ? null : context.core.facade;
		if (!listening || facade == null)
			return;
		facade.eventManager.removeEventListener("MouseOverOnActorEvent", hover);
	}

	function stateEntered(machine:StateMachine, state:State):Void {
		if (Std.isOfType(machine, ActorStateMachine))
			actorStateChanges++;
		else
			states.set(nameOf(machine), state.name);
	}

	function hover(event:DBMouseEvent):Void {
		if (pinned || event.actor == watched)
			return;
		watched = event.actor;
		watchedFields = [];
		watchedShown = 0;
		frames = 0;
	}

	function refresh(_):Void {
		if (!panel.visible || frozen || !context.core.alive)
			return;
		var actor = watched != null && !watched.isDestroyed ? watched : null;
		if (actor != null && frames++ % READ_EVERY == 0)
			read(actor);

		var lines = ["INSPECTOR   F7 pin, F8 hide, F9 freeze, F10 write", "", "States:"];
		for (machine in sorted(states.keys()))
			lines.push("  " + machine + ": " + states.get(machine));
		lines.push("  actors: " + actorStateChanges + " changes");
		lines.push("");
		lines.push(pinned ? "Pinned:" : "Last hovered:");
		if (actor == null) {
			lines.push("  nothing");
		} else {
			lines.push("  " + label(actor) + "   * changed");
			var shownHere = Std.int(Math.min(SHOWN_FIELDS, watchedShown));
			for (i in 0...shownHere)
				lines.push("    " + watchedFields[i]);
			if (watchedFields.length > shownHere)
				lines.push("    … " + (watchedFields.length - shownHere) + " more with F10");
		}
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

		shown = lines.copy();
		if (actor != null && watchedFields.length > Math.min(SHOWN_FIELDS, watchedShown)) {
			shown.push("");
			shown.push(label(actor) + ", every field:");
			for (line in watchedFields)
				shown.push("  " + line);
		}
	}

	/** What the panel shows, in a new file of the mod's `data` folder. */
	function write():Void {
		var stamp = DateTools.format(Date.now(), "%Y%m%d-%H%M%S");
		var path = context.data + "/inspector-" + stamp + ".txt";
		try {
			sys.io.File.saveContent(path, shown.join("\n") + "\n");
			context.log("wrote " + path);
		} catch (e:Dynamic) {
			context.log("could not write " + path + ": " + Std.string(e));
		}
	}

	/**
	 * Reads the actor's fields and properties: those that changed since it was first watched, marked,
	 * then its public ones, then its internal ones (`mName`, the game's private storage), each by name.
	 */
	function read(actor:ActorGameObject):Void {
		var changed = [];
		var open = [];
		var internal = [];
		var baseline = baselines.get(actor);
		var first = baseline == null;
		if (first) {
			baseline = new Map();
			baselines.set(actor, baseline);
		}
		for (field in readable(actor)) {
			if (first)
				baseline.set(field.name, field.value);
			var line = field.name + " = " + field.value;
			if (baseline.get(field.name) != field.value)
				changed.push("* " + line);
			else if (internalName(field.name))
				internal.push(line);
			else
				open.push(line);
		}
		watchedFields = changed.concat(open).concat(internal);
		watchedShown = changed.length + open.length;
	}

	/** The game's private storage, by its AS3 naming: `m` then a capital. */
	static function internalName(name:String):Bool {
		return name.length > 1 && name.charAt(0) == "m" && name.charAt(1) == name.charAt(1).toUpperCase()
			&& name.charAt(1) != name.charAt(1).toLowerCase();
	}

	/**
	 * The object's fields and properties with their values, by name. A property is read through its
	 * getter; a getter that throws is left out.
	 */
	static function readable(object:Dynamic):Array<{name:String, value:String}> {
		var names = Type.getInstanceFields(Type.getClass(object));
		var fields = [];
		for (name in sorted(names.iterator())) {
			var property = StringTools.startsWith(name, "get_") ? name.substr(4) : null;
			// A property's storage is shown through its getter.
			if (property == null && names.indexOf("get_" + name) >= 0)
				continue;
			try {
				var value:Dynamic = property != null ? Reflect.getProperty(object, property) : Reflect.field(object, name);
				if (!Reflect.isFunction(value))
					fields.push({name: property != null ? property : name, value: describe(value)});
			} catch (_:Dynamic) {}
		}
		return fields;
	}

	static function describe(value:Dynamic):String {
		if (value == null)
			return "null";
		if (Std.isOfType(value, GameObject))
			return label(value);
		if (Std.isOfType(value, String) || Std.isOfType(value, Float) || Std.isOfType(value, Bool)) {
			var text = Std.string(value);
			return text.length > 48 ? text.substr(0, 47) + "…" : text;
		}
		var type = Type.getClass(value);
		return type == null ? Std.string(Type.typeof(value)) : nameOf(value);
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
