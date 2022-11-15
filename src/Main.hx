class Main extends hxd.App {
	private var gameScene:GameScene;

	override function init() {
		gameScene = new GameScene(engine);
		setScene2D(gameScene);
	}

	override function update(dt:Float) {
		gameScene.update(dt);
	}

	static function main() {
		new Main();
	}
}
