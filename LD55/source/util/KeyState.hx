package util;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.util.FlxDirectionFlags;

/**
 * ...
 * @author aeveis
 */
class KeyState
{
	public static var keys:KeyState;

	public var pressed:Int = FlxDirectionFlags.NONE;
	public var lastPressed:Int = FlxDirectionFlags.NONE;
	public var upJustPressed:Bool = false;
	public var upJustPressedSlow:Bool = false;
	public var downJustPressed:Bool = false;
	public var leftJustPressed:Bool = false;
	public var rightJustPressed:Bool = false;
	public var action0:Bool = false;
	public var action0JustPressed:Bool = false;
	public var action1:Bool = false;
	public var action1JustPressed:Bool = false;
	public var jumpJustPressed:Bool = false;
	public var jump:Bool = false;

	public var left(get, null):Bool;

	function get_left()
	{
		return ((pressed & FlxDirectionFlags.LEFT) > 0);
	}

	public var right(get, null):Bool;

	function get_right()
	{
		return ((pressed & FlxDirectionFlags.RIGHT) > 0);
	}

	public var up(get, null):Bool;

	function get_up()
	{
		return ((pressed & FlxDirectionFlags.UP) > 0);
	}

	public var down(get, null):Bool;

	function get_down()
	{
		return ((pressed & FlxDirectionFlags.DOWN) > 0);
	}

	public var any(get, null):Bool;

	function get_any()
	{
		return up || down || left || right;
	}

	public var anyJustPressed(get, null):Bool;

	function get_anyJustPressed()
	{
		return upJustPressed || downJustPressed || leftJustPressed || rightJustPressed;
	}

	public var noneX(get, null):Bool;

	function get_noneX()
	{
		return (pressed == FlxDirectionFlags.NONE || pressed == FlxDirectionFlags.DOWN || pressed == FlxDirectionFlags.UP);
	}

	public var anyUpDown(get, null):Bool;

	function get_anyUpDown()
	{
		return upJustPressed || downJustPressed;
	}

	public var none(get, null):Bool;

	function get_none()
	{
		return pressed == FlxDirectionFlags.NONE;
	}

	public var analogX:Float = 1;
	public var stickRead:Bool = false;

	public var touchOrigin:FlxPoint;
	public var touchPoint:FlxPoint;
	public var clickDelay:Float = 0.3;
	public var clickTimer:Float = 0;
	public var clickCount:Int = 0;

	private var gamepad:FlxGamepad;
	private var stickMovedX:Bool = false;
	private var stickJustMovedX:Bool = false;
	private var stickMovedY:Bool = false;
	private var stickJustMovedY:Bool = false;
	private var upFrames:Int = 0;

	public function new()
	{
		touchOrigin = new FlxPoint(FlxG.width / 2, FlxG.height / 2);
		touchPoint = new FlxPoint(0, 0);
	}

	public function reset()
	{
		pressed = FlxDirectionFlags.NONE;
		upJustPressed = false;
		downJustPressed = false;
		leftJustPressed = false;
		rightJustPressed = false;
		action0 = false;
		action0JustPressed = false;
		action1 = false;
		action1JustPressed = false;
		stickRead = false;
		stickJustMovedX = false;
		stickJustMovedY = false;
		jumpJustPressed = false;
		jump = false;
	}

	public function update()
	{
		lastPressed = pressed;
		reset();
		// var touched:Bool = FlxG.mouse.pressed;
		touchPoint.set(FlxG.mouse.x, FlxG.mouse.y);

		if (FlxG.keys.pressed.A || FlxG.keys.pressed.LEFT) // || (touched && touchPoint.x < touchOrigin.x))
		{
			pressed = pressed | FlxDirectionFlags.LEFT;
		}
		if (FlxG.keys.pressed.D || FlxG.keys.pressed.RIGHT) // || (touched && touchPoint.x > touchOrigin.x))
		{
			pressed = pressed | FlxDirectionFlags.RIGHT;
		}
		if (FlxG.keys.pressed.S || FlxG.keys.pressed.DOWN) // || (touched && touchPoint.y > touchOrigin.y))
		{
			pressed = pressed | FlxDirectionFlags.DOWN;
		}
		if (FlxG.keys.pressed.SPACE || FlxG.keys.pressed.W || FlxG.keys.pressed.UP) // || (touched && touchPoint.y < touchOrigin.y))
		{
			pressed = pressed | FlxDirectionFlags.UP;
		}

		leftJustPressed = FlxG.keys.anyJustPressed(["A", "LEFT"]);
		rightJustPressed = FlxG.keys.anyJustPressed(["D", "RIGHT"]);
		downJustPressed = FlxG.keys.anyJustPressed(["S", "DOWN"]);
		upJustPressed = FlxG.keys.anyJustPressed(["W", "UP", "SPACE"]);
		jump = FlxG.keys.anyPressed(["SPACE"]);
		jumpJustPressed = FlxG.keys.anyJustPressed(["SPACE"]);
		action0 = FlxG.keys.anyPressed(["X", "PERIOD", "SLASH"]);
		action0JustPressed = FlxG.keys.anyJustPressed(["X", "PERIOD", "SLASH"]);
		action1 = FlxG.keys.anyPressed(["E", "SHIFT", "Z"]);
		action1JustPressed = FlxG.keys.anyJustPressed(["E", "SHIFT", "Z"]);

		/*if(FlxG.mouse.justPressed)
			{
				clickCount++;	
			}
			if(clickCount > 0)
			{
				clickTimer += FlxG.elapsed;
				if(clickTimer > clickDelay)
				{
					clickCount = 0;
					clickTimer = 0;
				}
			}
			if(clickCount == 2)
			{
				action0 = true;
				action0JustPressed = true;
				clickCount = 0;
				clickTimer = 0;
		}*/

		gamepad = FlxG.gamepads.lastActive;
		if (gamepad != null)
		{
			if (gamepad.anyPressed(["X", "Y"]))
			{
				pressed = pressed | FlxDirectionFlags.UP;
				jump = true;
			}
			jumpJustPressed = jumpJustPressed || gamepad.anyJustPressed(["X", "Y"]);
			upJustPressed = upJustPressed || gamepad.anyJustPressed(["X", "Y"]);

			action0 = action0 || gamepad.pressed.A;
			action0JustPressed = action0JustPressed || gamepad.anyJustPressed(["A"]);
			action1 = action1 || gamepad.pressed.B;
			action1JustPressed = action1JustPressed || gamepad.anyJustPressed(["B"]);

			if (gamepad.analog.justMoved.LEFT_STICK_X)
			{
				stickMovedX = true;
				stickJustMovedX = true;
			}
			else if (gamepad.analog.justReleased.LEFT_STICK_X)
			{
				stickMovedX = false;
			}
			if (gamepad.analog.justMoved.LEFT_STICK_Y)
			{
				stickMovedY = true;
				stickJustMovedY = true;
			}
			else if (gamepad.analog.justReleased.LEFT_STICK_Y)
			{
				stickMovedY = false;
			}

			if (stickMovedX)
			{
				analogX = gamepad.analog.value.LEFT_STICK_X;
				if (Math.abs(analogX) > .35)
				{
					if (analogX > 0)
					{
						pressed = pressed | FlxDirectionFlags.RIGHT;
						if (stickJustMovedX)
						{
							rightJustPressed = true;
						}
					}
					else if (analogX < 0)
					{
						pressed = pressed | FlxDirectionFlags.LEFT;
						if (stickJustMovedX)
						{
							leftJustPressed = true;
						}
					}
					stickRead = true;
					analogX = (Math.abs(analogX) - .35) / .65;
					// trace(analogX);
				}
			}
			if (stickMovedY)
			{
				if (gamepad.analog.value.LEFT_STICK_Y > .35)
				{
					pressed = pressed | FlxDirectionFlags.DOWN;
					if (stickJustMovedY)
					{
						downJustPressed = true;
					}
				}
				if (gamepad.analog.value.LEFT_STICK_Y < .35)
				{
					pressed = pressed | FlxDirectionFlags.UP;
					if (stickJustMovedY)
					{
						upJustPressed = true;
					}
				}
			}
		}

		if (upJustPressed)
		{
			upJustPressedSlow = true;
			upFrames = 15;
		}
		if (upFrames > 0)
		{
			upFrames--;
			if (upFrames <= 0)
			{
				upJustPressedSlow = false;
			}
		}
	}
}
