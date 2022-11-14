import GameObject.GameObjectType;
import h2d.Scene;

class Turret extends h2d.Object {
	public function new(parent:h2d.Object) {
		super(parent);

		final turrentTile = h2d.Tile.fromColor(0x127022, 30, 30, 1).center();
		final turretBitmap = new h2d.Bitmap(turrentTile);

		final barrelTile = h2d.Tile.fromColor(0x127022, 45, 5, 1).center();
		final barrelBitmap = new h2d.Bitmap(barrelTile);

		barrelBitmap.setPosition(37.5, 0);

		addChild(turretBitmap);
		addChild(barrelBitmap);
	}
}

class Tank extends GameObject {
	private final width = 90;
	private final height = 50;
	private final fireRate:Float;
	// private final fireDelayMS = Std.random(5) + 1;
	private var lastFireTime = 0.0;
	private var target:Tank;

	public var turret:Turret;
	public var canShoot = true;

	public function new(id:String, s2d:h2d.Scene, x:Float, y:Float, fireRate:Float) {
		super(id, GameObjectType.Tank, s2d, x, y, width, height);
		this.fireRate = fireRate;
	}

	public function setTarget(target:Tank) {
		this.target = target;
	}

	public function checkFire() {
		final now = haxe.Timer.stamp();
		if (canShoot && (lastFireTime == 0 || lastFireTime + fireRate < now)) {
			lastFireTime = now;
			return true;
		} else {
			return false;
		}
	}

	public function init() {
		final bodyTile = h2d.Tile.fromColor(0x14491D, width, height, 1).center();
		final bodyBitmap = new h2d.Bitmap(bodyTile);

		addChild(bodyBitmap);

		turret = new Turret(this);
	}

	public function customUpdate() {
		if (target != null) {
			final angleInRadians = MathUtils.angleBetween(x, y, target.x, target.y);
			turret.rotation = angleInRadians;
		}
	}
}
