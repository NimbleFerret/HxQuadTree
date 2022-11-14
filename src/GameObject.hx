enum GameObjectType {
	Tank;
	Shell;
}

abstract class GameObject extends h2d.Object {
	public final outerRect:GameRect;
	public final shapeRect:GameRect;
	public final gameObjectType:GameObjectType;
	public final id:String;
	public final parentId:String;

	private final hitBitmap:h2d.Bitmap;

	var speed = 0;
	var intersects = false;

	public function new(id:String, gameObjectType:GameObjectType, s2d:h2d.Scene, x:Float, y:Float, w:Float, h:Float, ?parentId:String) {
		super(s2d);

		this.id = id;
		this.parentId = parentId;
		this.gameObjectType = gameObjectType;

		final hitTile = h2d.Tile.fromColor(0xFF0000, Std.int(w), Std.int(h), 0.5).center();
		hitBitmap = new h2d.Bitmap(hitTile);

		init();
		addChild(hitBitmap);
		setPosition(x, y);

		final biggestSide = w > h ? w : h;
		outerRect = new GameRect(this.x, this.y, biggestSide * 1.5, biggestSide * 1.5, 0);
		shapeRect = new GameRect(this.x, this.y, w, h, 0);
	}

	public function update(dt:Float) {
		// rotation += MathUtils.degreeToRads(10 * dt);

		customUpdate();

		final dx = speed * dt * Math.cos(rotation);
		final dy = speed * dt * Math.sin(rotation);
		x += dx;
		y += dy;

		outerRect.updatePosition(x, y, 0);
		shapeRect.updatePosition(x, y, rotation);

		hitBitmap.visible = intersects;
		intersects = false;
	}

	public function setIntersection() {
		intersects = true;
	}

	abstract public function init():Void;

	abstract public function customUpdate():Void;
}
