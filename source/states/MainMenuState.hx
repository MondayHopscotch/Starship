package states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

class MainMenuState extends FlxState {
	var _btnPlay:FlxButton;
	var _btnWall:FlxButton;

	var offset:Int = -60;
	var increment:Int = 30;

	override public function create():Void {
		super.create();
		// FlxG.debugger.visible = true;
		bgColor = FlxColor.TRANSPARENT;

		addButton(new FlxButton(0, 0, "Cargo", () -> FlxG.switchState(new CargoState())));
		addButton(new FlxButton(0, 0, "Interactables", () -> FlxG.switchState(new InteractableEnvironment())));
		addButton(new FlxButton(0, 0, "Constraints", () -> FlxG.switchState(new ConstraintsTestState())));
		addButton(new FlxButton(0, 0, "Low Power", () -> FlxG.switchState(new LowPower())));
		addButton(new FlxButton(0, 0, "Rope Bend", () -> FlxG.switchState(new RopeBend())));
		addButton(new FlxButton(0, 0, "Rope Test", () -> FlxG.switchState(new RopeTestBed())));
		addButton(new FlxButton(0, 0, "Bombs", () -> FlxG.switchState(new Bombs())));
		addButton(new FlxButton(0, 0, "Terrain", () -> FlxG.switchState(new TerrainTest())));
		addButton(new FlxButton(0, 0, "Terrain Debug", () -> FlxG.switchState(new TerrainDebug())));
	}

	function addButton(b:FlxButton) {
		b.updateHitbox();
		b.screenCenter();
		b.y += offset;
		offset += increment;
		add(b);
	}
}
