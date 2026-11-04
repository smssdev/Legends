// [Sprint 06 U6] The kit: every club's from the same mesh (tools/unity/players/kit.py). The mesh says where each
// piece is and where the trim goes (vertex colour: R the trim, G the front, B the piece), and where the pattern and
// the number fall ('pattern' UV, the second: u across the body, v from the hem to the shoulders). The club's colours,
// its pattern (App\Data\KitPattern: plain, stripes, hoops, halves, sash) and the player's number come from KitColours
// through each player's MaterialPropertyBlock. Drawing only.
Shader "Legends/Kit"
{
    Properties
    {
        _BaseColor ("Shirt", Color) = (0.78, 0.06, 0.18, 1)
        _TrimColor ("Trim and pattern", Color) = (1, 1, 1, 1)
        _ShortsColor ("Shorts", Color) = (0.11, 0.17, 0.28, 1)
        _SocksColor ("Socks", Color) = (0.78, 0.06, 0.18, 1)
        _BootsColor ("Boots", Color) = (0.08, 0.09, 0.11, 1)
        _NumberColor ("Number", Color) = (1, 1, 1, 1)
        _OutlineColor ("Number outline (patterned shirts)", Color) = (0, 0, 0, 1)
        _Pattern ("Pattern (0 plain, 1 stripes, 2 hoops, 3 halves, 4 sash)", Float) = 0
        _Number ("Number (-1 none)", Float) = -1
        [NoScaleOffset] _Numbers ("Digits 0-9 (Players/Textures/numbers.png)", 2D) = "black" {}
        _Smoothness ("Smoothness", Range(0, 1)) = 0.3
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" }
        Cull Off

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor, _TrimColor, _ShortsColor, _SocksColor, _BootsColor, _NumberColor, _OutlineColor;
            float _Pattern, _Number;
            half _Smoothness;
        CBUFFER_END
        TEXTURE2D(_Numbers);
        SAMPLER(sampler_Numbers);
        #include "PlayerLit.hlsl"

        // The pattern's share of the second colour at this point of the shirt.
        half Pattern(float2 p)
        {
            int kind = (int)round(_Pattern);
            if (kind == 1) return fmod(floor(p.x * 9.0), 2.0);                    // nine vertical stripes
            if (kind == 2) return fmod(floor(p.y * 7.0), 2.0);                    // seven hoops
            if (kind == 3) return step(0.5, p.x);                                 // the wearer's left half
            if (kind == 4) return step(abs(p.x + p.y - 1.0), 0.16);               // a sash, right shoulder to left hip
            return 0;
        }

        half Digit(float2 st, int d)
        {
            if (any(st < 0) || any(st > 1)) return 0;
            return SAMPLE_TEXTURE2D(_Numbers, sampler_Numbers, float2((d + st.x) / 10.0, st.y)).a;
        }

        // The number in a box (st 0..1 across it): one digit in the middle, two side by side.
        half NumberIn(float2 st)
        {
            int n = (int)round(_Number);
            if (n < 0) return 0;
            n = min(n, 99);
            if (n < 10) return Digit(float2(st.x * 2.0 - 0.5, st.y), n);
            return st.x < 0.5 ? Digit(float2(st.x * 2.0, st.y), n / 10) : Digit(float2(st.x * 2.0 - 1.0, st.y), n % 10);
        }

        // Where it goes: big on the back, small on the wearer's right chest. The box in pattern units (u is 0.5 m,
        // v about 0.48 m): 25 cm high on the back, 9 cm on the chest, each digit two thirds as wide as high.
        float2 NumberBox(float2 p, half front)
        {
            float4 box = front > 0.5 ? float4(0.30, 0.78, 0.24, 0.19) : float4(0.50, 0.60, 0.66, 0.52);   // centre u, v, size u, v
            float2 st = (p - box.xy) / box.zw + 0.5;
            if (front < 0.5) st.x = 1.0 - st.x;   // seen from behind, u runs right to left
            return st;
        }

        // The number's outline: the figure grown by about 4% of the box each way (eight samples around it).
        half Outline(float2 st)
        {
            const float r = 0.04;
            half o = 0;
            [unroll] for (int k = 0; k < 8; k++)
            {
                float a = k * 0.785398;
                o = max(o, NumberIn(st + float2(cos(a), sin(a) * 0.66) * r));
            }
            return o;
        }

        half3 Albedo(Varyings i)
        {
            half trim = i.color.r;
            half piece = i.color.b;
            float2 p = i.uv.zw;
            if (piece > 0.83) return _BootsColor.rgb;
            if (piece > 0.5) return lerp(_SocksColor.rgb, _TrimColor.rgb, trim);
            if (piece > 0.17) return lerp(_ShortsColor.rgb, _TrimColor.rgb, trim);
            half3 shirt = lerp(_BaseColor.rgb, _TrimColor.rgb, max(trim, Pattern(p)));
            float2 st = NumberBox(p, i.color.g);
            half fill = NumberIn(st);
            // On a patterned shirt the number is outlined in the shirt's own colour, so the stripes never swallow it.
            if (_Pattern > 0.5) shirt = lerp(shirt, _OutlineColor.rgb, Outline(st) * (1 - fill));
            return lerp(shirt, _NumberColor.rgb, fill);
        }

        half Coverage(Varyings i) { return 1; }
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
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile _ _CLUSTER_LIGHT_LOOP
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            half4 Frag(Varyings i, FRONT_FACE_TYPE face : FRONT_FACE_SEMANTIC) : SV_Target
            {
                return Lit(i, IS_FRONT_VFACE(face, 1, -1));
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            ZWrite On
            ColorMask 0
            HLSLPROGRAM
            #pragma vertex ShadowVert
            #pragma fragment NothingFrag
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }
            ZWrite On
            ColorMask R
            HLSLPROGRAM
            #pragma vertex DepthVert
            #pragma fragment NothingFrag
            ENDHLSL
        }
    }
}
