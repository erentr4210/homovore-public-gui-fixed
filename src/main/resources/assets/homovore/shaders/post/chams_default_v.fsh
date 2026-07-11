#version 330

uniform sampler2D InSampler;
uniform sampler2D ColorSampler;
uniform sampler2D OrigSampler;

layout(std140) uniform Globals {
    ivec3 CameraBlockPos;
    vec3 CameraOffset;
    vec2 ScreenSize;
    float GlintAlpha;
    float GameTime;
    int MenuBlurRadius;
    int UseRgss;
};

layout(std140) uniform ChamsConfig {
    float GlowIntensity;
    float FillTint;
    float FillAlpha;
    int GlowThickness;
    int LineWidth;
};

in vec2 texCoord;
out vec4 fragColor;

void main() {
    vec2 texel = 1.0 / ScreenSize;
    vec4 center = texture(OrigSampler, texCoord);

    if (center.a > 0.0) {
        fragColor = vec4(center.rgb * FillTint, center.a * FillAlpha);
        return;
    }

    int radius = max(LineWidth, GlowThickness);
    float invSpan = 1.0 / float(GlowThickness + 1);

    // Single vertical pass: color propagation (ColorSampler), line dilation
    // (InSampler.r) and glow accumulation (InSampler.g) all share one fetch of
    // each sampler per tap instead of three separate neighbourhood loops.
    vec3 cAcc = vec3(0.0);
    float wAcc = 0.0;
    float maxA = 0.0;
    float acc = 0.0;
    float wSum = 0.0;
    for (int y = -radius; y <= radius; y++) {
        vec2 offset = texel * vec2(0.0, float(y));

        vec4 c = texture(ColorSampler, texCoord + offset);
        cAcc += c.rgb;
        wAcc += c.a;

        vec2 rg = texture(InSampler, texCoord + offset).rg;

        if (abs(y) <= LineWidth) {
            maxA = max(maxA, rg.r);
        }
        if (abs(y) <= GlowThickness) {
            float t = 1.0 - float(y) * invSpan * float(y) * invSpan;
            float w = t * t;
            acc  += w * rg.g;
            wSum += w;
        }
    }

    vec3 col = wAcc > 0.0001 ? cAcc / wAcc : vec3(1.0);

    if (LineWidth > 0 && maxA > 0.0) {
        fragColor = vec4(col, maxA);
        return;
    }

    if (GlowThickness > 0) {
        float coverage = acc / wSum;
        float glow = clamp(pow(GlowIntensity * coverage, 0.72) * 1.35, 0.0, 1.0);
        if (glow > 0.0) {
            fragColor = vec4(col, glow);
            return;
        }
    }

    fragColor = vec4(0.0);
}
