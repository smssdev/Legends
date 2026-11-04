// [Sprint 06 U6] The shaved head (Hair_buzz, made in tools/unity/players/build_players.py buzz()): short hair seen from
// a metre, in the hair's colour, its cover the vertex colour's alpha (1 on the scalp, fading to 0 at the hairline)
// times fine noise, so the skin shows through and the hairline is soft. The hair's colour comes from PlayerLook.
Shader "Legends/Stubble"
{
    Properties
    {
        _BaseColor ("Hair colour", Color) = (0.17, 0.15, 0.13, 1)
        _Cover ("Most cover", Range(0, 1)) = 0.9
        _Smoothness ("Smoothness", Range(0, 1)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            half _Cover, _Smoothness;
        CBUFFER_END
        #include "PlayerLit.hlsl"

        half Hash(float2 p)
        {
            return frac(sin(dot(floor(p), float2(12.9898, 78.233))) * 43758.5453);
        }

        half3 Albedo(Varyings i) { return _BaseColor.rgb; }

        half Coverage(Varyings i)
        {
            half grain = lerp(0.4, 1.0, Hash(i.uv.xy * 900.0));   // never bare, never solid: hair over skin
            return saturate(i.color.a) * grain * _Cover;
        }
        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile _ _CLUSTER_LIGHT_LOOP
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            half4 Frag(Varyings i) : SV_Target { return Lit(i, 1); }
            ENDHLSL
        }
    }
}
