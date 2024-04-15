package objs;
import flixel.util.FlxTimer;


/**
 * ...
 * @author aeveis
 */
class Portal extends Object
{
	public static inline var SMALL:Int = 0;
	public static inline var MEDIUM:Int = 1;
	public static inline var LARGE:Int = 2;

	public var portalType:Int;
	public var spawned:Bool = false;
	public var collected:Bool = false;
	public var despawnX:Float = 0;

	public function new(px:Float, py:Float, ptype:Int)
	{
		portalType = ptype;
		switch(portalType)
		{
			case SMALL:
				super(px, py, AssetPaths.portal0__png, Object.NONE, Object.PORTAL);
			case MEDIUM:
				super(px, py, AssetPaths.portal1__png, Object.NONE, Object.PORTAL);
			case LARGE:
				super(px, py, AssetPaths.portal2__png, Object.NONE, Object.PORTAL);
		}
		warningMulti = 2.0;
	}

	public function explode()
	{
		collected = true;
		DustEmitter.instance.x = x;
		DustEmitter.instance.y = y;
		switch(portalType)
		{
			case SMALL:
				G.playSound("portal");
				DustEmitter.instance.colorPoof(0x9658bc);
			case MEDIUM:
				G.playSound("portal");
				DustEmitter.instance.colorPoof(0x9658bc);
				DustEmitter.instance.y += 16;
				DustEmitter.instance.colorPoof(0x9658bc);
			case LARGE:
				G.playSound("portal");
				DustEmitter.instance.x += 8;
				DustEmitter.instance.colorPoof(0x9658bc);
				DustEmitter.instance.y += 16;
				DustEmitter.instance.colorPoof(0x9658bc);
				DustEmitter.instance.y += 16;
				DustEmitter.instance.colorPoof(0x9658bc);
				DustEmitter.instance.y += 16;
				DustEmitter.instance.colorPoof(0x9658bc);
				DustEmitter.instance.y += 16;
				DustEmitter.instance.colorPoof(0x9658bc);
		}
		state = Object.RISEFADE;
		new FlxTimer().start(0.1, (timer:FlxTimer)->
		{
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
		spawned = false;
		despawnX = x;
		super.kill();
	}

}
 