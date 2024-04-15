package objs;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.path.FlxPath;
import flixel.util.FlxDirectionFlags;
import flixel.util.FlxTimer;
import ui.TextPopup;
import ui.TextTrigger;
import util.Input;

/**
 * ...
 * @author aeveis
 */
 
class Object extends FlxSprite
{
	private var timer:Float = 0;

	public static inline var NONE:Int = 0;
	public static inline var BOUNCE:Int = 1;
	public static inline var RISEFADE:Int = 2;
	public static inline var HIDE:Int = 3;

	public static inline var NOWARNING:Int = -1;
	public static inline var DEFAULT:Int = 0;
	public static inline var PORTAL:Int = 1;
	public static inline var OBSTACLE:Int = 2;
	

	public var state:Int = 0;
	public var sineAmount:Float = 1;
	public var sineSpeed:Float = 3;

	public var startY:Float = 0;
	public var spawnX:Float = 0;

	public var textTrigger:TextTrigger;

	public var warning:FlxSprite;
	public var warningMulti:Float = 1.0;
	public var warningType:Int;
	public static inline var WARNING_DIST:Float = 150.0;

	public function new(px:Float, py:Float, assetName:String = "", pstate:Int = NONE, pwarning:Int = DEFAULT)
	{
		if(assetName == null || assetName == "")
		{
			super(px,py);
		}
		else
		{
			super(px, py, assetName);
		}
		state = pstate;
		//drag.set(10, 10);
		setup(px, py);

		warning = new FlxSprite(304, py);
		if(height > 16)
		{
			warning.y += (height - 16) / 2.0;
		}
		warning.scrollFactor.set(0,0);
		warning.loadGraphic(AssetPaths.warnings__png, true, 16, 16);
		warning.animation.add("default", [0], 10, false);
		warning.animation.add("portal", [1], 10, false);
		warning.animation.add("obstacle", [2], 10, false);
		warningType = pwarning;
		switch(warningType)
		{
			case PORTAL:
				warning.animation.play("portal");
			case OBSTACLE:
				warning.animation.play("obstacle");
			default:
				warning.animation.play("default");
		}
		warning.cameras = [PlayState.instance.fgCam];
	}

	public function setup(px:Float, py:Float)
	{
		x = px;
		y = py;
		startY = py;
		setFacingFlip(FlxDirectionFlags.LEFT, true, false);
		setFacingFlip(FlxDirectionFlags.RIGHT, false, false);
		
		// solid = true;
		timer = FlxG.random.float(0, 5);
	}

	public override function update(elapsed:Float)
	{
		velocity.x = -PlayState.instance.speed * 4.0;
		
		super.update(elapsed);
		
		switch (state)
		{
			case BOUNCE:
				timer += elapsed * sineSpeed;
				y = startY + sineAmount * Math.sin(timer);
			case RISEFADE:
				y -= elapsed * 10;
				alpha -= elapsed * 10;
				if (alpha <= 0)
				{
					visible = false;
					alpha = 1;
					y = startY;
					state = HIDE;
				}
			default:
		}

		if (velocity.x > 2)
		{
			facing = FlxDirectionFlags.RIGHT;
		}
		else if (velocity.x < -2)
		{
			facing = FlxDirectionFlags.LEFT;
		}

		if(PlayState.instance.bird.velocity.x > 0)
		{
			if(x < -width + PlayState.instance.fgCam.scroll.x)
			{
				kill();
			}
		}
		if(PlayState.instance.bird.velocity.x < 0)
		{
			if(x > FlxG.width + PlayState.instance.fgCam.scroll.x)
			{
				kill();
			}
		}

		if (textTrigger == null)
			return;
		
	}
	override function reset(x:Float, y:Float) 
	{
		//trace(PlayState.instance.bird.x);
		super.reset(x, y);
	}
	override function kill() 
	{
		//trace(PlayState.instance.bird.x);
		super.kill();
	}
	override function draw() 
	{
		super.draw();
		if(warningType == NOWARNING)
		{
			return;
		}
		if(x > FlxG.width + PlayState.instance.fgCam.scroll.x)
		{
			warning.draw();
		}
	}
}
