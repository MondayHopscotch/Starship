package states;

import constants.CbTypes;
import constants.CollisionGroups;
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

class RopeTestBed extends FlxState {
	var rope:Rope;
	var cargo1:Cargo;
	var cargo2:Cargo;

	var hand:PivotJoint;
	var bodyList:BodyList = null;

	override public function create() {
		CbTypes.initTypes();
		FlxNapeSpace.init();
		FlxNapeSpace.drawDebug = true;
		FlxNapeSpace.createWalls(0, 0, 0, 0);

		hand = new PivotJoint(FlxNapeSpace.space.world, null, Vec2.weak(), Vec2.weak());
		hand.active = false;
		hand.stiff = false;
		hand.maxForce = 1e5;
		hand.space = FlxNapeSpace.space;

		createTestObjs();
	}

	function createTestObjs() {
		makeBlock(300, 300, 40, 40);

		cargo1 = Cargo.create(AssetPaths.debug_square_red__png, 50, 300, 20);
		cargo2 = Cargo.create(AssetPaths.debug_square_red__png, 300, 300, 20);
		add(cargo1);
		add(cargo2);

		rope = new Rope(cargo1, Vec2.get(), cargo2, Vec2.get(), Vec2.distance(cargo1.body.position, cargo2.body.position) + 1);
	}

	function makeBlock(x:Float, y:Float, width:Float, height:Float) {
		var testBlock = new FlxNapeSprite();
		testBlock.loadGraphic(AssetPaths.debug_square_blue__png);
		testBlock.setPosition(x, y);
		testBlock.createRectangularBody(width, height);
		testBlock.scale.set(width / 3, height / 3);
		testBlock.body.type = BodyType.STATIC;
		testBlock.body.setShapeFilters(new InteractionFilter(CollisionGroups.TERRAIN));
		add(testBlock);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

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
