import GameObject.GameObjectType;

class QuadTree {
	public var gameObjects:Array<GameObject> = new Array();
	public var subdivided = false;

	public var nw:QuadTree;
	public var ne:QuadTree;
	public var sw:QuadTree;
	public var se:QuadTree;

	public var x:Float;
	public var y:Float;
	public var size:Float;

	public final rect:GameRect;

	private final capacity = 4;
	private final minQuadSize = 125;

	public function new(x:Float, y:Float, size:Float) {
		this.x = x;
		this.y = y;
		this.size = size;

		rect = new GameRect(x, y, size, size, 0);
	}

	public function clear() {
		gameObjects = new Array();
		if (subdivided) {
			subdivided = false;
			nw.clear();
			ne.clear();
			sw.clear();
			se.clear();
		}
	}

	// Goal of this func is to return each leaf that has at least 2 objects that may collide
	public static function getPossibleCollisions(qt:QuadTree) {
		final likelyCollidedObjects = new Array<Array<GameObject>>();

		function getPossibleCollisionsInsideQuadTree(qtLeaf:QuadTree) {
			if (qtLeaf.subdivided) {
				if (qtLeaf.nw.gameObjects.length > 1) {
					getPossibleCollisionsInsideQuadTree(qtLeaf.nw);
				}
				if (qtLeaf.ne.gameObjects.length > 1) {
					getPossibleCollisionsInsideQuadTree(qtLeaf.ne);
				}
				if (qtLeaf.sw.gameObjects.length > 1) {
					getPossibleCollisionsInsideQuadTree(qtLeaf.sw);
				}
				if (qtLeaf.se.gameObjects.length > 1) {
					getPossibleCollisionsInsideQuadTree(qtLeaf.se);
				}
			} else {
				final checkedObjects = new Array<String>();
				for (gameObject1 in qtLeaf.gameObjects) {
					for (gameObject2 in qtLeaf.gameObjects) {
						// Skip self collision and non unique collisions
						final uniqueCollision = gameObject1.id + gameObject2.id;
						final uniqueCollisionReversed = gameObject2.id + gameObject1.id;
						if (gameObject1.id != gameObject2.id
							&& !checkedObjects.contains(uniqueCollision)
							&& !checkedObjects.contains(uniqueCollisionReversed)) {
							checkedObjects.push(uniqueCollision);
							checkedObjects.push(uniqueCollisionReversed);

							// Skip shell to shell collision
							final bothShells = gameObject1.gameObjectType == GameObjectType.Shell
								&& gameObject2.gameObjectType == GameObjectType.Shell;
							if (!bothShells) {
								// Skip own shells collisions
								if (gameObject1.gameObjectType == GameObjectType.Tank
									&& gameObject2.gameObjectType == GameObjectType.Shell
									&& gameObject2.parentId == gameObject1.id
									|| gameObject2.gameObjectType == GameObjectType.Tank
									&& gameObject1.gameObjectType == GameObjectType.Shell
									&& gameObject1.parentId == gameObject2.id) {
									continue;
								}
								// This is possible tank/tank or tank/shell collision
								// Collides if both outer rects intersects
								if (gameObject1.outerRect.intersectsWithRect(gameObject2.outerRect)) {
									likelyCollidedObjects.push([gameObject1, gameObject2]);
								}
							}
						}
					}
				}
			}
		}

		getPossibleCollisionsInsideQuadTree(qt);

		return likelyCollidedObjects;
	}

	public static function findRectByCoords(qt:QuadTree, x:Float, y:Float) {
		if (qt.rect.containsPoint(x, y)) {
			if (qt.subdivided) {
				if (qt.nw.rect.containsPoint(x, y)) {
					return findRectByCoords(qt.nw, x, y);
				} else if (qt.ne.rect.containsPoint(x, y)) {
					return findRectByCoords(qt.ne, x, y);
				} else if (qt.sw.rect.containsPoint(x, y)) {
					return findRectByCoords(qt.sw, x, y);
				} else if (qt.se.rect.containsPoint(x, y)) {
					return findRectByCoords(qt.se, x, y);
				} else {
					return null;
				}
			} else {
				return qt;
			}
		} else {
			return null;
		}
	}

	public function insertRect(gameObject:GameObject) {
		function insertSubdivided(value:GameObject) {
			if (nw.containsRect(value.outerRect)) {
				nw.insertRect(value);
			}
			if (ne.containsRect(value.outerRect)) {
				ne.insertRect(value);
			}
			if (sw.containsRect(value.outerRect)) {
				sw.insertRect(value);
			}
			if (se.containsRect(value.outerRect)) {
				se.insertRect(value);
			}
		}

		if (containsRect(gameObject.outerRect)) {
			if (!subdivided) {
				gameObjects.push(gameObject);
				final halfSize:Float = size / 2;

				if (gameObjects.length + 1 > capacity && halfSize > minQuadSize) {
					subdivided = true;

					final quarterSize:Float = size / 4;
					final qtX = x - quarterSize;
					final qtY = y - quarterSize;
					final nwX = qtX;
					final nwY = qtY;
					final neX = qtX + halfSize;
					final neY = qtY;
					final swX = qtX;
					final swY = qtY + halfSize;
					final seX = qtX + halfSize;
					final seY = qtY + halfSize;

					nw = new QuadTree(nwX, nwY, halfSize);
					ne = new QuadTree(neX, neY, halfSize);
					sw = new QuadTree(swX, swY, halfSize);
					se = new QuadTree(seX, seY, halfSize);

					for (value in gameObjects) {
						insertSubdivided(value);
					}
				}
			} else {
				insertSubdivided(gameObject);
			}
		}
	}

	private function name() {}

	private function containsRect(rect:GameRect) {
		return new GameRect(x, y, size, size, 0).intersectsWithRect(rect);
	}
}
