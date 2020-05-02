package states;

import constants.CGroups;
import constants.CbTypes;
import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.nape.FlxNapeSpace;
import flixel.addons.nape.FlxNapeSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;
import nape.constraint.PivotJoint;
import nape.dynamics.InteractionFilter;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyList;
import nape.phys.BodyType;
import nape.shape.Polygon;
import objects.Cargo;
import objects.Rope;
import objects.Ship;
import objects.SwitchWall;
import objects.Wall;
import physics.Creators;

class RopeTestBed extends BackableState {
	var rope:Rope;
	var cargo1:Cargo;
	var cargo2:Cargo;

	var hand:PivotJoint;
	var bodyList:BodyList = null;

	override public function create() {
		super.create();
		CbTypes.initTypes();
		FlxNapeSpace.init();
		FlxNapeSpace.drawDebug = true;
		FlxNapeSpace.createWalls(0, 0, 0, 0);
		// FlxNapeSpace.space.gravity.setxy(0, 200);

		hand = new PivotJoint(FlxNapeSpace.space.world, null, Vec2.weak(), Vec2.weak());
		hand.active = false;
		hand.stiff = false;
		hand.maxForce = 1e5;
		hand.space = FlxNapeSpace.space;

		createTestObjs();
	}

	function createTestObjs() {
		add(Creators.makeBlock(300, 300, 40, 40));
		add(Creators.makeBlock(400, 350, 40, 40));

		cargo1 = Cargo.create(AssetPaths.debug_square_red__png, 50, 300, 25);
		cargo2 = Cargo.create(AssetPaths.debug_square_red__png, 300, 300, 25);
		add(cargo1);
		add(cargo2);

		rope = new Rope();
		rope.attach(cargo1, Vec2.get(), cargo2, Vec2.get(12.5, 12.5), Vec2.distance(cargo1.body.position, cargo2.body.position) + 1);
		// rope.attach(cargo1, Vec2.get(), cargo2, Vec2.get(), Vec2.distance(cargo1.body.position, cargo2.body.position) + 1);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.mouse.justPressedRight) {
			trace(Vec2.get(FlxG.mouse.x, FlxG.mouse.y));
			trace(FlxNapeSpace.space.bodiesUnderPoint(Vec2.get(FlxG.mouse.x, FlxG.mouse.y), null));
		}

		if (FlxG.mouse.justPressed) {
			mouseDown();
		} else if (FlxG.mouse.justReleased) {
			hand.active = false;
		}
		if (hand.active) {
			hand.anchor1.setxy(FlxG.mouse.x, FlxG.mouse.y);
			hand.body2.angularVel *= 0.9;
		}

		cargo1.body.velocity.setxy(0, 0);
		cargo2.body.velocity.setxy(0, 0);
		rope.update(elapsed);
	}

	function mouseDown() {
		var mp = Vec2.get(FlxG.mouse.x, FlxG.mouse.y);
		// re-use the same list each time.
		bodyList = FlxNapeSpace.space.bodiesUnderPoint(mp, null, bodyList);

		for (body in bodyList) {
			if (!body.isStatic()) {
				hand.body2 = body;
				hand.anchor2 = body.worldPointToLocal(mp, true);
				hand.active = true;
				break;
			}
		}

		// recycle nodes.
		bodyList.clear();

		mp.dispose();
	}
}
