package constants;

class CollisionGroups {
	public static inline var TERRAIN:Int = 0x1 << 0;

	public static inline var SHIP:Int = 0x1 << 1;
	public static inline var SHIP_SENSOR:Int = 0x1 << 2;

	public static inline var CARGO:Int = 0x1 << 3;

	public static inline var HATCHES:Int = 0x1 << 4 | CARGO;

	public static inline var TOW_COLLIDERS:Int = CARGO & HATCHES & TERRAIN;
	public static inline var ALL:Int = ~(0);
}
