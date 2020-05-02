package objects;

import flixel.addons.nape.FlxNapeSprite;
import nape.phys.Body;

class SelfAssigningFlxNapeSprite extends FlxNapeSprite {
	public function new() {
		super();
	}

	override function setBody(body:Body):Void {
		super.setBody(body);
		body.userData.data = this;
	}
}
