// [Sprint 06 U6] What the players' own shaders share (Kit.shader, Stubble.shader): the vertex with its colour and
// second UV, URP's own PBR lighting (so a kit is lit like everything else in the scene), the shadow caster and the
// depth pass. Each shader includes this after its UnityPerMaterial buffer and gives Albedo() (and Coverage()).
#ifndef LEGENDS_PLAYER_LIT
#define LEGENDS_PLAYER_LIT

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 color : COLOR;
    float2 uv0 : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float3 positionWS : TEXCOORD0;
    float3 normalWS : TEXCOORD1;
    float4 color : TEXCOORD2;
    float4 uv : TEXCOORD3;      // xy the first UV, zw the second ('pattern' on the kit)
    float fog : TEXCOORD4;
    UNITY_VERTEX_OUTPUT_STEREO
};

Varyings Vert(Attributes v)
{
    Varyings o = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    VertexPositionInputs p = GetVertexPositionInputs(v.positionOS.xyz);
    o.positionCS = p.positionCS;
    o.positionWS = p.positionWS;
    o.normalWS = TransformObjectToWorldNormal(v.normalOS);
    o.color = v.color;
    o.uv = float4(v.uv0, v.uv1);
    o.fog = ComputeFogFactor(p.positionCS.z);
    return o;
}

half3 Albedo(Varyings i);
half Coverage(Varyings i);

half4 Lit(Varyings i, half facing)
{
    InputData d = (InputData)0;
    d.positionWS = i.positionWS;
    d.positionCS = i.positionCS;
    d.normalWS = normalize(i.normalWS) * facing;   // a kit is seen from both sides: its inside is lit as an inside
    d.viewDirectionWS = GetWorldSpaceNormalizeViewDir(i.positionWS);
    d.shadowCoord = TransformWorldToShadowCoord(i.positionWS);
    d.fogCoord = i.fog;
    d.bakedGI = SampleSH(d.normalWS);
    d.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(i.positionCS);
    d.shadowMask = half4(1, 1, 1, 1);

    SurfaceData s = (SurfaceData)0;
    s.albedo = Albedo(i);
    s.metallic = 0;
    s.specular = 0;
    s.smoothness = _Smoothness;
    s.occlusion = 1;
    s.alpha = Coverage(i);
    half4 c = UniversalFragmentPBR(d, s);
    c.rgb = MixFog(c.rgb, d.fogCoord);
    c.a = s.alpha;
    return c;
}

// ---------------------------------------------------------------- shadows and depth
float3 _LightDirection;
float3 _LightPosition;

float4 ShadowVert(Attributes v) : SV_POSITION
{
    UNITY_SETUP_INSTANCE_ID(v);
    float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
    float3 normalWS = TransformObjectToWorldNormal(v.normalOS);
#if _CASTING_PUNCTUAL_LIGHT_SHADOW
    float3 toLight = normalize(_LightPosition - positionWS);
#else
    float3 toLight = _LightDirection;
#endif
    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, toLight));
#if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
#else
    positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
#endif
    return positionCS;
}

float4 DepthVert(Attributes v) : SV_POSITION
{
    UNITY_SETUP_INSTANCE_ID(v);
    return TransformObjectToHClip(v.positionOS.xyz);
}

half4 NothingFrag() : SV_Target { return 0; }

#endif
