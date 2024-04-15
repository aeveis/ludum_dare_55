package objs;

import flixel.util.FlxTimer;

/**
 * ...
 * @author aeveis
 */
class FuelBee extends Object
{
	public static inline var YELLOW:Int = 0;
	public static inline var RED:Int = 1;
	public static inline var BLUE:Int = 2;
	public var beeType:Int = YELLOW;

	public function new(px:Float, py:Float, pbeetype:Int = YELLOW)
	{
		super(px, py, null, Object.BOUNCE);
		loadGraphic(AssetPaths.fuelbee__png, true, 16, 16);
		beeType = pbeetype;
		switch(beeType)
		{
			case YELLOW:
				animation.add("idle", [0,1,2], 10, true);
				animation.add("death",[3], 10, false);
			case RED:
				animation.add("idle", [4,5,6], 10, true);
				animation.add("death",[7], 10, false);
			case BLUE:
				animation.add("idle", [8,9,10], 10, true);
				animation.add("death",[11], 10, false);
		}
		animation.play("idle");
		height = 10;
		centerOffsets();
	}

	public function explode()
	{
		animation.play("death");
		alive = false;
		G.playSound("bugdeath",0.5);
		DustEmitter.instance.x = x - 8;
		DustEmitter.instance.y = y + 3;
		DustEmitter.instance.fireflyPoof(beeType);
		new FlxTimer().start(0.1, (timer:FlxTimer)->
		{
			if(PlayState.instance.beeRanges.exists(x))
			{
				PlayState.instance.beeRanges.get(x).dead = true;
			}
		});
		kill();
	}

	public function spawn(px:Float, py:Float, btype:Int)
	{
		beeType = btype;
		switch(beeType)
		{
			case YELLOW:
				animation.getByName("idle").frames = [0,1,2];
				animation.getByName("death").frames = [3];
			case RED:
				animation.getByName("idle").frames = [4,5,6];
				animation.getByName("death").frames = [7];
			case BLUE:
				animation.getByName("idle").frames = [8,9,10];
				animation.getByName("death").frames = [11];
		}
		reset(px,py);
	}

	override function reset(px:Float, py:Float) 
	{
		startY = warning.y = py;
		super.reset(px, py);
		animation.play("idle");
	}

	override function kill() 
	{
		if(PlayState.instance.beeRanges.exists(spawnX))
		{
			PlayState.instance.beeRanges.get(spawnX).spawned = false;
			PlayState.instance.beeRanges.get(spawnX).despawnX = x;
		}
		super.kill();
	}
}
 