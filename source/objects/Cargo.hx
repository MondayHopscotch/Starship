package objects;

import constants.CGroups;
import constants.CbTypes;
import flixel.system.FlxAssets.FlxGraphicAsset;
import nape.dynamics.InteractionFilter;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Polygon;

class Cargo extends Towable {
	public static function create(spriteName:FlxGraphicAsset, x:Int, y:Int, size:Float):Cargo {
		var cargo = new Cargo();
		cargo.loadGraphic(spriteName);
		cargo.setPosition(x, y);
		cargo.scale.set(size / 3, size / 3);

		var cargoBody = new Body(BodyType.DYNAMIC);
		cargoBody.isBullet = true;
		cargoBody.shapes.add(new Polygon(Polygon.rect(-size / 2, -size / 2, size, size)));
		cargoBody.mass *= 5;
		cargoBody.userData.data = cargo;
		cargoBody.cbTypes.add(CbTypes.CB_CARGO);
		cargoBody.cbTypes.add(CbTypes.CB_TOWABLE);

		var cargoFilter = new InteractionFilter(CGroups.CARGO | CGroups.TOWABLE, ~(CGroups.SHIP));
		cargoBody.setShapeFilters(cargoFilter);

		cargo.addPremadeBody(cargoBody);
		return cargo;
	}
}
