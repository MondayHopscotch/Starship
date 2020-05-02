package objects;

import constants.CGroups;
import constants.CbTypes;
import flixel.addons.nape.FlxNapeSpace;
import flixel.system.FlxAssets.FlxGraphicAsset;
import nape.callbacks.CbEvent;
import nape.callbacks.CbType;
import nape.callbacks.InteractionCallback;
import nape.callbacks.InteractionListener;
import nape.callbacks.InteractionType;
import nape.dynamics.InteractionFilter;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Circle;
import nape.shape.Polygon;

class Bomb extends Towable {
	public static function create(x:Int, y:Int, radius:Float):Bomb {
		var bomb = new Bomb();
		bomb.loadGraphic(AssetPaths.bomb__png);
		bomb.setPosition(x, y);
		bomb.scale.set(radius * 2 / 10, radius * 2 / 10);

		var bombBody = new Body(BodyType.DYNAMIC);
		bombBody.isBullet = true;
		// bombBody.shapes.add(new Polygon(Polygon.regular(size / 2, size / 2, 10)));
		bombBody.shapes.add(new Circle(radius));
		bombBody.mass *= 5;
		bombBody.userData.data = bomb;
		bombBody.cbTypes.add(CbTypes.CB_BOMB);
		bombBody.cbTypes.add(CbTypes.CB_TOWABLE);

		var bombFilter = new InteractionFilter(CGroups.BOMBS | CGroups.TOWABLE, ~(CGroups.SHIP));
		bombBody.setShapeFilters(bombFilter);

		bomb.addPremadeBody(bombBody);

		FlxNapeSpace.space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, CbTypes.CB_BOMB, CbTypes.CB_TERRAIN,
			bomb.checkExplode));

		return bomb;
	}

	function checkExplode(clbk:InteractionCallback) {
		trace(clbk.int1.cbTypes);
		trace(clbk.int2.cbTypes);

		if (clbk.int2.cbTypes.has(CbTypes.CB_BOMB)) {
			// we touched something bomb-proof
			trace("SAFE");
		} else {
			trace("BOOM");
			activeJoint.active = false;
			kill();
		}
	}
}
