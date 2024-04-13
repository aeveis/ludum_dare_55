package ui;

import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxShader;

/**
 * ...
 * @author aeveis
 */
class MapCover extends FlxSprite
{
	public var layer0:Array<Float>;
	public var layer1:Array<Float>;
	public var layer2:Array<Float>;
	public var layer3:Array<Float>;

	public var mapShader:MapCoverShader;

	public var mapSize:Int = 8;

	public function new(px:Float, py:Float)
	{
		super(px, py, AssetPaths.mapcover__png);

		layer0 = new Array<Float>();
		layer1 = new Array<Float>();
		layer2 = new Array<Float>();
		layer3 = new Array<Float>();

		for (i in 0...16)
		{
			layer0.push(1.0);
			layer1.push(1.0);
			layer2.push(1.0);
			layer3.push(1.0);
		}

		mapShader = new MapCoverShader();
		shader = mapShader;
		setShaderValues();
	}

	public function setShaderValues()
	{
		mapShader.layer0.value = layer0;
		mapShader.layer1.value = layer1;
		mapShader.layer2.value = layer2;
		mapShader.layer3.value = layer3;
	}

	public function revealCell(xIndex:Int, yIndex:Int)
	{
		var index:Int = xIndex + mapSize * yIndex;
		if (index < 16)
		{
			layer0[index] = 0.0;
		}
		else if (index < 32)
		{
			layer1[index - 16] = 0.0;
		}
		else if (index < 48)
		{
			layer2[index - 32] = 0.0;
		}
		else if (index < 64)
		{
			layer3[index - 48] = 0.0;
		}
		setShaderValues();
	}
}

class MapCoverShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		#ifdef GL_ES
			precision mediump float;
		#endif
		
		uniform mat4 layer0;
		uniform mat4 layer1;
		uniform mat4 layer2;
		uniform mat4 layer3;

        float setCell(vec2 uv, float on, float xindex, float yindex)
        {
            float mask = float(
                uv.x > (xindex * 0.125) && 
                uv.x < ((xindex + 1.0) * 0.125) && 
                uv.y > (yindex * 0.125) && 
                uv.y < ((yindex + 1.0) * 0.125)
                );

            return mask * on;
        }

        float setCells(vec2 uv)
        {
            float mask = 0.0;
            float mapsize = 8.0;
            for (int xi = 0; xi < 4; xi+=1)
            {
                for (int yi = 0; yi < 4; yi+=1)
                {
                    float index = float(xi + yi * 4);
                    float xindex = mod(index,mapsize);
                    float yindex = floor(index/mapsize);

                    mask += setCell(uv, layer0[yi][xi], xindex, yindex);
                    mask += setCell(uv, layer1[yi][xi], xindex, yindex+2.0);
                    mask += setCell(uv, layer2[yi][xi], xindex, yindex+4.0);
                    mask += setCell(uv, layer3[yi][xi], xindex, yindex+6.0);
                }
            }
            
            return mask;
        }

		void main()
		{
			vec2 uv = openfl_TextureCoordv;
			vec4 col = texture2D(bitmap, uv);

            col.a = setCells(uv);
			col *= col.a;
			
			gl_FragColor = col;
		}
	')
	public function new()
	{
		super();
	}
}
