package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.editors.tiled.TiledObject;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.util.FlxDirectionFlags;
import flixel.util.FlxTimer;
import global.TextConstants;
import objs.Background;
import objs.Bird;
import objs.Crate;
import objs.DustEmitter;
import objs.FuelBee;
import objs.Object;
import objs.Portal;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;
import shaders.CameraShader;
import ui.TextBox;
import ui.TextPopup;
import ui.TextTrigger;
import ui.Timer;
import util.Input;
import util.RangeMap;
import util.SpawnFloat;
import util.TiledLevel;
import util.ui.UIContainer.UILayout;
import util.ui.UIContainer.UIPlacement;
import util.ui.UIText;

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
	public var beeRanges:RangeMap<SpawnFloat>;
	public var crates:FlxTypedGroup<Crate>;
	public var crateRanges:RangeMap<SpawnFloat>;
	public var portals:FlxTypedGroup<Portal>;
	public var portalRanges:RangeMap<Portal>;
	public var nextPortalPos:FlxPoint;
	public var objects:FlxTypedGroup<Object>;

	public var hud:FlxGroup;
	public var timer:Timer;
	
	public var textbox:TextBox;
	public var textTriggers:FlxGroup;
	public var textpopups:FlxGroup;
	public var textTrigger:TextTrigger;

	public var despawnOffset:Float = 6.0;

	public var sfxSpeed:FlxSound;
	public var sfxFlame:FlxSound;

	public var helpText:UIText;
	public var helpRatio:Float = 1.0;

	public var endRatio:Float = 0;

	public static inline var INTRO:Int = 0;
	public static inline var START:Int = 1;
	public static inline var END:Int = 2;
	public static inline var ENDFADE:Int = 3;
	public static inline var FOOSH:Int = 4;
	public static inline var DONE:Int = 5;
	public var gameState = INTRO;

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
	public var spawnDist(get, null):Float;
	function get_spawnDist()
	{
		return Object.WARNING_DIST * (1.0+speedRatio);
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
		textTriggers = new FlxGroup();
		textpopups = new FlxGroup();

		bg = new Background();
		bg.scrollFactor.set(0,0);
		bird = new Bird(7, 59);
		fgCam.follow(bird, FlxCameraFollowStyle.PLATFORMER);
		fgCam.deadzone.right -= 100;

		beeRanges = new RangeMap<SpawnFloat>();
		bees = new FlxTypedGroup<FuelBee>();
		for(i in 0...30)
		{
			var bee:FuelBee = new FuelBee(0,0);
			bee.kill();
			bees.add(bee);
		}
		crateRanges = new RangeMap<SpawnFloat>();
		crates = new FlxTypedGroup<Crate>();
		for(i in 0...80)
		{
			var crate:Crate = new Crate(0,0);
			crate.kill();
			crates.add(crate);
		}
		nextPortalPos = FlxPoint.get();
		portalRanges = new RangeMap<Portal>();
		portals = new FlxTypedGroup<Portal>();
		objects = new FlxTypedGroup<Object>();
		
		textbox = new TextBox(AssetPaths.textbox__png, UIPlacement.Top, UISize.XFill(22), 0.5, UIParent.Camera(camera));
		textbox.setPortrait(AssetPaths.portraits__png, true, 16, 16);
		textbox.setPortraitBorderImage(AssetPaths.portrait_border__png, UILayout.sides(1));	textbox.addAnim("bird", [0]);
		textbox.addAnim("birdah", [1]);
		textbox.addAnim("wiz", [2]);
		textbox.playAnim("bird");
		textbox.visible = false;
		
		level = new TiledLevel(AssetPaths.getFile("level" + G.level, AssetPaths.LOC_DATA, "tmx"));
		level.loadTileMap("tiles", "tiles", false);
		level.loadObjects("entities", loadObj);
		FlxG.worldBounds.set(0, 0, FlxG.width * 1.5, FlxG.height);
		fgCam.setScrollBoundsRect(0, 0, FlxG.width * 1.5, FlxG.height);
		
		helpText = new UIText("--> <yellow>Get going!</yellow> <wave>The summoning circles are wayyy to the right</wave>!", true);
		helpText.setPlacement(UIPlacement.Center);
		var helpCam:FlxCamera = new FlxCamera(0, 0, Math.floor(helpText.width),
			Math.floor(helpText.height), 0.5);
		FlxG.cameras.add(helpCam);
		helpCam.bgColor = 0;
		helpText.setParent(UIParent.Camera(helpCam));
		helpText.textSprite.cameras = [helpCam];
		helpCam.x = FlxG.camera.x + bird.x + 16;
		helpCam.y = FlxG.camera.y + bird.y - 16;
		helpText.x = 0;
		helpText.y = 0;

		hud = new FlxGroup();
		timer = new Timer();
		hud.add(timer);

		add(bg);
		//add(bird.portalLine);
		fgGroup.add(objects);
		fgGroup.add(crates);
		fgGroup.add(dustEmit);
		fgGroup.add(portals);
		fgGroup.add(bees);
		fgGroup.add(bird);
		fgGroup.add(hud);
		fgGroup.add(textbox);
		fgGroup.add(textpopups);
		fgGroup.add(textTriggers);
		fgGroup.add(helpText);
		add(fgGroup);

		if (FlxG.sound.music == null)
		{
			FlxG.sound.playMusic("flyyoufools", 0);
		}
		if (!G.startInput)
		{
			FlxG.sound.music.pause();
		}

		sfxSpeed = G.loadLoopedSound(AssetPaths.speed_loop__ogg, 0.0);
		sfxFlame = G.loadLoopedSound(AssetPaths.fire__ogg, 0.0);
		fade(0.3, true, fadeOnComplete);
	}

	public function loadObj(pobj:TiledObject, px:Float, py:Float)
	{
		var pname:String = pobj.name;
		switch (pname)
		{
			case "fuelbee":
				while(beeRanges.exists(px))
				{
					px += 0.1;
				}
				beeRanges.set(px, new SpawnFloat(py));
			case "crate":
				while(crateRanges.exists(px))
				{
					px += 0.1;
				}
				crateRanges.set(px, new SpawnFloat(py));
			case "portal0":
				while(portalRanges.exists(px))
				{
					px += 0.1;
				}
				if(portalRanges.keys.length == 0)
				{
					nextPortalPos.set(px,py);
				}
				var portal:Portal = new Portal(px, py, Portal.SMALL);
				portalRanges.set(px, portal);
			case "portal1":
				while(portalRanges.exists(px))
				{
					px += 0.1;
				}
				var portal:Portal = new Portal(px, py, Portal.MEDIUM);
				portalRanges.set(px, portal);
			case "portal2":
				while(portalRanges.exists(px))
				{
					px += 0.1;
				}
				var portal:Portal = new Portal(px, py, Portal.LARGE);
				portalRanges.set(px, portal);
			default:
				var textID:String = "debug";
				textID = pobj.properties.contains("text") ? pobj.properties.get("text") : "debug";
				var type:String = pobj.properties.contains("type") ? pobj.properties.get("type") : null;
				var unskippable:Bool = type == "unskippable";
				var portrait:String = pobj.properties.contains("portrait") ? pobj.properties.get("portrait") : "wiz";
				var obj:Object = null;

				if (pname != "text")
				{
					obj = new Object(px, py, AssetPaths.getFile(pobj.properties.get("type")), Object.NOWARNING);
					obj.setFacingFlip(FlxDirectionFlags.LEFT, false, false);

					pobj.flippedHorizontally ? obj.facing = FlxDirectionFlags.LEFT : obj.facing = FlxDirectionFlags.RIGHT;
					objects.add(obj);
				}

				if (textID != null)
				{
					if (pname == "text")
					{
						py += pobj.height;
					}

					var textNode:TextNode = Reflect.getProperty(TextConstants.instance, textID);
					if (textNode == null)
					{
						textNode = TextConstants.instance.error;
					}

					var txt = new TextTrigger(px - 8, py - 8, pobj.width + 16, pobj.height + 16, textID, textNode);
					textTrigger = txt;
					txt.unskippable = unskippable;
					txt.setTypeSound("birdtype", 0);

					if (obj != null)
					{
						obj.textTrigger = txt;
					}
					textNode.portraits[0] = txt.animName = portrait;

					textTriggers.add(txt);
					if (unskippable)
					{
						return;
					}
					txt.addTextPopup(new TextPopup(px, py - 8));
					textpopups.add(txt.textpopup);
				}
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
			if (!FlxG.overlap(textTriggers, bird, checkText))
			{
				textbox.hasMoreText = false;
				if (Input.control.keys.get("select").justPressed)
				{
					textbox.skipTyping();
				}
			}
			super.update(elapsed);
			return;
		}

		spawnCrates();
		spawnBees();
		spawnPortals();
		FlxG.overlap(bees, bird, beeBoost);
		FlxG.overlap(crates, bird, crateBoost);
		FlxG.overlap(portals, bird, portalBoost);

		switch(gameState)
		{
			case START:
				if(!helpText.isTyping)
				{
					if(bird.velocity.x > 0)
					{
						helpRatio -= elapsed;
						helpRatio = Math.max(0, helpRatio);
						helpText.textSprite.setTypeRatio(helpRatio);
					}
					else
					{
						helpRatio += elapsed;
						helpRatio = Math.min(1.0, helpRatio);
						helpText.textSprite.setTypeRatio(helpRatio);
					}
				}
			case END:
				endRatio += elapsed;
				if(endRatio > 2.0)
				{
					endRatio = 2.0;
					gameState = ENDFADE;
					fade(1.0, false, gameEnd, 0xff6232b9);
				}
				camShader.endRatio.value = [endRatio];
			case FOOSH:
				dustEmit.x = bird.x;
				dustEmit.y = bird.y; 
				dustEmit.foosh();
			case DONE:
				endRatio -= elapsed * 3.0;
				if(endRatio < 0)
				{
					endRatio = 0;
				}
				camShader.endRatio.value = [endRatio];
			default:
		}

		time += elapsed * speedMultiplier;
		time = time % 200.0;
		camShader.time.value = [time];
		camShader.ratio.value = [speedMultiplier];

		//trace(sfxSpeed.playing + " " + sfxSpeed.volume + " " + sfxSpeed.pitch + " " + speedRatio);
		sfxSpeed.volume = FlxMath.lerp(0,0.7,speedRatio);
		sfxSpeed.pitch = FlxMath.lerp(1.0,2.2,speedRatio);
		
		if (!FlxG.overlap(textTriggers, bird, checkText))
		{
			textbox.hasMoreText = false;
			if (textbox.visible)
			{
				textbox.close();
			}
		}
		super.update(elapsed);

		if (Input.control.keys.get("restart").justPressed)
		{
			restart();
		}
	}
	public function gameEnd()
	{
		bird.y = FlxG.height/2.0;
		new FlxTimer().start(0.2, (time:FlxTimer)->fade(0.2, true, 0xff6232b9));
		TextConstants.instance.ending.texts = [
			"I summon you, the great Phoenix! This will be my ultimate attack!",
			"<red> !<shake>!FOOOOSH!</shake>! </red>",
			"Yes! It only took " + timer.timeString + " minutes to summon Phoenix!",
			"Thanks for playing! Press R to replay the game."
		];
		textTrigger.setTextNode(TextConstants.instance.ending);
		textTrigger.name = "ending";
		textTrigger.unskippable = true;
		textTrigger.x = bird.x;
		textTrigger.y = bird.y;
		textTrigger.resetTrigger();
		textTrigger.visible = true;
	}

	public function spawnBees()
	{
		if(bird.velocity.x >= 0)
		{
			if(!beeRanges.existsLess(bird.x))
			{
				return;
			}
			var closebees:Array<SpawnFloat> = beeRanges.getAllLess(bird.x);
			//trace(bird.x);
			for(beey in closebees)
			{
				if(beey.dead || beey.spawned)
				{
					continue;
				}
				var key:Float = beeRanges.getKey(beey);
				var bee:FuelBee = bees.getFirstAvailable();
				beey.spawned = true;
				if(bee != null)
				{
					bee.spawnX = key;
					bee.spawn(fgCam.x + FlxG.width + spawnDist, beey.value, FuelBee.YELLOW);
				}
				bee = bees.getFirstAvailable();
				if(bee != null)
				{
					bee.spawnX = key;
					bee.spawn(fgCam.x + FlxG.width + spawnDist, beey.value - 10, FuelBee.RED);
				}
				bee = bees.getFirstAvailable();
				if(bee != null)
				{
					bee.spawnX = key;
					bee.spawn(fgCam.x + FlxG.width + spawnDist, beey.value + 10, FuelBee.RED);
				}
				bee = bees.getFirstAvailable();
				if(bee != null)
				{
					bee.spawnX = key;
					bee.spawn(fgCam.x + FlxG.width + spawnDist, beey.value - 20, FuelBee.BLUE);
				}
				bee = bees.getFirstAvailable();
				if(bee != null)
				{
					bee.spawnX = key;
					bee.spawn(fgCam.x + FlxG.width + spawnDist, beey.value + 20, FuelBee.BLUE);
				}
				
			}
		}
		else
		{
			if(!beeRanges.existsGreater(bird.x - despawnOffset))
			{
				return;
			}
			var closebees:Array<SpawnFloat> = beeRanges.getAllGreater(bird.x - despawnOffset);
			for(beey in closebees)
			{
				if(beey.dead || beey.spawned)
				{
					continue;
				}
				var key:Float = beeRanges.getKey(beey);
				var bee:FuelBee = bees.getFirstAvailable();
				beey.spawned = true;
				if(bee != null)
				{
					bee.spawnX = key;
					bee.spawn(beey.despawnX, beey.value, FuelBee.YELLOW);
				}
				bee = bees.getFirstAvailable();
				if(bee != null)
				{
					bee.spawnX = key;
					bee.spawn(beey.despawnX, beey.value - 10, FuelBee.RED);
				}
				bee = bees.getFirstAvailable();
				if(bee != null)
				{
					bee.spawnX = key;
					bee.spawn(beey.despawnX, beey.value + 10, FuelBee.RED);
				}
				bee = bees.getFirstAvailable();
				if(bee != null)
				{
					bee.spawnX = key;
					bee.spawn(beey.despawnX, beey.value - 20, FuelBee.BLUE);
				}
				bee = bees.getFirstAvailable();
				if(bee != null)
				{
					bee.spawnX = key;
					bee.spawn(beey.despawnX, beey.value + 20, FuelBee.BLUE);
				}
				
			}
		}
	}
	public function beeBoost(bee:FuelBee, bird:Bird)
	{
		if(!bee.alive)
		{
			return;
		}
		bee.explode();
		switch(bee.beeType)
		{
			case FuelBee.YELLOW:
				bird.airBoostXStrength = 0.5;
			case FuelBee.RED:
				bird.airBoostXStrength = 0.25;
			case FuelBee.BLUE:
				bird.airBoostXStrength = 0.2;
		}
		bird.fsm.switchState(MoveState.AirBoost);
	}
	public function spawnCrates()
	{
		if(bird.velocity.x >= 0)
		{
			if(!crateRanges.existsLess(bird.x))
			{
				return;
			}
			var closeObjs:Array<SpawnFloat> = crateRanges.getAllLess(bird.x);
			for(objy in closeObjs)
			{
				if(objy.dead || objy.spawned)
				{
					continue;
				}
				var key:Float = crateRanges.getKey(objy);
				var obj:Crate = crates.getFirstAvailable();
				objy.spawned = true;
				if(obj != null)
				{
					obj.spawnX = key;
					obj.reset(fgCam.x + FlxG.width + spawnDist, objy.value);
				}
				
			}
		}
		else 
		{
			if(!crateRanges.existsGreater(bird.x - despawnOffset))
			{
				return;
			}
			var closeObjs:Array<SpawnFloat> = crateRanges.getAllGreater(bird.x - despawnOffset);
			for(objy in closeObjs)
			{
				if(objy.dead || objy.spawned)
				{
					continue;
				}
				var key:Float = crateRanges.getKey(objy);
				var obj:Crate = crates.getFirstAvailable();
				objy.spawned = true;
				if(obj != null)
				{
					obj.spawnX = key;
					obj.reset(objy.despawnX, objy.value);
				}
				
			}
		}
	}
	public function crateBoost(crate:Crate, bird:Bird)
	{
		if(!crate.alive)
		{
			return;
		}
		crate.explode();
		bird.airBoostXStrength = -0.05;
		bird.fsm.switchState(MoveState.AirBoost);
	}
	public function spawnPortals()
	{
		if(bird.velocity.x >= 0)
		{
			if(!portalRanges.existsLess(bird.x))
			{
				return;
			}
			var closePortals:Array<Portal> = portalRanges.getAllLess(bird.x);
			for(portal in closePortals)
			{
				if(portal.spawned || portal.collected)
				{
					continue;
				}
				if(!portal.exists)
				{
					portal.revive();
				}
				portal.spawned = true;
				portal.spawnX = portalRanges.getKey(portal);
				portal.x = fgCam.x + FlxG.width + spawnDist * portal.warningMulti;
				if(!portals.members.contains(portal))
				{
					portals.add(portal);
				}
			}
		}
		else
		{
			if(!portalRanges.existsGreater(bird.x - despawnOffset))
			{
				return;
			}
			var closePortals:Array<Portal> = portalRanges.getAllGreater(bird.x - despawnOffset);
			for(portal in closePortals)
			{
				//trace(portal.spawned, portal.collected);
				if(portal.spawned || portal.collected)
				{
					continue;
				}
				if(!portal.exists)
				{
					portal.revive();
				}
				portal.spawnX = portalRanges.getKey(portal);
				portal.spawned = true;
				portal.x = portal.despawnX;
				if(!portals.members.contains(portal))
				{
					portals.add(portal);
				}
			}
		}
	}
	public function portalBoost(portal:Portal, bird:Bird)
	{
		if(portal.collected)
		{
			return;
		}
		portal.explode();
		switch(portal.portalType)
		{
			case Portal.SMALL:
				bird.maxSpeed += 0.1;
			case Portal.MEDIUM:
				bird.maxSpeed += 0.2;
			case Portal.LARGE:
				timer.stopTimer();
				gameState = PlayState.END;
				//trace("you win");
		}
		bird.airBoostXStrength = 0.75;
		bird.fsm.switchState(MoveState.AirBoost);

		for(i in 0...portalRanges.values.length)
		{
			if(!portalRanges.values[i].spawned)
			{
				nextPortalPos.set(portalRanges.keys[i],portalRanges.values[i].y);
				break;
			}
		}
	}
	public function playTrigger(trigger:TextTrigger)
	{
		var textToPlay:String = "";

		textToPlay = trigger.getText();
		if (trigger.name == "ending")
		{
			if(trigger.index == 2)
			{
				gameState = FOOSH;
				FlxG.sound.music.fadeOut(1,0.1);
				sfxFlame.resume();
				sfxFlame.volume = 1;
			}
			if(trigger.index == 3)
			{
				gameState = DONE;
				FlxG.sound.music.fadeIn(1,0.4);
				sfxFlame.fadeOut(0.5);
			}
		}

		Bird.control = false;
		textbox.visible = true;
		trigger.setPopupState(PopupState.Open);
		textbox.playAnim(trigger.animName);

		textbox.hasMoreText = true;
		textbox.setStatus(TextBoxStatus.Skip);
		textbox.playText(textToPlay, trigger.typeSoundName, trigger.typeSoundRandomCount);

		if (trigger.state == TextTriggerState.Done)
		{
			textbox.hasMoreText = false;
		}
		else
		{
			trigger.state = TextTriggerState.Playing;
		}
	}

	public function checkText(trigger:TextTrigger, player:FlxObject)
	{
		if (overlapFrame == frameCount || !trigger.visible)
		{
			return;
		}
		trigger.onTrigger = true;
		if (!textbox.visible)
		{
			trigger.setPopupState(PopupState.Show);
		}

		switch (trigger.state)
		{
			case TextTriggerState.Ready:
				if (!Input.control.keys.get("select").justPressed && !trigger.unskippable)
				{
					return;
				}
				playTrigger(trigger);

			case TextTriggerState.Playing:
				if (Input.control.keys.get("select").justPressed)
				{
					if (textbox.isDoneTyping)
					{
						// trigger.state = TextTriggerState.Ready;
						textbox.setStatus(TextBoxStatus.Next);
						playTrigger(trigger);
					}
					else
					{
						textbox.skipTyping();
						textbox.setStatus(TextBoxStatus.Next);
					}
				}
				if (textbox.isDoneTyping)
				{
					textbox.setStatus(TextBoxStatus.Next);
				}
			case TextTriggerState.Done:
				if (textbox.isDoneTyping)
				{
					textbox.setStatus(TextBoxStatus.Done);
				}
				if (Input.control.keys.get("select").justPressed)
				{
					if (textbox.isDoneTyping)
					{
						Bird.control = true;
						textbox.visible = false;
						if (trigger.oneshot)
						{
							trigger.visible = false;
							return;
						}
						switch(trigger.name)
						{
							case "intro":
								bird.fsm.switchState(MoveState.Idle);
								trigger.visible = false;
								helpText.startTyping(); 
								gameState = START;
								FlxG.sound.music.fadeIn(1, 0, 0.4);
								timer.startTimer();
							case "ending":
								trigger.visible = false;

						}
						trigger.resetTrigger();
					}
					else
					{
						textbox.skipTyping();
					}
				}
		}
		overlapFrame = frameCount;
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
		for(cam in FlxG.cameras.list)
		{
			if(cam == camera)
			{
				continue;
			}
			cam.fade(pColor, pDuration, pFadeIn);
		}
	}

	public function restart(fadeTime:Float = 0.3):Void
	{
		fade(fadeTime, false, refreshState);
		fadeComplete = false;
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.fadeOut(.3);
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
