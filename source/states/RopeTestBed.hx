package states;

import constants.CGroups;
import constants.CbTypes;
import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.nape.FlxNapeSpace;
import flixel.addons.nape.FlxNapeSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;
import geometry.ContactBundle;
import nape.constraint.PivotJoint;
import nape.dynamics.InteractionFilter;
import nape.geom.AABB;
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
import physics.Terrain;

class RopeTestBed extends BackableState {
	var rope:Rope;
	var cargo1:Cargo;
	var cargo2:Cargo;

	var c1Contact:ContactBundle;
	var c2Contact:ContactBundle;

	var hand:PivotJoint;
	var bodyList:BodyList = null;

	override public function create() {
		super.create();
		FlxNapeSpace.createWalls(0, 0, 0, 0);

		hand = new PivotJoint(FlxNapeSpace.space.world, null, Vec2.weak(), Vec2.weak());
		hand.active = false;
		hand.stiff = false;
		hand.maxForce = 1e5;
		hand.space = FlxNapeSpace.space;

		createTestObjs();
	}

	function createTestObjs() {
		// add(Creators.makeBlock(300, 300, 40, 40));
		// add(Creators.makeBlock(400, 350, 40, 40));
		// var shapeTest = Creators.makeShape(400, 350, 40, 40, 5);
		// shapeTest.body.space = null;
		// for (s in shapeTest.body.shapes) {
		// 	for (vert in s.castPolygon.localVerts) {
		// 		vert.x += 30;
		// 	}
		// }
		// shapeTest.body.space = FlxNapeSpace.space;
		// add(shapeTest);

		cargo1 = Cargo.create(AssetPaths.debug_square_red__png, 50, 250, 25);
		cargo2 = Cargo.create(AssetPaths.debug_square_red__png, 300, 250, 25);
		add(cargo1);
		add(cargo2);

		FlxG.bitmap.add(AssetPaths.testLevel__png, true, "terrainTest");
		var gfx = FlxG.bitmap.get("terrainTest");

		var terrain = new Terrain(gfx.bitmap, 30, 5);
		terrain.invalidate(new AABB(0, 0, gfx.width, gfx.height), FlxNapeSpace.space);

		rope = new Rope();
		c1Contact = new ContactBundle(Vec2.get(), Vec2.get(), Vec2.get());
		c2Contact = new ContactBundle(Vec2.get(12.5, 12.5), Vec2.get(12.5, 12.5).normalise(), Vec2.get());

		FlxG.camera.follow(cargo1);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.keys.justPressed.SPACE) {
			FlxG.camera.zoom += 1;
		}

		if (FlxG.keys.justPressed.X) {
			FlxG.camera.zoom -= 1;
		}

		if (FlxG.mouse.justPressedRight) {
			trace(Vec2.get(FlxG.mouse.x, FlxG.mouse.y));
			trace(FlxNapeSpace.space.bodiesUnderPoint(Vec2.get(FlxG.mouse.x, FlxG.mouse.y), null));
		}

		if (FlxG.keys.justPressed.R) {
			if (rope.isAttached()) {
				rope.detach();
			} else {
				rope.attach(cargo1, c1Contact, cargo2, c2Contact, Vec2.distance(cargo1.body.position, cargo2.body.position) + 1);
			}
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
