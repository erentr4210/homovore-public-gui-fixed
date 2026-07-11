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

// Vertical half of the separable glow blur, both source and target at half
// resolution. InSampler holds the horizontal-pass result (premultiplied colour in
// .rgb, coverage in .a), so blurring is a plain linear accumulation. Normalising
// each pass independently is valid because the 2D kernel is separable:
// sum(wx*wy) = sum(wx)*sum(wy).
void main() {
    float step = 2.0 / ScreenSize.y;          // one half-res texel, in UV space
    int taps = (GlowRadius + 1) / 2;
    float invSpan = 1.0 / float(GlowRadius + 1);

    vec3 cAcc = vec3(0.0);
    float aAcc = 0.0;
    float wSum = 0.0;
    for (int i = -taps; i <= taps; i++) {
        float d = float(i * 2);
        float t = 1.0 - d * invSpan * d * invSpan;
        float w = max(t, 0.0);
        w *= w;

        vec4 s = texture(InSampler, texCoord + vec2(0.0, float(i) * step));
        cAcc += w * s.rgb;
        aAcc += w * s.a;
        wSum += w;
    }

    float invW = 1.0 / wSum;
    fragColor = vec4(cAcc * invW, aAcc * invW);
}
