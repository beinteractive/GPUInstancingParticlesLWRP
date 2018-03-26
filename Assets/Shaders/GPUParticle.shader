﻿// ------------------------------------------
// Only directional light is supported for lit particles
// No shadow
// No distortion
Shader "GPUParticle"
{
    Properties
    {
        _MainTex("Albedo", 2D) = "white" {}
        _Color("Color", Color) = (1,1,1,1)

        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        _MetallicGlossMap("Metallic", 2D) = "white" {}
        [Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5

        _BumpScale("Scale", Float) = 1.0
        _BumpMap("Normal Map", 2D) = "bump" {}

        _EmissionColor("Color", Color) = (0,0,0)
        _EmissionMap("Emission", 2D) = "white" {}

        _SoftParticlesNearFadeDistance("Soft Particles Near Fade", Float) = 0.0
        _SoftParticlesFarFadeDistance("Soft Particles Far Fade", Float) = 1.0
        _CameraNearFadeDistance("Camera Near Fade", Float) = 1.0
        _CameraFarFadeDistance("Camera Far Fade", Float) = 2.0

        // Hidden properties
        [HideInInspector] _Mode("__mode", Float) = 0.0
        [HideInInspector] _FlipbookMode("__flipbookmode", Float) = 0.0
        [HideInInspector] _LightingEnabled("__lightingenabled", Float) = 1.0
        [HideInInspector] _EmissionEnabled("__emissionenabled", Float) = 0.0
        [HideInInspector] _BlendOp("__blendop", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _Cull("__cull", Float) = 2.0
        [HideInInspector] _SoftParticlesEnabled("__softparticlesenabled", Float) = 0.0
        [HideInInspector] _CameraFadingEnabled("__camerafadingenabled", Float) = 0.0
        [HideInInspector] _SoftParticleFadeParams("__softparticlefadeparams", Vector) = (0,0,0,0)
        [HideInInspector] _CameraFadeParams("__camerafadeparams", Vector) = (0,0,0,0)
    }

    SubShader
    {
        Tags{"RenderType" = "Opaque" "IgnoreProjector" = "True" "PreviewType" = "Plane" "PerformanceChecks" = "False" "RenderPipeline" = "LightweightPipeline"}

        BlendOp[_BlendOp]
        Blend[_SrcBlend][_DstBlend]
        ZWrite[_ZWrite]
        Cull[_Cull]

        Pass
        {
            Tags {"LightMode" = "LightweightForward"}
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma vertex ParticlesLitVertex
            #pragma fragment ParticlesLitFragment
            #pragma multi_compile __ SOFTPARTICLES_ON
            #pragma target 2.0

            #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON _ALPHAMODULATE_ON
            #pragma shader_feature _METALLICGLOSSMAP
            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _EMISSION
            #pragma shader_feature _FADING_ON
            #pragma shader_feature _REQUIRE_UV2

            #define NO_SHADOWS 1
            
            #pragma multi_compile_instancing
            #pragma instancing_options procedural:vertInstancingSetup
            
            #include "CoreRP/ShaderLibrary/UnityInstancing.hlsl"
            #include "LWRP/ShaderLibrary/Particles.hlsl"
            #include "LWRP/ShaderLibrary/Lighting.hlsl"
            #include "ParticleInstancing.hlsl"
            
            // Vertex shader input
            struct appdata_particles_instanced
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                half4 color : COLOR;
            #if defined(_FLIPBOOK_BLENDING) && !defined(UNITY_PARTICLE_INSTANCING_ENABLED)
                float4 texcoords : TEXCOORD0;
                float texcoordBlend : TEXCOORD1;
            #else
                float2 texcoords : TEXCOORD0;
            #endif
            #if defined(_NORMALMAP)
                float4 tangent : TANGENT;
            #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            VertexOutputLit ParticlesLitVertex(appdata_particles_instanced v)
            {
                VertexOutputLit o;
                UNITY_SETUP_INSTANCE_ID(v);
                OUTPUT_NORMAL(v, o);

                o.color = v.color * _Color;
                o.posWS.xyz = TransformObjectToWorld(v.vertex.xyz).xyz;
                o.posWS.w = ComputeFogFactor(o.clipPos.z);
                o.clipPos = TransformWorldToHClip(o.posWS.xyz);
                o.viewDirShininess.xyz = VertexViewDirWS(GetCameraPositionWS() - o.posWS.xyz);
                vertTexcoord(v, o);
                vertFading(o, o.posWS, o.clipPos);
                return o;
            }

            half4 ParticlesLitFragment(VertexOutputLit IN) : SV_Target
            {
                SurfaceData surfaceData;
                InitializeSurfaceData(IN, surfaceData);

                InputData inputData;
                InitializeInputData(IN, surfaceData.normalTS, inputData);

                half4 color = LightweightFragmentPBR(inputData, surfaceData.albedo,
                    surfaceData.metallic, half3(0, 0, 0), surfaceData.smoothness, surfaceData.occlusion, surfaceData.emission, surfaceData.alpha);
                ApplyFog(color.rgb, inputData.fogCoord);
                return color;
            }

            ENDHLSL
        }
    }

    Fallback "LightweightPipeline/Particles/Standard (Simple Lighting)"
    CustomEditor "LightweightStandardParticlesShaderGUI"
}