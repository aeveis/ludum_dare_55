package ui;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import util.ui.UIContainer.UIPlacement;
import util.ui.UIText;

/**
 * ...
 * @author aeveis
 */
class Hud extends FlxGroup
{
	public var cursor:FlxSprite;
	public var mapPivot:FlxPoint;
	public var cellSize:Float = 10.0;
	public var mapCover:MapCover;

	public function new()
	{
		super();
		mapPivot = FlxPoint.get(5, 60);

		var borderTall1:FlxSprite = new FlxSprite(89, 1, AssetPaths.border_tall__png);
		borderTall1.scrollFactor.set(0, 0);
		add(borderTall1);
		var borderTall2:FlxSprite = new FlxSprite(636, 1, AssetPaths.border_tall__png);
		borderTall2.flipY = true;
		borderTall2.scrollFactor.set(0, 0);
		add(borderTall2);
		var borderWide1:FlxSprite = new FlxSprite(92, 1, AssetPaths.border_wide__png);
		borderWide1.scrollFactor.set(0, 0);
		add(borderWide1);
		var borderWide2:FlxSprite = new FlxSprite(92, 356, AssetPaths.border_wide__png);
		borderWide2.flipX = true;
		borderWide2.scrollFactor.set(0, 0);
		add(borderWide2);
		var title:FlxSprite = new FlxSprite(3, 4, AssetPaths.title__png);
		title.scrollFactor.set(0, 0);
		add(title);

		mapCover = new MapCover(mapPivot.x, mapPivot.y);
		mapCover.scrollFactor.set(0, 0);
		add(mapCover);
		mapCover.setShaderValues();

		cursor = new FlxSprite(35, 60, AssetPaths.mapcursor__png);
		cursor.scrollFactor.set(0, 0);
		add(cursor);

		var text:UIText = new UIText("Move\n<color=yellow>[Arrow\nKeys]</color>\n\nInteract\n<color=yellow>[X]</color>\n\nUndo\n<color=yellow>[Z]</color>\n\nReset\nLevel\n<color=yellow>[R]</color>");
		text.scrollFactor.set(0, 0);
		text.setPlacement(UIPlacement.Pos(4, 145));
		add(text);
	}

	public function setMapCursor(xIndex:Int, yIndex:Int)
	{
		cursor.setPosition(mapPivot.x + xIndex * cellSize, mapPivot.y + yIndex * cellSize);
		mapCover.revealCell(xIndex, yIndex);
	}

	override function destroy()
	{
		mapPivot.put();
		super.destroy();
	}
}
