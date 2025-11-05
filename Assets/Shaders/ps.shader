Shader "Unlit/test2"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LightPos ("Light position", Vector) = (0, 0, 0, 0)
        _TessellationEdgeLength ("Tesselation edge length", Float) = 0.0
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
                float4 vertex : SV_POSITION;
                float3 world: TEXCOORD1;

            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _LightPos;
            float _TessellationEdgeLength;

            TessellationControlPoint MyTessellationVertexProgram (VertexData v) {
	            TessellationControlPoint p;
	            p.vertex = v.vertex;
	            p.uv = v.uv;
	            return p;
            }

            InterpolatorsVertex vert (VertexData v)
            {
                InterpolatorsVertex o;

                o.vertex = mul(UNITY_MATRIX_MV, v.vertex);

                o.vertex = floor(o.vertex * 75) / 75;

                o.vertex = mul(UNITY_MATRIX_P, o.vertex);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex) * o.vertex.w;
                o.world = mul(unity_ObjectToWorld, v.vertex);
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

            float TessellationEdgeFactor (
	            TessellationControlPoint cp0, TessellationControlPoint cp1
            ) {
	            float3 p0 = mul(unity_ObjectToWorld, float4(cp0.vertex.xyz, 1)).xyz;
		        float3 p1 = mul(unity_ObjectToWorld, float4(cp1.vertex.xyz, 1)).xyz;
		        float edgeLength = distance(p0, p1);

		        float3 edgeCenter = (p0 + p1) * 0.5;
		        float viewDistance = distance(edgeCenter, _WorldSpaceCameraPos);

		        return edgeLength * _ScreenParams.y / (_TessellationEdgeLength * viewDistance);
            }

            TessellationFactors MyPatchConstantFunction (InputPatch<TessellationControlPoint , 3> patch) {
	            TessellationFactors f;
                f.edge[0] = TessellationEdgeFactor(patch[1], patch[2]);
                f.edge[1] = TessellationEdgeFactor(patch[0], patch[2]);
                f.edge[2] = TessellationEdgeFactor(patch[0], patch[1]);
	            f.inside = (f.edge[0] + f.edge[1] + f.edge[2]) * (1 / 3.0);;
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
                fixed4 col = QuantizeColor(tex2D(_MainTex, i.uv / i.vertex.w), 32);

                // Hardcoded light position
                float3 lightPos = _LightPos.xyz;

                // Compute lighting
                float3 dpdx = ddx(i.world);
	            float3 dpdy = ddy(i.world);
	            float3 normal = normalize(cross(dpdy, dpdx));
                float3 lightVec = lightPos - i.world;
                float light = max(0, dot(normal, normalize(lightVec)));
                float attenuation = 1.0 / dot(lightVec, lightVec);

                return lerp(col*0.03 + col*light*attenuation, fixed4(0.0, 0.0, 0.0, 0.0), i.vertex.w / 10.0);
            }
            ENDCG
        }
    }
}
