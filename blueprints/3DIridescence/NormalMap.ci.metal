// Create a normal map out of a 2D B&W image where the black represents height and white represents baseline.

#include <metal_stdlib>
using namespace metal;
#include <CoreImage/CoreImage.h>

float lumaAtOffset(coreimage::sampler source, float2 origin, float2 offset) {
    float3 pixel = coreimage::sample(source, samplerTransform(source, origin + offset)).rgb;
    return dot(pixel, float3(0.2126, 0.7152, 0.0722));
}

extern "C" float4 normalMap(coreimage::sampler image, coreimage::destination dest)
{
    float2 d = dest.coord();
    
    float northLuma = lumaAtOffset(image, d, float2(0.0, -1.0));
    float southLuma = lumaAtOffset(image, d, float2(0.0, 1.0));
    float westLuma = lumaAtOffset(image, d, float2(-1.0, 0.0));
    float eastLuma = lumaAtOffset(image, d, float2(1.0, 0.0));
    
    float horizontalSlope = ((westLuma - eastLuma) + 1.0) * 0.5;
    float verticalSlope = ((northLuma - southLuma) + 1.0) * 0.5;
    
    return float4(horizontalSlope, verticalSlope, 1.0, 1.0);
}
