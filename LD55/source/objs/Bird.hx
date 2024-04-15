package objs;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxDirectionFlags;
import flixel.util.FlxTimer;
import util.FSM;
import util.Input;
import util.TimedBool;

enum MoveState
{
	Sleep;
	Idle;
	Flap;
	Glide;
	Fall;
	AirDash;
	AirBoost;
}

class Bird extends FlxSprite
{
	public static var instance:Bird;

	public var moveSpeed:Float = 0.75;
	public var groundBoost:Float = 3;
	public var airBoost:Float = 3;
	public var jumpStrength:Float = 8;
	public var jumpVariable:Float = 0.5;
	public var flapCount:Float = 0;
	public var flapStrength:Float = 45;
	public var currentFlapStrength:Float = 25;
	public var flapVariable:Float = 2;
	public var fallGravity:Float = 200;
	public var glideGravity:Float = 25;
	public var airDrag:Float = 250;
	public var moveDrag:Float = 0.5;
	public var airDashYStrength:Float = 20.0;
	public var airDashXStrength:Float = 0.25;
	public var airBoostXStrength:Float = 0.35;
	public var airBoostYStrength:Float = 350.0;
	public var diveStrength:Float = 200.0;
	public var floatStrength:Float = 25.0;
	public var maxDashVelocity = 400;
	public var maxYVelocity = 120;
	public var maxTotalSpeed = 2.5;
	public var maxSpeed = 1.5;

	public var elapsed:Float = 0;
	public var fsm:FSM;

	static public var control:Bool = true;

	// public var onGround:TimedBool;
	public var jumping:TimedBool;
	public var jumpCooldown:TimedBool;
	public var dashing:TimedBool;
	public var dashCooldown:TimedBool;
	public var delayedDash:Bool = false;

	public var dashCount:Int = 0;
	public var normalDashTime:Float = 0.25;

	public var followPoint:FlxPoint;
	public var followOffset:Float = 3;

	public var chirping:TimedBool;

	private var groundYOffset = 4;
	private var airYOffset = 2;

	private var edgeDraft = 400;

	public var portalLine:PortalLine;

	public function new(px:Float, py:Float)
	{
		super(px, py + 4);

		loadGraphic(AssetPaths.firebird__png, true, 16, 16);

		width = height = 8;
		centerOffsets();

		setFacingFlip(FlxDirectionFlags.RIGHT, false, false);
		setFacingFlip(FlxDirectionFlags.LEFT, true, false);
		facing = FlxDirectionFlags.RIGHT;

		maxVelocity.x = maxTotalSpeed;
		maxVelocity.y = maxYVelocity;
		drag.x = moveDrag;
		acceleration.y = 0;
		elasticity = 0;

		// onGround = new TimedBool(0.15);
		jumping = new TimedBool(0.2);
		jumpCooldown = new TimedBool(0.3);
		dashing = new TimedBool(normalDashTime);
		dashCooldown = new TimedBool(0.5);
		chirping = new TimedBool(0.15);

		animation.add("sleep", [0, 1], 5, true);
		animation.add("surprise", [2], 5, false);
		animation.add("stand", [3], 5, false);
		animation.add("flap", [4, 5], 10, false);
		animation.add("glide", [5, 6, 5, 7], 6, true);
		animation.add("hardglide", [13, 14, 13, 15], 10, true);
		animation.add("fall", [8, 9, 10], 10, true);
		animation.add("airDash", [11], 5, false);
		animation.add("boost", [12], 5, false);
		fsm = new FSM();

		fsm.addState(MoveState.Sleep, sleepEnter);
		fsm.addState(MoveState.Idle, idleEnter);
		fsm.addState(MoveState.Glide, glideEnter, glideUpdate, glideLeave);
		fsm.addState(MoveState.Flap, flapEnter, flapUpdate);
		fsm.addState(MoveState.Fall, fallEnter, fallUpdate);
		fsm.addState(MoveState.AirDash, airDashEnter, airDashUpdate, airDashLeave);
		fsm.addState(MoveState.AirBoost, airBoostEnter, airDashUpdate);
		fsm.switchState(MoveState.Sleep);

		portalLine = new PortalLine();

		control = true;
		instance = this;
	}

	override public function update(elapsed:Float):Void
	{
		portalLine.x = x;
		portalLine.y = y + 4;
		portalLine.angle = Math.atan((PlayState.instance.nextPortalPos.y - y)/(FlxG.width - x)) * 180.0/Math.PI;

		if (!control)
		{
			animation.update(elapsed);
			return;
		}
		this.elapsed = elapsed;

		dashCooldown.update(elapsed);
		dashing.update(elapsed);
		/*if (!dashCooldown.soft)
			{
				onGround.hard = isTouching(FlxDirectionFlags.FLOOR);
				onGround.update(elapsed);
		}*/
		jumping.update(elapsed);
		jumpCooldown.update(elapsed);
		chirping.update(elapsed);
		fsm.update();
		super.update(elapsed);

		if (Input.control.keys.get("action").justPressed)
		{
			G.playSound("short_chirp", 2);
			/*if (animation.frameIndex < 25)
				{
					animation.frameIndex += 25;
			}*/
			/*TrailEmitter.instance.x = x + 1;
				TrailEmitter.instance.y = y;
				TrailEmitter.instance.poof(); */

			chirping.trigger();
		}
		/*else if (chirping.soft && animation.frameIndex < 25)
			{
				animation.frameIndex += 25;
			}
			else if (animation.frameIndex >= 25 && !chirping.soft)
			{
				animation.frameIndex -= 25;
		}*/

		// prevent flooring below floor
		if (y > FlxG.height - 16)
		{
			velocity.y -= edgeDraft * elapsed;
			if (velocity.y < -50)
			{
				velocity.y = -50;
			}
		}
		if (y < 0)
		{
			velocity.y += edgeDraft * elapsed;
			if (velocity.y > 50)
			{
				velocity.y = 50;
			}
		}

		// scale.x = 1.0 + 0.1 * PlayState.instance.speedRatio;
		scale.y = 1.0 - 0.1 * PlayState.instance.speedRatio;
	}

	private function sleepEnter()
	{
		offset.y = groundYOffset;

		followOffset = 3;
		animation.play("sleep");
	}

	private function idleEnter()
	{
		offset.y = groundYOffset;

		followOffset = 3;
		animation.play("sleep");
		new FlxTimer().start(1, (timer:FlxTimer) ->
		{
			animation.play("surprise");
			timer.start(1, (timer:FlxTimer) ->
			{
				animation.play("stand");
				timer.start(1, (timer:FlxTimer) ->
				{
					fsm.switchState(MoveState.Glide);
				});
			});
		});
	}

	private function flapEnter()
	{
		drag.y = airDrag;
		followOffset = 2;
		animation.play("flap");
		jump(flapStrength, flapVariable);
		currentFlapStrength = flapStrength;
		acceleration.y = glideGravity;
		G.playSound("flap", 1, 1.75);
	}

	private function fallEnter()
	{
		drag.y = airDrag;
		followOffset = 2;
		velocity.y = 0;
		//acceleration.y = fallGravity;
		animation.play("fall");
		G.playSound("flap", 1, 1.75);
	}

	private function glideEnter()
	{
		drag.y = airDrag;
		followOffset = 2;
		acceleration.y = glideGravity;
		if (Math.abs(velocity.x) > maxSpeed)
		{
			animation.play("hardglide");
		}
		else
		{
			animation.play("glide");
		}
	}

	private function glideLeave()
	{
		animation.stop();
	}

	private function airDashEnter()
	{
		drag.y = airDrag;
		offset.y = airYOffset;
		acceleration.y = glideGravity;

		elasticity = 0.5;
		followOffset = 2;
		acceleration.y = 1;
		maxVelocity.y = maxDashVelocity;
		dashCooldown.trigger();
		dashing.trigger();
		// FlxG.sound.play(AssetPaths.dash__ogg);
		DustEmitter.instance.x = x;
		DustEmitter.instance.y = y + 5;

		/*trace("delayed left: " + Input.control.left.justPressedDelayed + " right: " + Input.control.right.justPressedDelayed + " up: "
				+ Input.control.up.justPressedDelayed + " down: " + Input.control.down.justPressedDelayed);
			trace("justpressed left: " + Input.control.left.justPressed + " right: " + Input.control.right.justPressed + " up: " + Input.control.up.justPressed
				+ " down: " + Input.control.down.justPressed);
			trace("pressed left: " + Input.control.left.pressed + " right: " + Input.control.right.pressed + " up: " + Input.control.up.pressed
				+ " down: " + Input.control.down.pressed); */

		delayedDash = !Input.control.anyJustPressed;

		var diagonal:Bool = Input.control.anyLeftRight;
		if (Input.control.left.justPressedDelayed)
		{
			facing = FlxDirectionFlags.LEFT;
		}
		if (Input.control.right.justPressedDelayed)
		{
			facing = FlxDirectionFlags.RIGHT;
		}
		animation.play("airDash");
		if (Input.control.up.pressed || Input.control.up.justPressedDelayed)
		{
			if (facing == FlxDirectionFlags.LEFT && diagonal)
			{
				velocity.x -= airDashXStrength;
				velocity.y -= airDashYStrength;
				// animation.play("airDashDiaUp");
				DustEmitter.instance.dashStartPoof(velocity);
				return;
			}
			if (facing == FlxDirectionFlags.RIGHT && diagonal)
			{
				velocity.x += airDashXStrength;
				velocity.y += airDashYStrength;
				// animation.play("airDashDiaUp");
				DustEmitter.instance.dashStartPoof(velocity);
				return;
			}

			velocity.y = -airDashYStrength;
			DustEmitter.instance.dashStartPoof(velocity);
			return;
		}
		if (Input.control.down.pressed || Input.control.down.justPressedDelayed)
		{
			if (facing == FlxDirectionFlags.LEFT && diagonal)
			{
				velocity.x -= airDashXStrength;
				velocity.y += airDashYStrength;
				// animation.play("airDashDiaDown");
				DustEmitter.instance.dashStartPoof(velocity);
				return;
			}
			if (facing == FlxDirectionFlags.RIGHT && diagonal)
			{
				velocity.x += airDashXStrength;
				velocity.y += airDashYStrength;
				// animation.play("airDashDiaDown");
				DustEmitter.instance.dashStartPoof(velocity);
				return;
			}

			velocity.y = airDashYStrength;
			DustEmitter.instance.dashStartPoof(velocity);
			return;
		}
		if (facing == FlxDirectionFlags.LEFT)
		{
			velocity.x -= airDashXStrength;
			DustEmitter.instance.dashStartPoof(velocity);
			return;
		}
		if (facing == FlxDirectionFlags.RIGHT)
		{
			velocity.x += airDashXStrength;
			DustEmitter.instance.dashStartPoof(velocity);
			return;
		}
	}

	private function airBoostEnter()
	{
		drag.y = airDrag;
		offset.y = airYOffset;
		acceleration.y = glideGravity;

		elasticity = 0.5;
		followOffset = 2;
		acceleration.y = 1;
		maxVelocity.y = maxDashVelocity;
		dashCooldown.trigger();
		dashing.trigger();
		// FlxG.sound.play(AssetPaths.dash__ogg);
		DustEmitter.instance.x = x;
		DustEmitter.instance.y = y + 5;

		delayedDash = !Input.control.anyJustPressed;

		var diagonal:Bool = Input.control.anyLeftRight;
		if (Input.control.left.justPressedDelayed)
		{
			facing = FlxDirectionFlags.LEFT;
		}
		if (Input.control.right.justPressedDelayed)
		{
			facing = FlxDirectionFlags.RIGHT;
		}
		animation.play("boost");
		if (Input.control.up.pressed || Input.control.up.justPressedDelayed)
		{
			if (facing == FlxDirectionFlags.LEFT && diagonal)
			{
				velocity.x -= airBoostXStrength;
				velocity.y -= airDashYStrength;
				// animation.play("airDashDiaUp");
				DustEmitter.instance.dashStartPoof(velocity);
				return;
			}
			if (facing == FlxDirectionFlags.RIGHT && diagonal)
			{
				velocity.x += airBoostXStrength;
				velocity.y += airDashYStrength;
				// animation.play("airDashDiaUp");
				DustEmitter.instance.dashStartPoof(velocity);
				return;
			}

			velocity.y = -airDashYStrength;
			DustEmitter.instance.dashStartPoof(velocity);
			return;
		}
		if (Input.control.down.pressed || Input.control.down.justPressedDelayed)
		{
			if (facing == FlxDirectionFlags.LEFT && diagonal)
			{
				velocity.x -= airBoostXStrength;
				velocity.y += airDashYStrength;
				// animation.play("airDashDiaDown");
				DustEmitter.instance.dashStartPoof(velocity);
				return;
			}
			if (facing == FlxDirectionFlags.RIGHT && diagonal)
			{
				velocity.x += airBoostXStrength;
				velocity.y += airDashYStrength;
				// animation.play("airDashDiaDown");
				DustEmitter.instance.dashStartPoof(velocity);
				return;
			}

			velocity.y = airDashYStrength;
			DustEmitter.instance.dashStartPoof(velocity);
			return;
		}
		if (facing == FlxDirectionFlags.LEFT)
		{
			velocity.x -= airBoostXStrength;
			DustEmitter.instance.dashStartPoof(velocity);
			return;
		}
		if (facing == FlxDirectionFlags.RIGHT)
		{
			velocity.x += airBoostXStrength;
			DustEmitter.instance.dashStartPoof(velocity);
			return;
		}
	}

	private function airDashLeave()
	{
		acceleration.y = glideGravity;
		maxVelocity.y = maxYVelocity;
		elasticity = 0;
	}

	private function flapUpdate()
	{
		if (canDash())
		{
			fsm.switchState(MoveState.AirDash);
			// onGround.hard = false;
			return;
		}
		if (!jumping.soft)
		{
			if (canDash())
			{
				fsm.switchState(MoveState.AirDash);
			}
			else if (Input.control.up.justPressed)
			{
				fsm.switchState(MoveState.Flap);
				return;
			}
			fsm.switchState(MoveState.Glide);
		}

		if (!Input.control.up.justPressed)
		{
			jump(jumpStrength, jumpVariable);
		}
		move(moveSpeed);
	}

	private function glideUpdate()
	{
		if (Input.control.up.pressed)
		{
			velocity.y -= elapsed * floatStrength;
		}

		if (canDash())
		{
			fsm.switchState(MoveState.AirDash);
		}
		else if (Input.control.up.justPressed)
		{
			fsm.switchState(MoveState.Flap);
			return;
		}
		else if (Input.control.down.justPressed)
		{
			fsm.switchState(MoveState.Fall);
			return;
		}
		if (Math.abs(velocity.x) + 0.01 > maxSpeed)
		{
			if (animation.name == "glide")
			{
				animation.play("hardglide");
			}
		}
		else
		{
			if (animation.name == "hardglide")
			{
				animation.play("glide");
			}
		}
		move(moveSpeed);
	}

	private function fallUpdate()
	{
		if (Input.control.down.pressed)
		{
			velocity.y += elapsed * diveStrength;
		}

		if (canDash())
		{
			fsm.switchState(MoveState.AirDash);
		}
		else if (Input.control.up.justPressed)
		{
			fsm.switchState(MoveState.Flap);
			return;
		}
		else if (!Input.control.down.pressed)
		{
			fsm.switchState(MoveState.Glide);
			return;
		}
		move(moveSpeed);
	}

	private function airDashUpdate()
	{
		if (Input.control.pressedBothY) {}
		else if (Input.control.up.pressed)
		{
			velocity.y -= elapsed * airBoostYStrength;
		}
		else if (Input.control.down.pressed)
		{
			velocity.y += elapsed * airBoostYStrength;
		}

		if (!dashing.soft)
		{
			fsm.switchState(MoveState.Glide);
		}
		else
		{
			DustEmitter.instance.x = x;
			DustEmitter.instance.y = y + 6;
			DustEmitter.instance.dashPoof();
			move(moveSpeed);
		}
	}

	private function canDash()
	{
		dashing.setDelay(normalDashTime);

		var attemptDash:Bool = (Input.control.keys.get("select").justPressed && !dashCooldown.soft);
		return attemptDash;
	}

	private function move(p_move_speed:Float)
	{
		DustEmitter.instance.x = x;
		DustEmitter.instance.y = y;
		DustEmitter.instance.constantPoof();

		if (Input.control.pressedBothX) {}
		else if (Input.control.left.pressed)
		{
			if (velocity.x > -maxSpeed)
			{
				velocity.x -= elapsed * p_move_speed;
			}
		}
		else if (Input.control.right.pressed)
		{
			if (velocity.x < maxSpeed)
			{
				velocity.x += elapsed * p_move_speed;
			}
		}
		if (velocity.x < 0)
		{
			facing = FlxDirectionFlags.LEFT;
		}
		else if (velocity.x > 0)
		{
			facing = FlxDirectionFlags.RIGHT;
		}
	}

	private function jump(p_jump_strength:Float, p_jump_variable:Float)
	{
		if (Input.control.up.justPressed)
		{
			velocity.y -= p_jump_strength;
			/*if (velocity.y < -jumpStrength && p_jump_strength == flapStrength)
				{
					velocity.y = -jumpStrength;
			}*/

			if (!jumping.soft)
			{
				jumping.trigger();
			}
			jumpCooldown.trigger();
			DustEmitter.instance.x = x;
			DustEmitter.instance.y = y;
			if (Input.control.left.justPressedDelayed)
			{
				// velocity.x -= airBoost;
				DustEmitter.instance.leftPoof();
			}
			else if (Input.control.right.justPressedDelayed)
			{
				// velocity.x += airBoost;
				DustEmitter.instance.rightPoof();
			}
			DustEmitter.instance.downPoof();
		}
		else if (Input.control.up.pressed && jumping.soft)
		{
			velocity.y -= elapsed * p_jump_variable;
		}

		if (Input.control.down.pressed)
		{
			// velocity.y += elapsed * p_move_speed;
		}
	}

	override function destroy()
	{
		super.destroy();
	}
}
