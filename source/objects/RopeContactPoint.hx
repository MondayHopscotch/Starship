package objects;

import flixel.FlxSprite;
import flixel.math.FlxAngle;
import geometry.ContactBundle;
import nape.geom.Vec2;
import nape.phys.Body;

using extensions.FlxObjectExt;

class RopeContactPoint extends FlxSprite {
	public var body:Body;
	public var contact:ContactBundle;

	public function new(b:Body, c:ContactBundle) {
		super(c.point.x, c.point.y, AssetPaths.angleDebug__png);
		body = b;
		contact = c;
		angle = c.normal.angle * FlxAngle.TO_DEG;
		this.setMidpoint(c.point.x, c.point.y);
	}

	public function getWorldPoint():Vec2 {
		return contact.point.copy().rotate(body.rotation).add(body.position);
	}

	public function getWorldNormal():Vec2 {
		return contact.normal.copy().rotate(body.rotation);
	}

	public function copy():RopeContactPoint {
		return new RopeContactPoint(body, contact.copy());
	}
}
