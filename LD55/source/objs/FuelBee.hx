package objs;

import flixel.FlxSprite;
import flixel.util.FlxDirection;
import flixel.util.FlxTimer;

/**
 * ...
 * @author aeveis
 */
class FuelBee extends Object
{
	public function new(px:Float, py:Float)
	{
		super(px, py, null, Object.BOUNCE);
		loadGraphic(AssetPaths.fuelbee__png, true, 16, 16);
		animation.add("idle", [0,1,2], 10, true);
		animation.add("death",[3], 10, false);
		animation.play("idle");
	}

	public function explode()
	{
		animation.play("death");
		DustEmitter.instance.x = x;
		DustEmitter.instance.y = y;
		DustEmitter.instance.fireflyPoof();
		new FlxTimer().start(0.1, (timer:FlxTimer)->
		{
			kill();
		});
	}
}
 