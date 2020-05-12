package objects;

import nape.geom.Vec2;
import nape.phys.Body;

class RopeContactPoint {
	public var body:Body;
	public var point:Vec2;
	public var normal:Vec2;

	public function new(b:Body, p:Vec2, n:Vec2) {
		body = b;
		point = p;
		normal = n;
	}

	public function getWorldPoint():Vec2 {
		return point.copy().rotate(body.rotation).add(body.position);
	}

	public function getWorldNormal():Vec2 {
		return normal.copy().rotate(body.rotation);
	}

	public function copy():RopeContactPoint {
		return new RopeContactPoint(body, point.copy(), normal.copy());
	}
}
