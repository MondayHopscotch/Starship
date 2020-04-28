package input;

import flixel.FlxG;
import flixel.input.actions.FlxAction.FlxActionAnalog;
import flixel.input.actions.FlxAction.FlxActionDigital;
import flixel.input.actions.FlxActionManager;

class BasicControls {
	static var actions:FlxActionManager;

	public var thruster:FlxActionAnalog;
	public var steer:FlxActionAnalog;
	public var grappleAdjust:FlxActionAnalog;
	public var toggleGrapple:FlxActionDigital;

	public var pause:FlxActionDigital;

	public function new() {
		thruster = new FlxActionAnalog("thruster");
		steer = new FlxActionAnalog("steer");
		grappleAdjust = new FlxActionAnalog("grappleAdjust");
		toggleGrapple = new FlxActionDigital("toggleGrapple");
		pause = new FlxActionDigital("pause");

		if (actions == null) {
			actions = FlxG.inputs.add(new FlxActionManager());
		}
		actions.addActions([thruster, steer, grappleAdjust, toggleGrapple]);

		// thruster.addKey(FlxKey.SPACE, JUST_PRESSED);
		toggleGrapple.addKey(E, JUST_PRESSED);

		updateGamepadInput();
	}

	function updateGamepadInput() {
		thruster.addGamepad(RIGHT_TRIGGER, MOVED);
		steer.addGamepad(LEFT_ANALOG_STICK, MOVED);
		grappleAdjust.addGamepad(RIGHT_ANALOG_STICK, MOVED);
		toggleGrapple.addGamepad(B, JUST_PRESSED);
		pause.addGamepad(LEFT_SHOULDER, JUST_PRESSED);
	}
}
