package util.ui;

import flixel.graphics.frames.FlxBitmapFont;
import flixel.system.FlxAssets.FlxAngelCodeAsset;
import flixel.system.FlxAssets.FlxBitmapFontGraphicAsset;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import util.ui.UIContainer.UIPlacement;
import util.ui.UIContainer.UISize;

/**
 * Text class to handle specific text settings for UI
 * Uses set FlxBitmapText for now
 * @author aeveis
 */
class UIText extends UIContainer
{
	public var textSprite:TypeBitmapText;

	public var text(default, set):String = "";
	public var shouldSkipType(get, null):Bool;
	public var isTyping(get, null):Bool;

	function set_text(p_text:String):String
	{
		textSprite.text = p_text;
		setSizeToText();
		return text = textSprite.text;
	}

	function get_shouldSkipType()
	{
		return !textSprite.isTypeText;
	}

	function get_isTyping()
	{
		return textSprite.isTyping;
	}

	public function new(?p_text:String, p_typeText:Bool = false, ?p_font:FlxBitmapFont)
	{
		super(UIPlacement.Inherit, UISize.Fill, UIPlacement.TopLeft);
		setBitmapFont(p_font);
		add(textSprite);
		if (p_text != null)
		{
			text = p_text;
		}

		if (p_typeText)
		{
			readyTyping();
		}
	}

	public function tweakShaderLineOffset(offset:Float)
	{
		textSprite.setShaderLineOffset(offset);
	}

	public function setAlignment(p_align:FlxTextAlign)
	{
		textSprite.alignment = p_align;
	}

	public function setWordWrap(p_wrap:Bool)
	{
		if (p_wrap)
		{
			textSprite.wrap = Wrap.WORD(NEVER);
		}
		else
		{
			textSprite.wrap = Wrap.NONE;
		}
		textSprite.refresh();
	}

	public function setMaxWidth(p_width:Float)
	{
		textSprite.fieldWidth = Math.round(p_width);
		textSprite.wrap = Wrap.WORD(NEVER);
		textSprite.autoSize = false;
		textSprite.refresh();
		setSizeToText();
	}

	public function setColor(p_color:FlxColor)
	{
		textSprite.color = p_color;
	}

	public function setSizeToText()
	{
		// size = UISize.Size(textSprite.width * textSprite.scale.x, textSprite.height * textSprite.scale.y);
		size = UISize.Size(textSprite.width, textSprite.height);
		refresh(true);
	}

	public function setBitmapFont(?font:FlxBitmapFont)
	{
		var setDefault = font == null;
		if (setDefault)
		{
			font = FlxBitmapFont.fromAngelCode(AssetPaths.Easyable_0__png, AssetPaths.Easyable__fnt);
		}
		textSprite = new TypeBitmapText(font);
		textSprite.text = "";
		if (setDefault)
		{
			tweakShaderLineOffset(0.15);
		}
	}

	/*public function setFont(?fontPath:String)
		{
			if (fontPath == null)
			{
				fontPath = AssetPaths.EasyableOutline__ttf;
			}
			textSprite = new TypeText();
	}*/
	public function readyTyping()
	{
		textSprite.readyTyping();
	}

	public function startTyping(pixelPerSec:Float = 512.0)
	{
		textSprite.startTyping(pixelPerSec);
	}

	public function skipTyping()
	{
		textSprite.skipTyping();
	}

	public function setTypingSound(soundName:String, soundRandomCount:Int = 0, volume:Float = 0.5)
	{
		textSprite.setTypingSound(soundName, soundRandomCount, volume);
	}
}
