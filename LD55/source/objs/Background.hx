package objs;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxShader;

/**
 * ...
 * @author aeveis
 */
class Background extends FlxSprite
{
    public var bgShader:BackgroundShader;
    public var time:Float = 0.0;
    public var waveTime:Float = 0.0;
    public var prevTime:Float = 0.0;
    public var speed:Float = 0.0;
	public function new()
	{
		super(0, 0);
        makeGraphic(FlxG.width, FlxG.height);
        bgShader = new BackgroundShader();
        shader = bgShader;
	}

    override function update(elapsed:Float) {
        super.update(elapsed);
        time += elapsed * PlayState.instance.speedRatio;
        waveTime += elapsed;
        bgShader.time.value = [time];
        bgShader.waveTime.value = [waveTime];
        speed = time - prevTime;
        prevTime = time;
    }
}



class BackgroundShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		#ifdef GL_ES
			precision mediump float;
		#endif
		
		uniform float time;
		uniform float waveTime;

        // Some useful functions
        vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
        vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
        vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }
        
        //
        // Description : GLSL 2D simplex noise function
        //      Author : Ian McEwan, Ashima Arts
        //  Maintainer : ijm
        //     Lastmod : 20110822 (ijm)
        //     License :
        //  Copyright (C) 2011 Ashima Arts. All rights reserved.
        //  Distributed under the MIT License. See LICENSE file.
        //  https://github.com/ashima/webgl-noise
        //
        float snoise(vec2 v) {
        
            // Precompute values for skewed triangular grid
            const vec4 C = vec4(0.211324865405187,
                                // (3.0-sqrt(3.0))/6.0
                                0.366025403784439,
                                // 0.5*(sqrt(3.0)-1.0)
                                -0.577350269189626,
                                // -1.0 + 2.0 * C.x
                                0.024390243902439);
                                // 1.0 / 41.0
        
            // First corner (x0)
            vec2 i  = floor(v + dot(v, C.yy));
            vec2 x0 = v - i + dot(i, C.xx);
        
            // Other two corners (x1, x2)
            vec2 i1 = vec2(0.0);
            i1 = (x0.x > x0.y)? vec2(1.0, 0.0):vec2(0.0, 1.0);
            vec2 x1 = x0.xy + C.xx - i1;
            vec2 x2 = x0.xy + C.zz;
        
            // Do some permutations to avoid
            // truncation effects in permutation
            i = mod289(i);
            vec3 p = permute(
                    permute( i.y + vec3(0.0, i1.y, 1.0))
                        + i.x + vec3(0.0, i1.x, 1.0 ));
        
            vec3 m = max(0.5 - vec3(
                                dot(x0,x0),
                                dot(x1,x1),
                                dot(x2,x2)
                                ), 0.0);
        
            m = m*m ;
            m = m*m ;
        
            // Gradients:
            //  41 pts uniformly over a line, mapped onto a diamond
            //  The ring size 17*17 = 289 is close to a multiple
            //      of 41 (41*7 = 287)
        
            vec3 x = 2.0 * fract(p * C.www) - 1.0;
            vec3 h = abs(x) - 0.5;
            vec3 ox = floor(x + 0.5);
            vec3 a0 = x - ox;
        
            // Normalise gradients implicitly by scaling m
            // Approximation of: m *= inversesqrt(a0*a0 + h*h);
            m *= 1.79284291400159 - 0.85373472095314 * (a0*a0+h*h);
        
            // Compute final noise value at P
            vec3 g = vec3(0.0);
            g.x  = a0.x  * x0.x  + h.x  * x0.y;
            g.yz = a0.yz * vec2(x1.x,x2.x) + h.yz * vec2(x1.y,x2.y);
            return 130.0 * dot(m, g);
        }

		void main()
		{	
			vec2 uv = openfl_TextureCoordv;
            uv.x = floor(uv.x * openfl_TextureSize.x * 2.0)/(openfl_TextureSize.x * 2.0);
            uv.y = floor(uv.y * openfl_TextureSize.y * 2.0)/(openfl_TextureSize.y * 2.0);

            vec4 col = vec4(1.0, 1.0, 1.0, 1.0);
            float perY = uv.y * uv.y;
            float posx = mod(uv.x + time, 3.14);
            float pos2x = mod(2.0 * uv.x + time, 3.14);
            float cloudx = mod((uv.x + time / 100.0), 3.14);
            float cloudy = perY - 0.2;

            col.rgb = mix(vec3(0.271, 0.722, 0.678), vec3(0.412, 0.871, 0.875), floor(perY * 10.0)/10.0 );

            float cloudDetail = (snoise(vec2(cloudx * 2.5, cloudy * 60.0)) - 0.5) * 0.025;
            float clouds = snoise(vec2(cloudx + cloudDetail, cloudy * 3.0 + waveTime/150.0));
            col.rgb = mix(col.rgb, vec3(0.773, 0.906, 0.906), step(0.75, clouds) * 0.75);

            //float wwTime = waveTime + time;
            //float waterWave = (sin(uv.x * 50.0 + wwTime)) * 0.0025;
            float waterSurface = 0.9;
            waterSurface += 0.0;
            col.rgb = mix(col.rgb, vec3(0.294, 0.639, 0.522), step(waterSurface, uv.y));

            float surface = 0.85 + (sin(posx) * sin(2.0 * posx) * 0.1 + 0.02 * sin(uv.x * sin(uv.x)));
            col.rgb = mix(col.rgb, vec3(0.180, 0.329, 0.224), step(surface, uv.y));
            
            float treeDetail = (snoise(vec2(posx * 2.5, uv.y * 25.0)) - 0.5) * 0.025;
            float treeXNoise = (snoise(vec2(posx * 2.0, uv.y * 3.0)) - 0.5) * 0.05;
            float tree =  snoise(vec2(posx * 3.0 + treeDetail + treeXNoise * 0.5, 0.0)) * (uv.y * 2.0 + treeXNoise) * (1.0 - smoothstep(surface, surface + 0.1, uv.y));
            tree *= tree;
            col.rgb = mix(col.rgb, vec3(0.280, 0.429, 0.324), step(0.75, tree));
            //col.rgb = tree;

			gl_FragColor = col;
		}
	')
	public function new()
	{
		super();
	}
}
