import GameObject.GameObjectType;

class Main extends hxd.App {
	private var graphics:h2d.Graphics;
	private var quadTree:QuadTree;
	private var lastMouseX:Float;
	private var lastMouseY:Float;
	private var tanksTotal = 0;
	private var shellsTotal = 0;
	private var shellsCounter = 0;

	private var tanksText:h2d.Text;
	private var shellsText:h2d.Text;
	private var fpsText:h2d.Text;
	private var calculationTimeText:h2d.Text;

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

	override function init() {
		tanksText = new h2d.Text(hxd.res.DefaultFont.get(), s2d);
		tanksText.setPosition(20, 20);
		tanksText.scale(5);

		shellsText = new h2d.Text(hxd.res.DefaultFont.get(), s2d);
		shellsText.setPosition(20, 90);
		shellsText.scale(5);

		fpsText = new h2d.Text(hxd.res.DefaultFont.get(), s2d);
		fpsText.setPosition(20, 160);
		fpsText.scale(5);

		calculationTimeText = new h2d.Text(hxd.res.DefaultFont.get(), s2d);
		calculationTimeText.setPosition(20, 240);
		calculationTimeText.scale(5);

		quadTree = new QuadTree(worldSize / 2, worldSize / 2, worldSize);
		graphics = new h2d.Graphics(s2d);

		hxd.Window.getInstance().addEventTarget(onEvent);

		// Spawn tank pair that shoots each other
		for (i in 0...tankPairs) {
			final rnd = Std.int(worldSize) - 100;

			final x1 = Std.random(rnd);
			final y1 = Std.random(rnd);

			final tank1 = new Tank('Tank' + tanksTotal++, s2d, x1, y1, tankFireRateSecond);
			tanks.set(tank1.id, tank1);

			var x2 = Std.random(rnd);
			var y2 = Std.random(rnd);

			final tank2 = new Tank('Tank' + tanksTotal++, s2d, x2, y2, tankFireRateSecond);
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

	function onEvent(event:hxd.Event) {
		switch (event.kind) {
			case EPush:
			// Spaw tank on left mouse click and pos
			// if (event.button == 0) {
			// 	final tank = new Tank('Tank' + tanksTotal++, s2d, event.relX, event.relY);
			// 	if (tanksTotal > 1) {
			// 		tank.canShoot = false;
			// 	}
			// 	tanks.set(tank.id, tank);
			// }
			case EMove:
			// Remember mouse pos for highlighting QuadTree rect
			// lastMouseX = event.relX;
			// lastMouseY = event.relY;
			case EKeyDown:
				// Move camera left
				if (event.keyCode == leftKeyCode) {
					s2d.camera.x -= cameraMoveSpeed;
				}
				// Move camera up
				if (event.keyCode == upKeyCode) {
					s2d.camera.y -= cameraMoveSpeed;
				}
				// Move camera right
				if (event.keyCode == rightKeyCode) {
					s2d.camera.x += cameraMoveSpeed;
				}
				// Move camera down
				if (event.keyCode == downKeyCode) {
					s2d.camera.y += cameraMoveSpeed;
				}
				// Zoom in camera
				if (event.keyCode == qKeyCode) {
					if (s2d.camera.scaleX + cameraZoomStep < maxZoom)
						s2d.camera.setScale(s2d.camera.scaleX + cameraZoomStep, s2d.camera.scaleY + cameraZoomStep);
				}
				// Zoom out camera
				if (event.keyCode == wKeyCode) {
					if (s2d.camera.scaleX - cameraZoomStep > minZoom)
						s2d.camera.setScale(s2d.camera.scaleX - cameraZoomStep, s2d.camera.scaleY - cameraZoomStep);
				}
			case _:
		}
	}

	override function update(dt:Float) {
		final updateBeginTime = haxe.Timer.stamp();

		// Clear graphic context and reset quadtree
		graphics.clear();
		quadTree.clear();

		for (tank in tanks) {
			// Draw tank outer rect
			// drawDebugRect(tank.outerRect, 0xEA8220);
			// Draw tank shape rect
			drawDebugRect(tank.shapeRect, 0xEA8220);
			// Update tank position
			tank.update(dt);
			// Check tank rate of fire and fire shell
			final castedTank = cast(tank, Tank);
			if (castedTank.checkFire()) {
				final shell = new Shell('Shell' + shellsTotal++, castedTank.id, s2d, castedTank.x, castedTank.y, castedTank.turret.rotation);
				shells.set(shell.id, shell);
				shellsCounter++;
			}
			// Populate quadtree with tank
			quadTree.insertRect(tank);
		}

		final shellToDelete:Array<Shell> = new Array();

		for (shell in shells) {
			// Draw tank outer rect
			// drawDebugRect(shell.outerRect, 0xEA8220);
			// Draw tank shape rect
			// drawDebugRect(shell.shapeRect, 0xEA8220);
			// Update tank position
			shell.update(dt);
			// Check if it is time to destroy shell by time
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

		// Non QuadTreeCollision
		// for (tank1 in tanks) {
		// 	// Tank to tank collision
		// 	for (tank2 in tanks) {
		// 		if (tank1.id != tank2.id) {
		// 			if (tank1.outerRect.intersectsWithRect(tank2.outerRect)) {
		// 				tank1.setIntersection();
		// 				tank2.setIntersection();
		// 			}
		// 		}
		// 	}
		// 	// Tank to shell collision
		// 	for (shell in shells) {
		// 		// Skip self shoot collision
		// 		if (shell.parentId != tank1.id) {
		// 			if (shell.outerRect.intersectsWithRect(tank1.outerRect)) {
		// 				tank1.setIntersection();
		// 				shellToDelete.push(cast(shell, Shell));
		// 			}
		// 		}
		// 	}
		// }

		// Destroy shells
		for (shell in shellToDelete) {
			shells.remove(shell.id);
			shell.visible = false;
			shell.delete();
			shellsCounter--;
		}

		// Draw full quadtree
		drawQuadTree(quadTree);

		final updateEndTime = haxe.Timer.stamp();

		tanksText.text = "Tanks: " + tanksTotal;
		shellsText.text = "Shells: " + shellsCounter;
		fpsText.text = "FPS: " + engine.fps;
		calculationTimeText.text = "Calculation time: " + (updateEndTime - updateBeginTime) * 1000;

		// Highlight rect under mouse pos
		// final qt = QuadTree.findRectByCoords(quadTree, lastMouseX, lastMouseY);
		// if (qt != null) {
		// 	drawDebugRect(qt.rect, 0x0000FF);
		// 	for (value in qt.gameObjects) {
		// 		value.setIntersection();
		// 	}
		// }
	}

	function drawQuadTree(quadTree:QuadTree) {
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

	function drawDebugRect(rect:GameRect, c:Int) {
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

	static function main() {
		new Main();
	}
}
