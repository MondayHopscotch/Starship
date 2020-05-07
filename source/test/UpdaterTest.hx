package test;

import flixel.FlxBasic;
import flixel.FlxG;

class UpdaterTest extends FlxBasic {
	public static function init():Void {
		FlxG.plugins.add(new UpdaterTest());
	}

	public function new() {
		super();
	}

	override public function update(delta:Float) {
		FlxG.watch.addQuick("UPDATER TEST WORKING:", true);
	}
}
