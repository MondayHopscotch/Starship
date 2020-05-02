package constants;

import nape.callbacks.CbType;

// Callback types
class CbTypes {
	public static var CB_BOMB:CbType;
	public static var CB_CARGO:CbType;
	public static var CB_SHIP_SENSOR_RANGE:CbType;
	public static var CB_TERRAIN:CbType;
	public static var CB_TOWABLE:CbType;

	public static function initTypes() {
		CB_BOMB = new CbType();
		trace("CB_BOMB is " + CB_BOMB);
		CB_CARGO = new CbType();
		trace("CB_CARGO is " + CB_CARGO);
		CB_SHIP_SENSOR_RANGE = new CbType();
		trace("CB_SHIP_SENSOR_RANGE is " + CB_SHIP_SENSOR_RANGE);
		CB_TERRAIN = new CbType();
		trace("CB_TERRAIN is " + CB_TERRAIN);
		CB_TOWABLE = new CbType();
		trace("CB_TOWABLE is " + CB_TOWABLE);
	}
}
