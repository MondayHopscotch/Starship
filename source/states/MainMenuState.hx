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
		FlxG.debugger.visible = true;
		bgColor = FlxColor.TRANSPARENT;

		addButton(new FlxButton(0, 0, "Cargo", () -> FlxG.switchState(new CargoState())));
		addButton(new FlxButton(0, 0, "Walls", () -> FlxG.switchState(new DestructableObjects())));
		addButton(new FlxButton(0, 0, "Interactables", () -> FlxG.switchState(new InteractableEnvironment())));
		addButton(new FlxButton(0, 0, "Constraints", () -> FlxG.switchState(new ConstraintsTestState())));
	}

	function addButton(b:FlxButton) {
		b.updateHitbox();
		b.screenCenter();
		b.y += offset;
		offset += increment;
		add(b);
	}
}
