#include <metal_stdlib>
using namespace metal;

// Procedural animated mesh-gradient background with a centered morphing
// "iridescent blob" shape, evoking the Block-inspired reference without
// literal 3D geometry (design.md - "Rendering: SwiftUI Canvas + Metal
// layer-effect shaders, not SceneKit/RealityKit").
//
// `intensity` scales motion speed/highlight strength (restrained state
// uses a low value); `morphAmount` scales how much the shape's edge
// wobbles away from a circle (zeroed when Reduce Motion is enabled, so
// the shape renders as a static soft circle).
[[ stitchable ]]
half4 ambientCanvas(float2 position, half4 currentColor,
                     float width, float height, float time,
                     float colorAR, float colorAG, float colorAB,
                     float colorBR, float colorBG, float colorBB,
                     float colorCR, float colorCG, float colorCB,
                     float intensity, float morphAmount) {
    float2 size = float2(width, height);
    float minDim = min(size.x, size.y);
    float2 uv = (position - size * 0.5) / minDim;

    float3 colorA = float3(colorAR, colorAG, colorAB);
    float3 colorB = float3(colorBR, colorBG, colorBB);
    float3 colorC = float3(colorCR, colorCG, colorCB);

    float speed = 0.15 + intensity * 0.25;

    // Three soft, slowly-orbiting radial blobs blended together for a
    // mesh-gradient background.
    float2 p1 = float2(cos(time * speed * 0.35), sin(time * speed * 0.45)) * 0.7;
    float2 p2 = float2(cos(time * speed * 0.28 + 2.1), sin(time * speed * 0.38 + 2.1)) * 0.7;
    float2 p3 = float2(cos(time * speed * 0.22 + 4.2), sin(time * speed * 0.31 + 4.2)) * 0.7;

    float d1 = length(uv - p1);
    float d2 = length(uv - p2);
    float d3 = length(uv - p3);

    float w1 = 1.0 / (d1 * d1 + 0.08);
    float w2 = 1.0 / (d2 * d2 + 0.08);
    float w3 = 1.0 / (d3 * d3 + 0.08);
    float wsum = w1 + w2 + w3;

    float3 background = (colorA * w1 + colorB * w2 + colorC * w3) / wsum;

    // Centered morphing shape: a circle whose radius wobbles with angle
    // and time, softened at the edge, shaded with a rotating highlight
    // band for an iridescent-fold feel.
    float angle = atan2(uv.y, uv.x);
    float baseRadius = 0.3;
    float wobble = sin(angle * 3.0 + time * 0.6 * (0.4 + intensity)) * 0.6
                 + sin(angle * 5.0 - time * 0.37 * (0.4 + intensity)) * 0.4;
    float radius = baseRadius * (1.0 + morphAmount * wobble * 0.35);

    float dist = length(uv) - radius;
    float shapeAlpha = 1.0 - smoothstep(0.0, 0.03, dist);

    float highlight = pow(max(0.0, sin(angle * 2.0 - time * 0.5 * (0.4 + intensity))), 6.0);
    float3 shapeBase = mix(colorB, colorC, 0.5 + 0.5 * sin(angle * 2.0 + time * 0.3));
    float3 shapeColor = shapeBase + highlight * (0.3 + intensity * 0.4);

    float3 final = mix(background, shapeColor, shapeAlpha);
    final = clamp(final, 0.0, 1.0);

    return half4(half3(final), 1.0);
}
