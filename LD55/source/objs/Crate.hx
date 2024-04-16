package objs;
import flixel.util.FlxTimer;


/**
 * ...
 * @author aeveis
 */
class Crate extends Object
{
	public function new(px:Float, py:Float)
	{
		super(px, py, AssetPaths.crate__png, Object.BOUNCE, Object.OBSTACLE);
	}

	public function explode()
	{
		alive = false;
		G.playSound("boxhit",0.5);
		DustEmitter.instance.x = x;
		DustEmitter.instance.y = y;
		DustEmitter.instance.colorPoof(0xd99e62);
		state = Object.RISEFADE;
		new FlxTimer().start(0.1, (timer:FlxTimer)->
		{
			if(PlayState.instance.crateRanges.exists(x))
			{
				PlayState.instance.crateRanges.get(x).dead = true;
			}
			DustEmitter.instance.x = x;
			DustEmitter.instance.y = y;
			DustEmitter.instance.colorPoof(0xd99e62);
			kill();
		});
	}

	override function reset(px:Float, py:Float) 
	{
		startY = warning.y = py;
		visible = true;
		super.reset(px, py);
	}

	override function kill() 
	{
		if(PlayState.instance.crateRanges.exists(spawnX))
		{
			PlayState.instance.crateRanges.get(spawnX).spawned = false;
			PlayState.instance.crateRanges.get(spawnX).despawnX = x;
		}
		super.kill();
	}
}
 