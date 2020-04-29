package states;

import constants.CbTypes;
import constants.CollisionGroups;
import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.nape.FlxNapeSpace;
import flixel.addons.nape.FlxNapeSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;
import nape.dynamics.InteractionFilter;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Polygon;
import objects.Ship;
import objects.Wall;

class DestructableObjects extends FlxState {
	var ship:Ship;

	// Units: Pixels/sec/sec
	var gravity:Vec2 = Vec2.get().setxy(0, 200);

	override public function create() {
		CbTypes.initTypes();
		FlxNapeSpace.init();
		FlxNapeSpace.drawDebug = true;
		FlxNapeSpace.createWalls(0, 0, 0, 0);
		FlxNapeSpace.space.gravity.set(gravity);

		createTestObjs();
	}

	function createTestObjs() {
		ship = new Ship(300, 300);
		add(ship);

		var wall = new Wall(cast(FlxG.width * 0.75, Int));
		add(wall);
	}

	function createCargo(spriteName:FlxGraphicAsset, x:Int, y:Int, size:Float) {
		var cargo = new FlxNapeSprite();
		cargo.loadGraphic(spriteName);
		cargo.setPosition(x, y);
		cargo.scale.set(size / 3, size / 3);

		var cargoBody = new Body(BodyType.DYNAMIC);
		cargoBody.shapes.add(new Polygon(Polygon.rect(-size / 2, -size / 2, size, size)));
		cargoBody.mass *= 5;
		cargoBody.userData.data = cargo;
		cargoBody.cbTypes.add(CbTypes.CB_CARGO);

		var cargoFilter = new InteractionFilter(CollisionGroups.CARGO, ~(CollisionGroups.SHIP));
		cargoBody.setShapeFilters(cargoFilter);

		cargo.addPremadeBody(cargoBody);
		add(cargo);
	}

	function createBucket(spriteGfx:FlxGraphicAsset, x:Int, y:Int, width:Int, height:Int) {
		var wallThickness = 10;
		var left = new FlxNapeSprite();
		left.loadGraphic(spriteGfx);
		left.setPosition(x - width / 2 - wallThickness, y + height / 2);
		left.createRectangularBody(wallThickness, height);
		left.scale.set(wallThickness / 3, height / 3);
		left.body.type = BodyType.STATIC;
		add(left);

		var right = new FlxNapeSprite();
		right.loadGraphic(spriteGfx);
		right.setPosition(x + width / 2, y + height / 2);
		right.createRectangularBody(wallThickness, height);
		right.scale.set(wallThickness / 3, height / 3);
		right.body.type = BodyType.STATIC;
		add(right);

		var bottom = new FlxNapeSprite();
		bottom.loadGraphic(spriteGfx);
		bottom.setPosition(x, y + height);
		bottom.createRectangularBody(width, wallThickness);
		bottom.scale.set(width / 3, wallThickness / 3);
		bottom.body.type = BodyType.STATIC;
		add(bottom);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
	}
}
