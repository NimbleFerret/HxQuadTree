import GameObject.GameObjectType;

class Shell extends GameObject {
	private final width = 5;
	private final height = 5;
	private final spawnTime:Float;
	private final s2d:h2d.Scene;

	public function new(id:String, parentTankId:String, s2d:h2d.Scene, x:Float, y:Float, r:Float) {
		super(id, GameObjectType.Shell, s2d, x, y, width, height, parentTankId);
		rotation = r;
		speed = 350;
		spawnTime = haxe.Timer.stamp();
		this.s2d = s2d;
	}

	public function init() {
		final bodyTile = h2d.Tile.fromColor(0xFFFF00, width, height, 1).center();
		final bodyBitmap = new h2d.Bitmap(bodyTile);

		addChild(bodyBitmap);
		addChild(hitBitmap);
	}

	public function delete() {
		removeChildren();
		s2d.removeChild(this);
	}

	public function customUpdate() {}
}
