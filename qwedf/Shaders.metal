//
//  Shaders.metal
//  qwedf
//
//  Created by Dávid Németh Cs. on 2020. 11. 10..
//

#include <metal_stdlib>
using namespace metal;

kernel void compute_shader(
                           texture2d<float, access::read> input1 [[texture(0)]],
                           texture2d<float, access::read> input2 [[texture(1)]],
                           texture2d<float, access::write> output [[texture(2)]],
                           uint2 gid [[thread_position_in_grid]])
{
    float4 color1 = input1.read(gid);
    float4 color2 = input2.read(gid);
   
    float a1 = color1.a;
    float a2 = color2.a * (1-a1);
    output.write(float4(
                        (color1.r * a1 + color2.r * a2) / (a1 + a2),
                        (color1.g * a1 + color2.g * a2) / (a1 + a2),
                        (color1.b * a1 + color2.b * a2) / (a1 + a2),
                        1
               ), gid);
   
}
