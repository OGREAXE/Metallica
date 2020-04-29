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

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

vertex VertexOut vertexShader(device float4* position [[buffer(0)]],
                            constant float4* color[[buffer(1)]],
                            const device SceneMatrices& scene_matrices [[buffer(2)]],
                            uint vid [[vertex_id]]) {
    VertexOut vert;
    vert.position = scene_matrices.projectionMatrix * scene_matrices.viewModelMatrix * position[vid];
//    vert.position = scene_matrices.projectionMatrix * position[vid];
//    vert.position.z = 0;
    vert.position = vert.position/vert.position[3];
    vert.position.z = vert.position.z/2 + 0.5;
    vert.color = color[vid];
    return vert;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]]) {
    return in.color;
}
