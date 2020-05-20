//
//  shader.metal
//  Metallica
//
//  Created by Liang,Zhiyuan(MTD) on 2020/4/27.
//  Copyright © 2020 Liang,Zhiyuan(MTD). All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct SceneMatrices {
    float4x4 projectionMatrix;
    float4x4 viewModelMatrix;
};

struct SceneUniform {
    SceneMatrices meshMatrices;
    SceneMatrices shadowMatrices;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float3 shadow_coord;
    float4 modelPosition;
};
 
struct ShadowVertexOut {
    float4 position [[position]];
};

vertex VertexOut vertexShader(device float4* position [[buffer(0)]],
                            constant float4* color[[buffer(1)]],
                            const device SceneUniform& uniform [[buffer(2)]],
                            uint vid [[vertex_id]]) {
    VertexOut vert;
    vert.modelPosition = position[vid];
    vert.position = uniform.meshMatrices.projectionMatrix * uniform.meshMatrices.viewModelMatrix * position[vid];
//    vert.position = scene_matrices.projectionMatrix * position[vid];
//    vert.position.z = 0;
//    vert.position = vert.position/vert.position[3];
//    vert.position.z = vert.position.z/2 + 0.5;
    vert.color = color[vid];
    
    vert.shadow_coord = (uniform.shadowMatrices.projectionMatrix * uniform.shadowMatrices.viewModelMatrix * position[vid]).xyz;
    
    vert.shadow_coord.x *= 0.5;
    vert.shadow_coord.x += 0.5;

    vert.shadow_coord.y *= -0.5;
    vert.shadow_coord.y += 0.5;
    
    return vert;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]],
                               depth2d<float> shadowMap [[texture(3)]]) {
    
    constexpr sampler shadowSampler(coord::normalized,
                                    filter::linear,
                                    mip_filter::none,
                                    address::clamp_to_edge,
                                    compare_func::less);

    float2 shadowUV = in.shadow_coord.xy;

//    shadowUV.x += 0.5;
//    shadowUV.y += 0.5;
    
    // Compare the depth value in the shadow map to the depth value of the fragment in the sun's.
    // frame of reference.  If the sample is occluded, it will be zero.
    float shadow_sample = shadowMap.sample_compare(shadowSampler, shadowUV, in.shadow_coord.z);
    
//    return in.color * shadow_sample;
//    if (shadow_sample == 0) return in.color * 0.5;
    
    if (shadow_sample == 0) return float4(in.color.rgb * 0.5, in.color.a);
    
    return in.color;
}

fragment float4 fragmentShader2(VertexOut in [[stage_in]],
                               const device SceneUniform& uniform [[buffer(1)]],
                               depth2d<float> shadowMap [[texture(3)]]) {
    
    float3 shadow_coord = (uniform.shadowMatrices.projectionMatrix * uniform.shadowMatrices.viewModelMatrix * in.modelPosition).xyz;
    
    constexpr sampler shadowSampler(coord::normalized,
                                    filter::linear,
                                    mip_filter::none,
                                    address::clamp_to_edge,
                                    compare_func::less);

    // Compare the depth value in the shadow map to the depth value of the fragment in the sun's.
    // frame of reference.  If the sample is occluded, it will be zero.
    float shadow_sample = shadowMap.sample_compare(shadowSampler, shadow_coord.xy, shadow_coord.z);
    
//    return float4(in.color.xyz, shadow_sample);
    return in.color * shadow_sample;
}

//shadow
vertex ShadowVertexOut shadow_vertex(const device float4* position[[buffer(0) ]],
                                  constant SceneUniform& uniform[[buffer(2)]],
                                  uint vid[[vertex_id]])
{
    ShadowVertexOut out;
    out.position = uniform.shadowMatrices.projectionMatrix * uniform.shadowMatrices.viewModelMatrix * position[vid];
    return out;
}
