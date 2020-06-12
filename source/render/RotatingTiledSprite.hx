package render;

import flixel.addons.display.FlxTiledSprite;
import flixel.math.FlxPoint;
import flixel.math.FlxVector;

class RotatingTiledSprite extends FlxTiledSprite {
	var pivotPoint = FlxPoint.get();
	var ref = FlxVector.get();

	override public function updateVerticesData() {
		super.updateVerticesData();
		pivotPoint.set(width / 2, height / 2);

		for (i in 1...vertices.length) {
			if (i % 2 == 0) {
				// we only want to look at every other point
				continue;
			}
			ref.set(vertices[i - 1], vertices[i]);
			ref.rotate(pivotPoint, angle);
			vertices[i - 1] = ref.x;
			vertices[i] = ref.y;
		}
	}
}
