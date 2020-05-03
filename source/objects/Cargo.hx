package objects;

import constants.CGroups;
import constants.CbTypes;
import flixel.system.FlxAssets.FlxGraphicAsset;
import nape.dynamics.InteractionFilter;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.MassMode;
import nape.phys.Material;
import nape.shape.Polygon;

class Cargo extends Towable {
	public static function create(spriteName:FlxGraphicAsset, x:Int, y:Int, size:Float, massScale:Float = 1):Cargo {
		var cargo = new Cargo();
		cargo.loadGraphic(spriteName);
		cargo.setPosition(x, y);
		cargo.scale.set(size / 3, size / 3);
		cargo.towMassScale = massScale;

		var cargoBody = new Body(BodyType.DYNAMIC);
		cargoBody.isBullet = true;
		cargoBody.shapes.add(new Polygon(Polygon.rect(-size / 2, -size / 2, size, size)));

		cargoBody.cbTypes.add(CbTypes.CB_CARGO);
		cargoBody.cbTypes.add(CbTypes.CB_TOWABLE);

		var cargoFilter = new InteractionFilter(CGroups.CARGO | CGroups.TOWABLE, ~(CGroups.SHIP));
		cargoBody.setShapeFilters(cargoFilter);

		cargo.addPremadeBody(cargoBody);
		for (shape in cargo.body.shapes) {
			shape.material = Material.wood();
		}
		return cargo;
	}

	override public function update(delta:Float) {
		super.update(delta);
		// allow some small spin to happen so it feels a little more natural
		if (Math.abs(body.angularVel) > 0.01) {
			body.angularVel *= .95;
		}
	}
}
