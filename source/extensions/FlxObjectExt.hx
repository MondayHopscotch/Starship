package extensions;

import flixel.FlxObject;

class FlxObjectExt {
	/* A utility for positioning the midpoint of a FlxObject to a location */
	static public function setMidpoint(o:FlxObject, x:Float, y:Float) {
		o.setPosition(x - o.width / 2, y - o.height / 2);
	}
}
