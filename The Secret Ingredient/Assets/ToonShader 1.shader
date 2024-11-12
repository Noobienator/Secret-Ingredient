Shader "Supyrb/Unlit/CameraBasedOutline"
{
    Properties
    {
        [HDR]_Color("Albedo", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _EdgeDarkenFactor("Edge Darken Factor", Range(0, 1)) = 0.5
        _EdgeSaturationFactor("Edge Saturation Factor", Range(0, 1)) = 0.5
        _EdgeThreshold("Edge Threshold", Range(0, 1)) = 0.7

        [Header(Stencil)]
        _Stencil ("Stencil ID [0;255]", Float) = 0
        _ReadMask ("ReadMask [0;255]", Int) = 255
        _WriteMask ("WriteMask [0;255]", Int) = 255
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilOp ("Stencil Operation", Int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilFail ("Stencil Fail", Int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilZFail ("Stencil ZFail", Int) = 0

        [Header(Rendering)]
        _Offset("Offset", float) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _Culling ("Cull Mode", Int) = 2
        [Enum(Off,0,On,1)] _ZWrite("ZWrite", Int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4
        [Enum(None,0,Alpha,1,Red,8,Green,4,Blue,2,RGB,14,RGBA,15)] _ColorMask("Color Mask", Int) = 15
    }
   
    CGINCLUDE
    #include "UnityCG.cginc"
 
    half4 _Color;
    sampler2D _MainTex;
    float4 _MainTex_ST;
    float _EdgeDarkenFactor;
    float _EdgeSaturationFactor;
    float _EdgeThreshold;
   
    struct appdata
    {
        float4 vertex : POSITION;
        float3 normal : NORMAL;
        float2 uv : TEXCOORD0;
    };
 
    struct v2f
    {
        float2 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
        float fresnelFactor : TEXCOORD1;
    };
 
    v2f vert (appdata v)
    {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        
        // Calculate the view direction based on the camera's position
        float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
        float3 viewDir = normalize(_WorldSpaceCameraPos - worldPos);
        
        // Calculate Fresnel term based on view direction and normal, creating a camera-dependent outline
        o.fresnelFactor = 1.0 - saturate(dot(viewDir, v.normal));

        return o;
    }
   
    half4 frag (v2f i) : SV_Target
    {
        // Sample base color
        half4 baseColor = tex2D(_MainTex, i.uv) * _Color;
        
        // Apply sharp edge threshold to Fresnel factor for a sharp outline
        half edgeFactor = step(_EdgeThreshold, i.fresnelFactor) * _EdgeDarkenFactor;
        half saturationFactor = step(_EdgeThreshold, i.fresnelFactor) * _EdgeSaturationFactor;
        
        // Adjust brightness and saturation for edges
        baseColor.rgb *= (1.0 - edgeFactor); // Darken edges
        baseColor.rgb = lerp(baseColor.rgb, saturate(baseColor.rgb), saturationFactor); // Saturate edges

        return baseColor;
    }
   
    ENDCG
       
    SubShader
    {
        Stencil
        {
            Ref [_Stencil]
            ReadMask [_ReadMask]
            WriteMask [_WriteMask]
            Comp [_StencilComp]
            Pass [_StencilOp]
            Fail [_StencilFail]
            ZFail [_StencilZFail]
        }
       
        Pass
        {
            Tags { "RenderType"="Opaque" "Queue" = "Geometry" }
            LOD 100
            Cull [_Culling]
            Offset [_Offset], [_Offset]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
            ColorMask [_ColorMask]
           
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
       
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            LOD 80
            Cull [_Culling]
            Offset [_Offset], [_Offset]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
           
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_shadowcaster
            ENDCG
        }
    }
}
