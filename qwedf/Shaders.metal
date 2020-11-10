//
//  Shaders.metal
//  qwedf
//
//  Created by Dávid Németh Cs. on 2020. 11. 10..
//

#include <metal_stdlib>
using namespace metal;

kernel void compute_shader(texture2d<float, access::read> input [[texture(0)]],
                    texture2d<float, access::write> output [[texture(1)]],
                    uint2 gid [[thread_position_in_grid]])
{
    float4 color = input.read(gid);
    if(color.a > 0){
        output.write(float4(color.r, color.g, color.b, 0.2), gid);
    }
}
