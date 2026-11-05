// [Sprint 06, the owner 2026-11-05: "not flying in the air"] The soft dark contact where a boot or the ball meets the
// grass: the floodlights stand far and high, so their own shadows fall soft and away from the feet and nothing marks
// the contact. One mesh of quads for every foot and the ball (ContactShadows.cs), in one draw: each quad's alpha in its
// vertex colour, its falloff from its UV (0 at the centre, 1 at the rim), no texture. Unlit, over the grass, never
// writing depth, so it never hides a player.
Shader "Legends/ContactShadow"
{
    Properties
    {
        _BaseColor ("Shadow colour", Color) = (0.02, 0.05, 0.02, 1)
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent-50" "IgnoreProjector" = "True" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off

        Pass
        {
            Name "ContactShadow"
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
            CBUFFER_END

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; half4 color : COLOR; };
            struct Varyings { float4 positionCS : SV_POSITION; float2 uv : TEXCOORD0; half4 color : COLOR; };

            Varyings Vert(Attributes v)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.uv * 2.0 - 1.0;
                o.color = v.color;
                return o;
            }

            half4 Frag(Varyings i) : SV_Target
            {
                half r2 = saturate(dot(i.uv, i.uv));
                half a = (1.0 - r2);
                a = a * a * i.color.a;                       // dark at the contact, nothing at the rim
                return half4(_BaseColor.rgb, a);
            }
            ENDHLSL
        }
    }
}
