//
//  IridescenceShaderTypes.h
//  acusia
//
//  Created by decoherence on 1/28/25.
//
#ifndef IridescenceShaderTypes_h
#define IridescenceShaderTypes_h

#ifdef __METAL_VERSION__
#define TEXTURE_2D metal::texture2d<half>
#else
#define TEXTURE_2D uint64_t
#endif

typedef struct {
    float3 baseColor;
    float3 cameraPosition;
    float roughness;
    float iridescenceFactor;
    float iridescenceIor;
    float iridescenceThicknessMin;
    float iridescenceThicknessMax;
//    TEXTURE_2D iridescenceTexture;
//    TEXTURE_2D thicknessTexture;
} IridescenceUniforms;

#endif /* IridescenceShaderTypes_h */
