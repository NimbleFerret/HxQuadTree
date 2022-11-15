import h2d.Scene;

class UiScene extends Scene {
	private var tanksText:h2d.Text;
	private var shellsText:h2d.Text;
	private var fpsText:h2d.Text;
	private var inputText:h2d.Text;

	public function new() {
		super();

		tanksText = new h2d.Text(hxd.res.DefaultFont.get(), this);
		tanksText.setPosition(20, 20);
		tanksText.scale(5);

		shellsText = new h2d.Text(hxd.res.DefaultFont.get(), this);
		shellsText.setPosition(20, 90);
		shellsText.scale(5);

		fpsText = new h2d.Text(hxd.res.DefaultFont.get(), this);
		fpsText.setPosition(20, 160);
		fpsText.scale(5);

		inputText = new h2d.Text(hxd.res.DefaultFont.get(), this);
		inputText.setPosition(20, 240);
		inputText.scale(5);
	}

	public function updateText(tanksTotal:Int, shellsCounter:Int, fps:Float) {
		tanksText.text = "Tanks: " + tanksTotal;
		shellsText.text = "Shells: " + shellsCounter;
		fpsText.text = "FPS: " + fps;
		inputText.text = "Use arrow to move camera, Q/W for zoom";
	}
}
