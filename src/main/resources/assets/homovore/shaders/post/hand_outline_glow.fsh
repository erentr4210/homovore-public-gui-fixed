#version 330

uniform sampler2D InSampler;
uniform sampler2D GlowSampler;
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

layout(std140) uniform OutlineConfig {
    float FillAlpha;
    float OutlineAlpha;
    float GlowIntensity;
    int LineWidth;
    int GlowRadius;
};

in vec2 texCoord;
out vec4 fragColor;

void main() {
    vec4 orig = texture(OrigSampler, texCoord);
    if (orig.a > 0.0) {

        fragColor = FillAlpha > 0.0 ? vec4(orig.rgb, FillAlpha) : vec4(0.0);
        return;
    }

    vec2 texel = 1.0 / ScreenSize;

    if (LineWidth > 0) {
        float maxA = 0.0;
        vec3 col = vec3(0.0);
        for (int y = -LineWidth; y <= LineWidth; y++) {
            vec4 s = texture(InSampler, texCoord + texel * vec2(0.0, float(y)));
            if (s.a > maxA) {
                maxA = s.a;
                col = s.rgb;
            }
        }
        if (maxA > 0.0) {
            fragColor = vec4(col, OutlineAlpha);
            return;
        }
    }

    if (GlowRadius > 0) {
        // Glow is fully blurred in the half-res GLOW_V target; a single bilinear
        // fetch upsamples it. .rgb is premultiplied colour, .a is coverage.
        vec4 g = texture(GlowSampler, texCoord);
        float coverage = g.a;
        if (coverage > 0.0001) {
            vec3 col = g.rgb / coverage;
            float glow = clamp(pow(GlowIntensity * coverage, 0.72) * 1.35, 0.0, 1.0);
            if (glow > 0.0) {
                fragColor = vec4(col, glow);
                return;
            }
        }
    }

    fragColor = vec4(0.0);
}
