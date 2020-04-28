package extensions;

import nape.geom.Vec2;
import nape.phys.Body;

class BodyExt {
	static public function getWorldPoint(b:Body, localPoint:Vec2):Vec2 {
		return localPoint.copy().rotate(b.rotation).add(b.position);
	}

	static public function getLocalPoint(b:Body, worldPoint:Vec2):Vec2 {
		return worldPoint.copy().sub(Vec2.weak().set(b.position)).rotate(-b.rotation);
	}
}
