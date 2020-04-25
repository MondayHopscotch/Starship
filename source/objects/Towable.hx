package objects;

import constants.CbTypes;
import constants.CollisionGroups;
import flixel.addons.nape.FlxNapeSprite;
import nape.constraint.DistanceJoint;
import nape.dynamics.InteractionFilter;

class Towable extends FlxNapeSprite {
	public var activeJoint:DistanceJoint;

	public function new() {
		super();
	}

	// Bakes the body and sets proper collision properties
	public function set() {
		body.setShapeFilters(new InteractionFilter(CollisionGroups.CARGO, ~(CollisionGroups.SHIP | CollisionGroups.TERRAIN)));
		body.cbTypes.add(CbTypes.CB_CARGO);
		body.allowRotation = false;
		body.userData.data = this;
	}

	public function inTow(joint:DistanceJoint) {
		activeJoint = joint;
	}

	public function outOfTow() {
		activeJoint = null;
	}
}
