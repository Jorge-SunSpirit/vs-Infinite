package shaders;

import flixel.FlxG;
import flixel.system.FlxAssets.FlxShader;

class ReflectionShader extends FlxShader
{
    @:glFragmentSource("
        #pragma header

        uniform vec2 resolution;
        uniform float reflectAlpha;
        uniform float startHeight;
        uniform float alphaAdd;

        vec4 transformColor(vec4 color)
        {
            if (!hasTransform)
            {
                return color;
            }

            if (color.a == 0.0)
            {
                return vec4(0.0, 0.0, 0.0, 0.0);
            }

            if (hasColorTransform)
            {
                color = vec4(color.rgb / color.a, color.a);

                mat4 colorMultiplier = mat4(0);
                colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
                colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
                colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
                colorMultiplier[3][3] = openfl_ColorMultiplierv.w;

                color = clamp(openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);
            }

            if (color.a > 0.0)
            {
                return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
            }
            return vec4(0.0, 0.0, 0.0, 0.0);
        }

        float map(float value, float min1, float max1, float min2, float max2)
        {
            return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
        }

		void main(void)
		{
            vec4 tex = texture2D(bitmap, openfl_TextureCoordv.st);
            gl_FragColor = transformColor(vec4(tex.rgb, tex.a * clamp((1 - map(gl_FragCoord.t/resolution.y, 0, 1, startHeight, 1)) + alphaAdd, 0, 1) * reflectAlpha));
		}")

    public function new(alpha:Float = 1, alphaAdd:Float = 0.1, startHeight:Float = 0.1)
    {
        super();

        data.resolution.value = [FlxG.stage.stageWidth, FlxG.stage.stageWidth];
        data.reflectAlpha.value = [alpha];
        data.startHeight.value = [startHeight];
        data.alphaAdd.value = [alphaAdd];
    }
}