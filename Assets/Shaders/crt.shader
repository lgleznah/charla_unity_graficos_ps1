Shader "ColorBlit"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100
        ZWrite Off Cull Off
        Pass
        {
            Name "ColorBlitPass"

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            // The Blit.hlsl file provides the vertex shader (Vert),
            // the input structure (Attributes) and the output structure (Varyings)
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            #pragma vertex Vert
            #pragma fragment frag

            // Set the color texture from the camera as the input texture
            TEXTURE2D_X(_CameraOpaqueTexture);
            SAMPLER(sampler_CameraOpaqueTexture);

            // Set up an intensity parameter
            float _Intensity;

            half4 frag (Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                // CRT curvature
                float2 uv = input.texcoord*2-1;
                float lf = 1./(pow(length(uv), 3.)*.1 + 1.);
                uv /= lf;
                uv = uv *.5 + .5;

                float4 color = SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, uv);
                color = (max(uv.x, uv.y) > 1. || min(uv.x, uv.y) < 0.) ? float4(0,0,0,0) : color;

                // CRT bands
                color *= sin(uv.x*1000.0)*.1+.9;
                color *= sin(uv.y*100.0+_Time*5.)*.3+1.3;

                // CRT noise
                float noise = frac(sin(dot(uv,float2(12.9898 + (float)_Time, 78.233 - (float)_Time)))*43758.5453123);
                color *= noise*.3+.7;

                // Output the color from the texture, with the green value set to the chosen intensity
                return color;
            }
            ENDHLSL
        }
    }
}