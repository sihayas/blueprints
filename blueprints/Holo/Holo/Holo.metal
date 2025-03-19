#include <metal_stdlib>
using namespace metal;


struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
    float3 worldNormal;
    float3 worldPosition;
};

struct VertexIn {
    float3 position [[attribute(0)]];
    float2 normal [[attribute(1)]];
};

struct Uniforms {
    float4x4 modelMatrix;
    float4x4 viewProjectionMatrix;
    float3 lightDirection;
    float padding;
    float rotationAngleX;
    float rotationAngleY;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                             constant Uniforms &uniforms [[buffer(1)]]) {
    float4 worldPosition = uniforms.modelMatrix * float4(in.position, 1.0);
    VertexOut out {
        .position = uniforms.viewProjectionMatrix * worldPosition,
        .texCoord = in.normal,
        .worldNormal = normalize((uniforms.modelMatrix * float4(in.position, 0.0)).xyz),
        .worldPosition = worldPosition.xyz
    };
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant Uniforms &uniforms [[buffer(1)]],
                              texture2d<float> rampTexture [[texture(0)]],
                              texture2d<float> noiseTexture [[texture(1)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);

    // Sample the noise texture (keep it independent of the ramp)
    float3 noiseColor = noiseTexture.sample(textureSampler, in.texCoord).rgb;

    // Sample the normal map and combine with the world normal
    float3 normalMap = noiseColor * 2.0 - 1.0;
    float3 normal = normalize(in.worldNormal);

    // Adjust the bump strength
    float3 fullNormal = normalize(normal + normalMap * 1.0);

    // Calculate the dot product between the light direction and the full normal
    float NdotL = dot(uniforms.lightDirection, fullNormal);

    // Scale the ramp effect to stretch the gradient
    // Adjust this value to stretch or compress the gradient
    float rampScale = 0.25;

    // Calculate the rotation effect for vertical progression, scaled
    float rotationEffect = (1.0 - in.texCoord.y) * uniforms.rotationAngleX * rampScale;

    // Ramp texture coordinates, with a scaled NdotL
    float2 rampUV = float2((NdotL * 0.5 + 0.5 + rotationEffect) * rampScale, 0.5);
    float3 rampColor = rampTexture.sample(textureSampler, rampUV).rgb;

    // Blend the noise with the ramp color
    // Adjust blending factor as needed
    float3 finalColor = mix(rampColor, noiseColor, 0.25);

    return float4(finalColor, 1.0);
}
