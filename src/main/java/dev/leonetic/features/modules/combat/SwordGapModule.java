package dev.leonetic.features.modules.combat;

import dev.leonetic.Homovore;
import dev.leonetic.features.modules.Module;
import dev.leonetic.util.inventory.InventoryUtil;
import dev.leonetic.util.inventory.Result;
import dev.leonetic.util.inventory.ResultType;
import net.minecraft.tags.ItemTags;
import net.minecraft.world.item.Items;

import java.util.EnumSet;

public class SwordGapModule extends Module {

    private boolean latched;

    public SwordGapModule() {
        super("SwordGap", "Switches from sword to gap while holding right click.", Category.COMBAT);
    }

    @Override
    public void onDisable() {
        releaseLatch();
    }

    @Override
    public void onTick() {
        if (nullCheck()) {
            releaseLatch();
            return;
        }

        // A silent swap may have interrupted our latch; re-sync so we can re-latch while RMB is held.
        if (latched && !Homovore.swapManager.isLatched()) latched = false;

        boolean useHeld = mc.options.keyUse.isDown();

        if (useHeld && !latched) {
            if (!mc.player.getMainHandItem().is(ItemTags.SWORDS)) return;

            Result apple = InventoryUtil.find(Items.ENCHANTED_GOLDEN_APPLE, EnumSet.of(ResultType.HOTBAR));
            if (apple.found() && Homovore.swapManager.latch(apple)) latched = true;
        } else if (!useHeld && latched) {
            releaseLatch();
        }
    }

    private void releaseLatch() {
        if (!latched) return;
        Homovore.swapManager.release();
        latched = false;
    }
}
