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
	public var worldPoint:Vec2;
	public var worldNormal:Vec2;

	public function new(b:Body, c:ContactBundle) {
		super(c.point.x, c.point.y, AssetPaths.angleDebug__png);
		body = b;
		contact = c;
		worldPoint = contact.point.copy().rotate(body.rotation).add(body.position);
		worldNormal = contact.normal.copy().rotate(body.rotation);

		// align our normal graphic
		angle = c.normal.angle * FlxAngle.TO_DEG;
		this.setMidpoint(c.point.x, c.point.y);
	}

	public function updateWorldPoint() {
		worldPoint.set(contact.point.copy().rotate(body.rotation).add(body.position));
	}

	public function updateWorldNormal() {
		worldNormal.set(contact.normal.copy().rotate(body.rotation));
	}

	public function copy():RopeContactPoint {
		return new RopeContactPoint(body, contact.copy());
	}
}
