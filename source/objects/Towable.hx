package objects;

import flixel.addons.nape.FlxNapeSprite;
import nape.constraint.DistanceJoint;

class Towable extends FlxNapeSprite {
	public var activeJoint:DistanceJoint;

	public function new() {
		super();
	}

	public function inTow(joint:DistanceJoint) {
		activeJoint = joint;
	}

	public function outOfTow() {
		activeJoint = null;
	}
}
