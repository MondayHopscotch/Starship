package objects;

import flixel.FlxBasic;
import geometry.ContactBundle;
import nape.geom.Vec2;
import nape.phys.Body;

using extensions.BodyExt;

class RopeSegment extends FlxBasic {
	public var contact1:RopeContactPoint;
	public var contact2:RopeContactPoint;

	private var center:Vec2 = Vec2.get();
	private var lastCenter:Vec2 = Vec2.get();

	public static function fromContacts(s:RopeContactPoint, e:RopeContactPoint):RopeSegment {
		return new RopeSegment(s.body, s.contact.copy(), e.body, e.contact.copy());
	}

	public function new(b1:Body, c1:ContactBundle, b2:Body, c2:ContactBundle) {
		super();
		contact1 = new RopeContactPoint(b1, c1);
		contact2 = new RopeContactPoint(b2, c2);
	}

	public function length():Float {
		return Vec2.distance(contact1.worldPoint, contact2.worldPoint);
	}

	override public function update(delta:Float) {
		super.update(delta);
		contact1.updateWorldPoint();
		contact1.updateWorldNormal();
		contact2.updateWorldPoint();
		contact2.updateWorldNormal();

		lastCenter.set(center);
		center.set(contact2.worldPoint).addeq(contact1.worldPoint).muleq(0.5);
	}

	public function delta():Vec2 {
		return center.sub(lastCenter);
	}
}
