package objects;

import constants.CGroups;
import constants.CbTypes;
import flixel.FlxG;
import flixel.addons.nape.FlxNapeSpace;
import flixel.addons.nape.FlxNapeSprite;
import nape.constraint.DistanceJoint;
import nape.dynamics.InteractionFilter;

class Towable extends SelfAssigningFlxNapeSprite {
	public var activeJoint:DistanceJoint;

	public function new() {
		super();
	}

	// Bakes the body and sets proper collision properties
	public function set() {
		body.setShapeFilters(new InteractionFilter(CGroups.CARGO, ~(CGroups.SHIP | CGroups.TERRAIN)));
		body.cbTypes.add(CbTypes.CB_CARGO);
		body.allowRotation = false;
		body.space = FlxNapeSpace.space;
	}

	public function inTow(joint:DistanceJoint) {
		FlxG.log.notice("Now towing: " + joint.body2);
		activeJoint = joint;
	}

	public function outOfTow() {
		FlxG.log.notice("Dropping tow");
		activeJoint = null;
	}
}
