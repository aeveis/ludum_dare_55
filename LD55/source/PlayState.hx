package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.editors.tiled.TiledObject;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import objs.Background;
import objs.Bird;
import objs.DustEmitter;
import objs.FuelBee;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;
import shaders.CameraShader;
import ui.TextBox;
import util.Input;
import util.RangeMap;
import util.TiledLevel;
import util.ui.UIContainer.UILayout;
import util.ui.UIContainer.UIPlacement;

class PlayState extends FlxState
{
	public static var instance:PlayState;
	public var level:TiledLevel;
	public var fadeComplete:Bool = false;
	public var followCam:FlxObject = null;
	public var frameCount:Int = 0;
	public var overlapFrame:Int = 0;
	public var fgCam:FlxCamera;
	public var fgGroup:FlxGroup;
	public var camShader:CameraShader;

	public var bg:Background;
	public var dustEmit:DustEmitter;
	public var bird:Bird;
	public var bees:FlxTypedGroup<FuelBee>;
	public var beePool:RangeMap<FuelBee>;
	
	public var textbox:TextBox;

	public var sfxSpeed:FlxSound;

	public var time:Float = 0;
	public var speedRatio(get, null):Float;
	function get_speedRatio()
	{
		if(!G.startInput)
		{
			return 0.0;
		}
		var ratio:Float = bird.velocity.x/bird.maxTotalSpeed;
		return ratio*ratio;
	}
	public var speedMultiplier(get, null):Float;
	function get_speedMultiplier()
	{
		if(!G.startInput)
		{
			return 0.0;
		}
		var sign:Float = (bird.velocity.x > 0)?1.0:-1.0;
		return sign*speedRatio*2.0;
	}
	public var speed(get, null):Float;
	function get_speed()
	{
		if(!G.startInput)
		{
			return 0.0;
		}
		return bg.speed*5000.0;
	}

	override public function create()
	{
		super.create();
		instance = this;

		fgCam = new FlxCamera( camera.x, camera.y, camera.width, cast camera.height);
		fgCam.bgColor = 0x0045b8ad;
		FlxG.cameras.add(fgCam);
		fgGroup = new FlxGroup();
		fgGroup.cameras = [fgCam];
		
		cameras = [camera];
		FlxG.mouse.useSystemCursor = true;
		FlxG.camera.bgColor = 0x0045b8ad;
		FlxG.camera.pixelPerfectRender = false;
		camShader = new CameraShader();
		camera.filters = new Array<BitmapFilter>();
		camera.filters.push(new ShaderFilter(camShader));

		Input.control = new Input();
		Input.control.platformerSetup();
		dustEmit = new DustEmitter();
		bees = new FlxTypedGroup<FuelBee>();
		beePool = new RangeMap();
		
		/*textbox = new TextBox(AssetPaths.textbox__png, UIPlacement.Top, UISize.XFill(22), 0.5, UIParent.Camera(camera));
		textbox.setPortrait(AssetPaths.portraits__png, true, 16, 16);
		textbox.setPortraitBorderImage(AssetPaths.portrait_border__png, UILayout.sides(1));
*/
		bg = new Background();
		bird = new Bird(10, 50);
		
		level = new TiledLevel(AssetPaths.getFile("level" + G.level, AssetPaths.LOC_DATA, "tmx"));
		level.loadTileMap("tiles", "tiles", false);
		level.loadObjects("entities", loadObj);
		
		add(bg);
		fgGroup.add(dustEmit);
		fgGroup.add(bees);
		fgGroup.add(bird);
		add(fgGroup);

		sfxSpeed = G.loadLoopedSound(AssetPaths.speed__ogg, 0.5);
		fade(0.3, true, fadeOnComplete);
	}

	public function loadObj(pobj:TiledObject, px:Float, py:Float)
	{
		var pname:String = pobj.name;
		
		switch (pname)
		{
			case "fuelbee":
				var bee = new FuelBee(px, py);
				while(beePool.exists(px))
				{
					px += 0.1;
				}
				beePool.set(px, bee);
		}
	}

	override public function update(elapsed:Float)
	{
		frameCount++;
		Input.control.update(elapsed);
		if (!fadeComplete)
			return;

		if (!G.startInput)
		{
			if (Input.control.any || Input.control.keys.get("select").pressed)
			{
				G.startInput = true;
				sfxSpeed.resume();
				// FlxG.sound.music.fadeIn(1, 0, 0.5);
				// remove(title, true);
				// title.kill();
				/*if (Input.control.keys.get("select").justPressed)
					{
						G.playSound("birdtype0");
				}*/
			}
			/*if (!FlxG.overlap(textTriggers, bird, checkText))
			{
				textbox.hasMoreText = false;
				if (Input.control.keys.get("select").justPressed)
				{
					textbox.skipTyping();
				}
			}*/
			super.update(elapsed);
			return;
		}

		spawnBees();
		FlxG.overlap(bees, bird, beeBoost);

		time += elapsed * speedMultiplier;
		time = time % 200.0;
		camShader.time.value = [time];
		camShader.ratio.value = [speedMultiplier];

		//trace(sfxSpeed.playing + " " + sfxSpeed.volume + " " + sfxSpeed.pitch + " " + speedRatio);
		sfxSpeed.volume = FlxMath.lerp(0.5,1.0,speedRatio);
		sfxSpeed.pitch = FlxMath.lerp(1.0,2.2,speedRatio);
		super.update(elapsed);

		if (Input.control.keys.get("restart").justPressed)
		{
			restart();
		}
	}

	public function spawnBees()
	{
		if(!beePool.existsLess(bird.x))
		{
			return;
		}
		var closebees:Array<FuelBee> = beePool.getAllLess(bird.x);
		for(bee in closebees)
		{
			if(bee == null || bee.spawned)
			{
				continue;
			}

			bee.x = FlxG.width + 100.0;
			bee.spawned = true;
			bees.add(bee);
		}
	}
	public function beeBoost(bee:FuelBee, bird:Bird)
	{
		bee.explode();
		bird.airBoostXStrength = 0.35;
		bird.fsm.switchState(MoveState.AirBoost);
	}
	
	public function fade(pDuration:Float, pFadeIn:Bool = false, ?pCallback:Void->Void, ?pColor:Int)
	{
		if (pColor == null)
		{
			pColor = 0xff45b8ad;
		}
		/*if (textbox.visible)
			{
				textbox.textCam.fade(pColor, pDuration, pFadeIn);
		}*/
		camera.fade(pColor, pDuration, pFadeIn, pCallback);
	}

	public function restart(fadeTime:Float = 0.3):Void
	{
		fade(fadeTime, false, refreshState);
		fadeComplete = false;
		if (FlxG.sound.music != null)
		{
			//FlxG.sound.music.fadeOut(.3);
		}
	}

	public function fadeOnComplete():Void
	{
		fadeComplete = true;
	}

	public function refreshState():Void
	{
		G.startInput = false;
		FlxG.switchState(new PlayState());
	}
}
