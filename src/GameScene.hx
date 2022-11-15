import GameObject.GameObjectType;
import h3d.Engine;
import h2d.Scene;

class GameScene extends Scene {
	private final uiScene:UiScene;
	private final engine:Engine;

	private var graphics:h2d.Graphics;
	private var quadTree:QuadTree;
	private var lastMouseX:Float;
	private var lastMouseY:Float;
	private var tanksTotal = 0;
	private var shellsTotal = 0;
	private var shellsCounter = 0;

	private final cameraMoveSpeed = 50;
	private final cameraZoomStep = 0.1;
	private final minZoom = 0.5;
	private final maxZoom = 1;

	private final leftKeyCode = 37;
	private final upKeyCode = 38;
	private final rightKeyCode = 39;
	private final downKeyCode = 40;
	private final qKeyCode = 81;
	private final wKeyCode = 87;

	private final tankPairs = 20; // Pairs shoot each other
	private final tankFireRateSecond = 0.8; // 1 - one second, 0.5 - half second etc
	private final worldSize = 10000.0;

	private final tanks = new Map<String, Tank>();
	private final shells = new Map<String, Shell>();

	public function new(engine:Engine) {
		super();
		this.engine = engine;
		uiScene = new UiScene();

		quadTree = new QuadTree(worldSize / 2, worldSize / 2, worldSize);
		graphics = new h2d.Graphics(this);

		hxd.Window.getInstance().addEventTarget(onEvent);

		// Spawn tank pair that shoots each other
		for (i in 0...tankPairs) {
			final rnd = Std.int(worldSize) - 100;

			final x1 = Std.random(rnd);
			final y1 = Std.random(rnd);

			final tank1 = new Tank('Tank' + tanksTotal++, this, x1, y1, tankFireRateSecond);
			tanks.set(tank1.id, tank1);

			var x2 = Std.random(rnd);
			var y2 = Std.random(rnd);

			final tank2 = new Tank('Tank' + tanksTotal++, this, x2, y2, tankFireRateSecond);
			tank2.canShoot = true;
			tanks.set(tank2.id, tank2);

			if (tank1.outerRect.intersectsWithRect(tank2.outerRect)) {
				x2 = Std.random(rnd);
				y2 = Std.random(rnd);
				tank2.setPosition(x2, y2);
			}

			tank1.setTarget(tank2);
			tank2.setTarget(tank1);
		}
	}

	public function update(dt:Float) {
		// Clear graphic context and reset quadtree
		graphics.clear();
		quadTree.clear();

		for (tank in tanks) {
			// Draw tank shape rect
			drawDebugRect(tank.shapeRect, 0xEA8220);
			// Update tank position
			tank.update(dt);
			// Check tank rate of fire and fire shell
			final castedTank = cast(tank, Tank);
			if (castedTank.checkFire()) {
				final shell = new Shell('Shell' + shellsTotal++, castedTank.id, this, castedTank.x, castedTank.y, castedTank.turret.rotation);
				shells.set(shell.id, shell);
				shellsCounter++;
			}
			// Populate quadtree with tank
			quadTree.insertRect(tank);
		}

		final shellToDelete:Array<Shell> = new Array();

		for (shell in shells) {
			// Update shell position
			shell.update(dt);
			// Destroy shell if it goes outside ou bounds
			final castedShell = cast(shell, Shell);
			if (castedShell.x < 0 || castedShell.y < 0 || castedShell.x > worldSize || castedShell.y > worldSize) {
				shellToDelete.push(castedShell);
			} else {
				// Or populate quadtree with tank shell
				quadTree.insertRect(shell);
			}
		}

		// Calculate collisions
		final possibleCollisions = QuadTree.getPossibleCollisions(quadTree);
		if (possibleCollisions.length > 0) {
			for (value in possibleCollisions) {
				// TODO Precise check
				value[0].setIntersection();
				value[1].setIntersection();

				// Destroy shells
				if (value[0].gameObjectType == GameObjectType.Shell) {
					shellToDelete.push(cast(value[0], Shell));
				}
				if (value[1].gameObjectType == GameObjectType.Shell) {
					shellToDelete.push(cast(value[1], Shell));
				}
			}
		}

		// Destroy shells
		for (shell in shellToDelete) {
			shells.remove(shell.id);
			shell.visible = false;
			shell.delete();
			shellsCounter--;
		}

		// Draw full quadtree
		drawQuadTree(quadTree);

		// Highlight rect under mouse pos
		final qt = QuadTree.findRectByCoords(quadTree, lastMouseX, lastMouseY);
		if (qt != null) {
			drawDebugRect(qt.rect, 0x0000FF);
			for (value in qt.gameObjects) {
				value.setIntersection();
			}
		}

		uiScene.updateText(tanksTotal, shellsCounter, engine.fps);
	}

	private function onEvent(event:hxd.Event) {
		switch (event.kind) {
			case EKeyDown:
				// Move camera left
				if (event.keyCode == leftKeyCode) {
					camera.x -= cameraMoveSpeed;
				}
				// Move camera up
				if (event.keyCode == upKeyCode) {
					camera.y -= cameraMoveSpeed;
				}
				// Move camera right
				if (event.keyCode == rightKeyCode) {
					camera.x += cameraMoveSpeed;
				}
				// Move camera down
				if (event.keyCode == downKeyCode) {
					camera.y += cameraMoveSpeed;
				}
				// Zoom in camera
				if (event.keyCode == qKeyCode) {
					if (camera.scaleX + cameraZoomStep < maxZoom)
						camera.setScale(camera.scaleX + cameraZoomStep, camera.scaleY + cameraZoomStep);
				}
				// Zoom out camera
				if (event.keyCode == wKeyCode) {
					if (camera.scaleX - cameraZoomStep > minZoom)
						camera.setScale(camera.scaleX - cameraZoomStep, camera.scaleY - cameraZoomStep);
				}
			case _:
		}
	}

	private function drawQuadTree(quadTree:QuadTree) {
		// Draw quadtree shape
		drawDebugRect(new GameRect(quadTree.x, quadTree.y, quadTree.size, quadTree.size, 0), 0xFFFFFF);
		// Recursively draw each quadtree leaf
		if (quadTree.subdivided) {
			drawQuadTree(quadTree.nw);
			drawQuadTree(quadTree.ne);
			drawQuadTree(quadTree.sw);
			drawQuadTree(quadTree.se);
		}
	}

	private function drawDebugRect(rect:GameRect, c:Int) {
		graphics.lineStyle(3, c);
		// Top line
		graphics.lineTo(rect.getTopLeftPoint().x, rect.getTopLeftPoint().y);
		graphics.lineTo(rect.getTopRightPoint().x, rect.getTopRightPoint().y);
		// Right line
		graphics.lineTo(rect.getBottomRightPoint().x, rect.getBottomRightPoint().y);
		// Bottom line
		graphics.lineTo(rect.getBottomLeftPoint().x, rect.getBottomLeftPoint().y);
		// Left line
		graphics.lineTo(rect.getTopLeftPoint().x, rect.getTopLeftPoint().y);
	}

	public override function render(e:Engine) {
		super.render(e);
		uiScene.render(e);
	}
}
