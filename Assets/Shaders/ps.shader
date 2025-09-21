Shader "Unlit/test2"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex MyTessellationVertexProgram
            #pragma fragment frag
            #pragma hull hull
            #pragma domain MyDomainProgram
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct VertexData {
	            UNITY_VERTEX_INPUT_INSTANCE_ID
	            float4 vertex : POSITION;
	            float2 uv : TEXCOORD0;
            };

            struct TessellationFactors {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            struct TessellationControlPoint {
	            float4 vertex : INTERNALTESSPOS;
	            float2 uv : TEXCOORD0;
            };

            struct InterpolatorsVertex {
	            float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            TessellationControlPoint MyTessellationVertexProgram (VertexData v) {
	            TessellationControlPoint p;
	            p.vertex = v.vertex;
	            p.uv = v.uv;
	            return p;
            }

            InterpolatorsVertex vert (VertexData v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.vertex = floor(o.vertex * 200) / 200;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex) * lerp(o.vertex.w, 1.0, 0.5);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            [UNITY_domain("tri")]
            [UNITY_outputcontrolpoints(3)]
            [UNITY_outputtopology("triangle_cw")]
            [UNITY_partitioning("integer")]
            [UNITY_patchconstantfunc("MyPatchConstantFunction")]
            TessellationControlPoint  hull (InputPatch<TessellationControlPoint , 3> patch, uint id : SV_OutputControlPointID) 
            {
	            return patch[id];
            }

            TessellationFactors MyPatchConstantFunction (InputPatch<TessellationControlPoint , 3> patch) {
	            TessellationFactors f;
                f.edge[0] = 2;
                f.edge[1] = 2;
                f.edge[2] = 2;
	            f.inside = 2;
	            return f;
            }

            [UNITY_domain("tri")]
            InterpolatorsVertex MyDomainProgram (TessellationFactors factors, OutputPatch<TessellationControlPoint, 3> patch, float3 barycentricCoordinates : SV_DomainLocation) 
            {
	            VertexData data;

	            #define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) data.fieldName = \
		            patch[0].fieldName * barycentricCoordinates.x + \
		            patch[1].fieldName * barycentricCoordinates.y + \
		            patch[2].fieldName * barycentricCoordinates.z;

	            MY_DOMAIN_PROGRAM_INTERPOLATE(vertex)
	            MY_DOMAIN_PROGRAM_INTERPOLATE(uv)

	            return vert(data);
            }

            fixed4 QuantizeColor(fixed4 color, uint steps)
            {
                return floor(color * steps) / steps;
            }

            fixed4 frag (InterpolatorsVertex i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv / lerp(i.vertex.w, 1.0, 0.5));
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return QuantizeColor(lerp(col * 0.3, fixed4(0.1, 0.1, 0.1, 0.1), i.vertex.w / 30.0), 32);
            }
            ENDCG
        }
    }
}
