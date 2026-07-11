package dev.leonetic.mixin.entity;

import net.minecraft.core.particles.ColorParticleOption;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;

@Mixin(ColorParticleOption.class)
public interface ColorParticleOptionAccessor {

    @Accessor("color")
    int homovore$getColor();
}
