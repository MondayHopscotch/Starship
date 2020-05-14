package geometry;

import nape.geom.Vec2;
import nape.shape.Shape;

class Shapes {
	public static function getCenter(s:Shape):Vec2 {
		var poly = s.castPolygon;
		var points = Vec2.get();
		for (vert in poly.localVerts) {
			points.addeq(vert);
		}
		return points.muleq(1 / poly.localVerts.length);
	}
}
