#version 330

uniform sampler2D InSampler;

layout(std140) uniform Globals {
    ivec3 CameraBlockPos;
    vec3 CameraOffset;
    vec2 ScreenSize;
    float GlintAlpha;
    float GameTime;
    int MenuBlurRadius;
    int UseRgss;
};

layout(std140) uniform GlowConfig {
    int GlowRadius;
};

in vec2 texCoord;
out vec4 fragColor;

// Horizontal half of the separable glow blur. Runs into a half-resolution target,
// so one output texel spans two full-res source texels; combined with bilinear
// filtering on InSampler each fetch already averages a texel pair. We therefore
// step in half-res texels and take ~GlowRadius/2 taps instead of the full span.
//
// Output packs a premultiplied, weight-normalised colour in .rgb and the blurred
// coverage in .a so the vertical pass can keep accumulating linearly.
void main() {
    float step = 2.0 / ScreenSize.x;          // one half-res texel, in UV space
    int taps = (GlowRadius + 1) / 2;          // taps per side at half resolution
    float invSpan = 1.0 / float(GlowRadius + 1);

    vec3 cAcc = vec3(0.0);
    float aAcc = 0.0;
    float wSum = 0.0;
    for (int i = -taps; i <= taps; i++) {
        float d = float(i * 2);               // full-res pixel distance from centre
        float t = 1.0 - d * invSpan * d * invSpan;
        float w = max(t, 0.0);
        w *= w;

        vec4 s = texture(InSampler, texCoord + vec2(float(i) * step, 0.0));
        cAcc += w * s.a * s.rgb;
        aAcc += w * s.a;
        wSum += w;
    }

    float invW = 1.0 / wSum;                   // wSum >= 1 (centre tap weight is 1)
    fragColor = vec4(cAcc * invW, aAcc * invW);
}
