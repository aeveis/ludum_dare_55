package objs;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxShader;

/**
 * ...
 * @author aeveis
 */
class PortalLine extends FlxSprite
{
	public function new()
	{
		super(0, 0);
        makeGraphic(FlxG.width + 20, 1, 0xff69dedf);
        immovable = true;
        origin.x = 0;
	}
}