//
//  Iridescence.metal
//  acusia
//
//  Created by decoherence on 7/24/24.
//
#include <simd/simd.h>
#include <metal_stdlib>

using namespace metal;

#include <SceneKit/scn_metal>

struct NodeBuffer {
    float4x4 modelViewProjectionTransform;
    float4x4 modelViewTransform;
    float3x3 normalTransform;
};

struct FragmentUniforms {
    float time;
    float3 cameraPosition;
    float3 baseColor;
    float roughness;
    float iridescenceFactor;
    float iridescenceIor;
    float iridescenceThicknessMin;
    float iridescenceThicknessMax;
};

constexpr sampler textureSampler(filter::linear, address::repeat);

struct VertexInput {
    float3 position [[attribute(SCNVertexSemanticPosition)]];
    float3 normal [[attribute(SCNVertexSemanticNormal)]];
    float2 textureCoordinate [[attribute(SCNVertexSemanticTexcoord0)]];
    float4 tangent [[attribute(SCNVertexSemanticTangent)]];
};

struct VertexOutput {
    float4 position [[position]];
    float3 worldPosition;
    float3 worldNormal;
    float2 textureCoordinate;
    float3 worldTangent;
    float3 worldBitangent;
};

vertex VertexOutput vertexShader(VertexInput in [[stage_in]],
                                 constant NodeBuffer& scn_node [[buffer(1)]],
                                 constant FragmentUniforms &uniforms [[buffer(2)]]) {
    VertexOutput out;

    out.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
    out.worldPosition = (scn_node.modelViewTransform * float4(in.position, 1.0)).xyz;
    out.worldNormal = normalize(scn_node.normalTransform * in.normal);
    out.textureCoordinate = in.textureCoordinate;
    
    float3 worldTangent = normalize(scn_node.normalTransform * in.tangent.xyz);
    float3 worldBitangent = normalize(cross(out.worldNormal, worldTangent) * in.tangent.w);
    out.worldTangent = worldTangent;
    out.worldBitangent = worldBitangent;

    return out;
}

// Helper functions for Fresnel, GGX, and Smith geometry
float3 fresnelSchlick(float cosTheta, float3 F0) {
    // Schlick's approximation for Fresnel factor
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

float distributionGGX(float NdotH, float roughness) {
    // GGX distribution function
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH2 = NdotH * NdotH;
    float denom = NdotH2 * (a2 - 1.0) + 1.0;
    return a2 / (M_PI_F * denom * denom);
}

float geometrySmith(float NdotV, float NdotL, float roughness) {
    // Smith's method for geometry term
    float r = roughness + 1.0;
    float k = (r * r) / 8.0;
    float ggx1 = NdotV / (NdotV * (1.0 - k) + k);
    float ggx2 = NdotL / (NdotL * (1.0 - k) + k);
    return ggx1 * ggx2;
}

// Iridescence helper functions
float IorToFresnel0(float transmittedIor, float incidentIor) {
    // Convert IOR to Fresnel reflectance at normal incidence
    return pow((transmittedIor - incidentIor) / (transmittedIor + incidentIor), 2.0);
}

float3 IorToFresnel0(float3 transmittedIor, float incidentIor) {
    // Convert IOR to Fresnel reflectance at normal incidence (vector version)
    return pow((transmittedIor - float3(incidentIor)) / (transmittedIor + float3(incidentIor)), 2.0);
}

float3 evalSensitivity(float OPD, float3 shift) {
    // Evaluate color sensitivity based on optical path difference (OPD)
    float phase = 2.0 * M_PI_F * OPD * 1.0e-9;
    float3 val(5.4856e-13, 4.4201e-13, 5.2481e-13);
    float3 pos(1.6810e+06, 1.7953e+06, 2.2084e+06);
    float3 var(4.3278e+09, 9.3046e+09, 6.6121e+09);
    
    float3 xyz = val * sqrt(2.0 * M_PI_F * var) * cos(pos * phase + shift) * exp(-phase * phase * var);
    xyz.x += 9.7470e-14 * sqrt(2.0 * M_PI_F * 4.5282e+09) * cos(2.2399e+06 * phase + shift.x) * exp(-4.5282e+09 * phase * phase);
    xyz /= 1.0685e-7;
    
    const float3x3 XYZ_TO_REC709 = float3x3(
        3.2404542, -0.9692660,  0.0556434,
        -1.5371385,  1.8760108, -0.2040259,
        -0.4985314,  0.0415560,  1.0572252
    );
    
    return XYZ_TO_REC709 * xyz;
}

float3 iridescenceFresnel(float outsideIor, float iridescenceIor, float3 baseF0, float iridescenceThickness, float cosTheta1) {
    // Calculate Fresnel reflectance for iridescence
    float sinTheta2Sq = pow(outsideIor / iridescenceIor, 2.0) * (1.0 - pow(cosTheta1, 2.0));
    float cosTheta2Sq = 1.0 - sinTheta2Sq;
    
    if (cosTheta2Sq < 0.0) {
        return float3(1.0);  // Total internal reflection
    }
    
    float cosTheta2 = sqrt(cosTheta2Sq);
    
    // Reflectance at interface between air and thin film
    float R0 = IorToFresnel0(iridescenceIor, outsideIor);
    float R12 = fresnelSchlick(cosTheta1, float3(R0)).x;
    float T121 = 1.0 - R12;
    float phi12 = (iridescenceIor < outsideIor) ? M_PI_F : 0.0;
    float phi21 = M_PI_F - phi12;
    
    // Reflectance at interface between thin film and base material
    float3 baseIor = outsideIor * baseF0 + float3(1.0 - baseF0);
    float3 R1 = IorToFresnel0(baseIor, iridescenceIor);
    float3 R23 = fresnelSchlick(cosTheta2, R1);
    
    float3 phi23 = float3((baseIor.r < iridescenceIor) ? M_PI_F : 0.0,
                          (baseIor.g < iridescenceIor) ? M_PI_F : 0.0,
                          (baseIor.b < iridescenceIor) ? M_PI_F : 0.0);
    
    float OPD = 2.0 * iridescenceIor * iridescenceThickness * cosTheta2;
    float3 phi = float3(phi21) + phi23;
    
    float3 R123 = clamp(R12 * R23, 1e-5, 0.9999);
    float3 r123 = sqrt(R123);
    float3 Rs = pow(T121, 2.0) * R23 / (float3(1.0) - R123);
    
    float3 C0 = R12 + Rs;
    float3 I = C0;
    
    // Add contributions from multiple reflections
    float3 Cm = Rs - T121;
    for (int m = 1; m <= 2; ++m) {
        Cm *= r123;
        float3 Sm = 2.0 * evalSensitivity(float(m) * OPD, float(m) * phi);
        I += Cm * Sm;
    }
    
    return max(I, float3(0.0));
}


fragment float4 fragmentShader(VertexOutput in [[stage_in]],
                               constant FragmentUniforms& uniforms [[buffer(0)]],
                               texture2d<float> normalMap [[texture(0)]]) {
    // Sample normal map
    float3 normalColor = normalMap.sample(textureSampler, in.textureCoordinate).xyz;
    normalColor = normalColor * 2.0 - 1.0; // Transform from [0,1] to [-1,1]

    // Construct TBN matrix from individual vectors
    float3x3 tbnMatrix = float3x3(in.worldTangent, in.worldBitangent, in.worldNormal);
    
    // Transform normal from tangent space to world space
    float3 N = normalize(tbnMatrix * normalColor);

    // Existing code to calculate lighting
    float3 V = normalize(uniforms.cameraPosition - in.worldPosition);
    float3 L = normalize(float3(1.0, 1.0, 1.0)); // Directional light
    float3 H = normalize(V + L);

    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float NdotH = max(dot(N, H), 0.0);
    float HdotV = max(dot(H, V), 0.0);

    float3 F0 = uniforms.baseColor;
    float iridescence = uniforms.iridescenceFactor;
    float thickness = mix(uniforms.iridescenceThicknessMin, uniforms.iridescenceThicknessMax, iridescence);
    float3 F_iridescence = iridescenceFresnel(1.0, uniforms.iridescenceIor, F0, thickness, NdotV);
    float3 F = mix(fresnelSchlick(HdotV, F0), F_iridescence, iridescence);

    float D = distributionGGX(NdotH, uniforms.roughness);
    float G = geometrySmith(NdotV, NdotL, uniforms.roughness);
    float3 specular = (D * F * G) / (4.0 * NdotV * NdotL + 0.0001);

    float3 color = specular * NdotL;
    color = color / (color + 1.0);
    color = pow(color, 1.0 / 2.2);

    return float4(color, 1.0);
}

//    fragment float4 fragmentShader(VertexOutput in [[stage_in]],
//                               constant FragmentUniforms& uniforms [[buffer(0)]],
//                               texture2d<float> normalMap [[texture(0)]],
//                               texture2d<float> environmentMap [[texture(1)]]) {
//    // Sample normal map
//    float3 normalColor = normalMap.sample(textureSampler, in.textureCoordinate).xyz;
//    normalColor = normalColor * 2.0 - 1.0; // Transform from [0,1] to [-1,1]
//
//    // Construct TBN matrix from individual vectors
//    float3x3 tbnMatrix = float3x3(in.worldTangent, in.worldBitangent, in.worldNormal);
//
//    // Transform normal from tangent space to world space
//    float3 N = normalize(tbnMatrix * normalColor);
//
//    // Existing code to calculate lighting
//    float3 V = normalize(uniforms.cameraPosition - in.worldPosition);
//    float3 L = normalize(float3(1.0, 1.0, 1.0)); // Directional light
//    float3 H = normalize(V + L);
//
//    float NdotV = max(dot(N, V), 0.0);
//    float NdotL = max(dot(N, L), 0.0);
//    float NdotH = max(dot(N, H), 0.0);
//    float HdotV = max(dot(H, V), 0.0);
//
//    float3 F0 = uniforms.baseColor;
//    float iridescence = uniforms.iridescenceFactor;
//    float thickness = mix(uniforms.iridescenceThicknessMin, uniforms.iridescenceThicknessMax, iridescence);
//    float3 F_iridescence = iridescenceFresnel(1.0, uniforms.iridescenceIor, F0, thickness, NdotV);
//    float3 F = mix(fresnelSchlick(HdotV, F0), F_iridescence, iridescence);
//
//    float D = distributionGGX(NdotH, uniforms.roughness);
//    float G = geometrySmith(NdotV, NdotL, uniforms.roughness);
//    float3 specular = (D * F * G) / (4.0 * NdotV * NdotL + 0.0001);
//
//    // Sample the environment map (2D texture)
//    float3 reflectDir = reflect(-V, N);
//
//    // Convert reflectDir to UV coordinates for 2D texture sampling
//    float2 uv = float2(atan2(reflectDir.z, reflectDir.x) / (2.0 * M_PI_F) + 0.5, acos(reflectDir.y) / M_PI_F);
//
//    float3 envColor = environmentMap.sample(textureSampler, uv).rgb;
//
//    // Combine environment reflection with specular highlights
//    float3 color = specular + envColor * F;
//
//    color = color / (color + 1.0);
//    color = pow(color, 1.0 / 2.2);
//
//    return float4(color, 1.0);
//}
