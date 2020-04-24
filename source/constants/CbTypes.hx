package constants;

import nape.callbacks.CbType;

// Callback types
class CbTypes {
	public static var CB_SHIP_SENSOR_RANGE:CbType;
	public static var CB_CARGO:CbType;

	public static function initTypes() {
		CB_SHIP_SENSOR_RANGE = new CbType();
		CB_CARGO = new CbType();
	}
}
