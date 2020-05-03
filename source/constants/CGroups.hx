package constants;

// CGroups are collision group flags
class CGroups {
	public static inline var TERRAIN:Int = 0x1 << 0;

	public static inline var SHIP:Int = 0x1 << 1;
	public static inline var SHIP_SENSOR:Int = 0x1 << 2;

	public static inline var CARGO:Int = 0x1 << 3;

	public static inline var HATCHES:Int = 0x1 << 4 | CARGO;

	public static inline var BOMBS:Int = 0x1 << 5;

	public static inline var TOWABLE:Int = 0x1 << 30;

	public static inline var OTHER_SENSOR:Int = 0x1 << 31;

	public static inline var TOW_COLLIDERS:Int = CARGO & HATCHES & TERRAIN;
	public static inline var ALL:Int = ~(0);
}
