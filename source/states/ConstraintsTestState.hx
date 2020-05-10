package states;

import constants.CGroups;
import constants.CbTypes;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.nape.FlxNapeSpace;
import flixel.addons.nape.FlxNapeSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;
import nape.constraint.AngleJoint;
import nape.constraint.Constraint;
import nape.constraint.ConstraintList;
import nape.constraint.DistanceJoint;
import nape.constraint.LineJoint;
import nape.constraint.MotorJoint;
import nape.constraint.PivotJoint;
import nape.constraint.PulleyJoint;
import nape.constraint.WeldJoint;
import nape.dynamics.InteractionFilter;
import nape.geom.Vec2;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.Body;
import nape.phys.BodyList;
import nape.phys.BodyType;
import nape.phys.BodyType;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.shape.Polygon;
import objects.Ship;

// Template class is used so that this sample may
// be as concise as possible in showing Nape features without
// any of the boilerplate that makes up the sample interfaces.
class ConstraintsTestState extends BackableState {
	// Cell sizes
	static inline var cellWcnt = 3;
	static inline var cellHcnt = 3;
	static inline var cellWidth = 640 / cellWcnt;
	static inline var cellHeight = 480 / cellHcnt;
	static inline var size = 22;

	// Constraint settings.
	var frequency:Float = 20.0;
	var damping:Float = 1.0;

	var hand:PivotJoint;

	override public function create() {
		super.create();
		FlxNapeSpace.createWalls(0, 0, 0, 0);

		var w = FlxG.width;
		var h = FlxG.height;

		// Create regions for each constraint demo
		var regions = new Body(BodyType.STATIC);
		for (i in 1...cellWcnt) {
			regions.shapes.add(new Polygon(Polygon.rect(i * cellWidth - 0.5, 0, 1, h)));
		}
		for (i in 1...cellHcnt) {
			regions.shapes.add(new Polygon(Polygon.rect(0, i * cellHeight - 0.5, w, 1)));
		}
		regions.space = FlxNapeSpace.space;

		createTestObjs();

		createHand();
	}

	function createHand() {
		hand = new PivotJoint(FlxNapeSpace.space.world, null, Vec2.weak(), Vec2.weak());
		hand.active = false;
		hand.stiff = false;
		hand.maxForce = 1e5;
		hand.space = FlxNapeSpace.space;
	}

	function createTestObjs() {
		withCell(1, 0, "PivotJoint", function(x, y) {
			var b1 = box(x(1 * cellWidth / 3), y(cellHeight / 2), size, BodyType.DYNAMIC);
			var b2 = box(x(2 * cellWidth / 3), y(cellHeight / 2), size, BodyType.DYNAMIC);

			var pivotPoint = Vec2.get(x(cellWidth / 2), y(cellHeight / 2));
			format(new PivotJoint(b1, b2, b1.worldPointToLocal(pivotPoint, true), b2.worldPointToLocal(pivotPoint, true)));
			pivotPoint.dispose();
		});

		withCell(2, 0, "WeldJoint", function(x, y) {
			var b1 = box(x(1 * cellWidth / 3), y(cellHeight / 2), size, BodyType.DYNAMIC);
			var b2 = box(x(2 * cellWidth / 3), y(cellHeight / 2), size, BodyType.DYNAMIC);

			var weldPoint = Vec2.get(x(cellWidth / 2), y(cellHeight / 2));
			format(new WeldJoint(b1, b2, b1.worldPointToLocal(weldPoint, true), b2.worldPointToLocal(weldPoint, true), /*phase*/ Math.PI / 4 /*45 degrees*/));
			weldPoint.dispose();
		});

		withCell(0, 1, "DistanceJoint", function(x, y) {
			var b1 = box(x(1.25 * cellWidth / 3), y(cellHeight / 2), size, BodyType.DYNAMIC);
			var b2 = box(x(1.75 * cellWidth / 3), y(cellHeight / 2), size, BodyType.DYNAMIC);

			format(new DistanceJoint(b1, b2, Vec2.weak(0, -size), Vec2.weak(0, -size), /*jointMin*/ cellWidth / 3 * 0.75, /*jointMax*/ cellWidth / 3 * 1.25));
		});

		withCell(1, 1, "LineJoint", function(x, y) {
			var b1 = box(x(1 * cellWidth / 3), y(cellHeight / 2), size, BodyType.DYNAMIC);
			var b2 = box(x(2 * cellWidth / 3), y(cellHeight / 2), size, BodyType.DYNAMIC);

			var anchorPoint = Vec2.get(x(cellWidth / 2), y(cellHeight / 2));
			format(new LineJoint(b1, b2, b1.worldPointToLocal(anchorPoint, true), b2.worldPointToLocal(anchorPoint, true), /*direction*/ Vec2.weak(0, 1),
				/*jointMin*/ - size, /*jointMax*/ size));
			anchorPoint.dispose();
		});

		withCell(2, 1, "PulleyJoint", function(x, y) {
			var b1 = box(x(cellWidth / 2), y(size), size / 2, BodyType.DYNAMIC, true);
			b1.scaleShapes(4, 1);

			var b2 = box(x(1 * cellWidth / 3), y(cellHeight / 2), size / 2, BodyType.DYNAMIC);
			var b3 = box(x(2 * cellWidth / 3), y(cellHeight / 2), size, BodyType.DYNAMIC);

			format(new PulleyJoint(b1, b2, b1, b3, Vec2.weak(-size * 2, 0), Vec2.weak(0, -size / 2), Vec2.weak(size * 2, 0), Vec2.weak(0, -size), /*jointMin*/
				cellHeight * 0.75, /*jointMax*/ cellHeight * 0.75, /*ratio*/ 2.5));
		});

		withCell(0, 2, "AngleJoint", function(x, y) {
			var b1 = box(x(1 * cellWidth / 3), y(cellHeight / 2), size, BodyType.DYNAMIC, true);
			var b2 = box(x(2 * cellWidth / 3), y(cellHeight / 2), size, BodyType.DYNAMIC, true);

			format(new AngleJoint(b1, b2, /*jointMin*/ - Math.PI * 1.5, /*jointMax*/ Math.PI * 1.5, /*ratio*/ 2));
		});

		withCell(1, 2, "MotorJoint", function(x, y) {
			var b1 = box(x(1 * cellWidth / 3), y(cellHeight / 2), size, BodyType.DYNAMIC, true);
			var b2 = box(x(2 * cellWidth / 3), y(cellHeight / 2), size, BodyType.DYNAMIC, true);
			var b3 = box(x(cellWidth / 2), y(cellHeight / 2), size, BodyType.KINEMATIC, false);
			b3.shapes.at(0).sensorEnabled = true;

			var pivotPoint = Vec2.get(x(cellWidth / 2), y(cellHeight / 2 + 20));
			format(new PivotJoint(b1, b3, b1.worldPointToLocal(pivotPoint, true), b3.worldPointToLocal(pivotPoint, true)));
			format(new PivotJoint(b2, b3, b2.worldPointToLocal(pivotPoint, true), b3.worldPointToLocal(pivotPoint, true)));

			var worldPivot = Vec2.get(x(cellWidth / 2), y(cellHeight / 2 - 20));
			rise(cast(format(new PivotJoint(FlxNapeSpace.space.world, b3, worldPivot, b3.worldPointToLocal(worldPivot, true))), PivotJoint));
			pivotPoint.dispose();
			worldPivot.dispose();

			// format(new MotorJoint(b1, b2, /*rate*/ 10, /*ratio*/ 3));
		});
	}

	// Environment for each cell.
	function withCell(i:Int, j:Int, title:String, f:(Float->Float)->(Float->Float)->Void) {
		f(function(x:Float) return x + (i * cellWidth), function(y:Float) return y + (j * cellHeight));
	}

	// Box utility.
	function box(x:Float, y:Float, radius:Float, type:BodyType, pinned:Bool = false) {
		var body = new Body();
		body.position.setxy(x, y);
		body.shapes.add(new Polygon(Polygon.box(radius * 2, radius * 2)));
		body.space = FlxNapeSpace.space;
		if (pinned) {
			var pin = new PivotJoint(FlxNapeSpace.space.world, body, body.position, Vec2.weak(0, 0));
			pin.space = FlxNapeSpace.space;
		}
		return body;
	}

	function format(c:Constraint):Constraint {
		c.stiff = false;
		c.frequency = frequency;
		c.damping = damping;
		c.space = FlxNapeSpace.space;
		return c;
	}

	var bodyList:BodyList = null;

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

	var constraints:ConstraintList = ConstraintList.fromArray([]);

	function rise(c:PivotJoint) {
		constraints.add(c);
	}

	override public function update(delta:Float) {
		if (FlxG.mouse.justPressed) {
			mouseDown();
		} else if (FlxG.mouse.justReleased) {
			hand.active = false;
		}

		if (hand.active) {
			hand.anchor1.setxy(FlxG.mouse.x, FlxG.mouse.y);
			hand.body2.angularVel *= 0.9;
		}
		constraints.foreach(c -> cast(c, PivotJoint).anchor1.y -= 10 * delta);
	}
}
