using System;
using System.Linq;
using System.Reflection;
using HarmonyLib;
using Verse;

namespace RJWAnimalTextures
{
    // Sized Apparel's dev action "Set BodyPart Variation" lists the variations from
    // SizedApparelBodyPartDetail.variationDef. That field is only filled in CompPostMake, when the
    // hediff is created, and is not saved. After a save is loaded it is null, so the menu shows a
    // single "default" entry whose action does nothing. Before the menu opens, fill in the missing
    // variationDef (and bodyPartName) the same way CompPostMake does. The saved variation name is
    // untouched, so this changes nothing unless the player picks an entry.
    [StaticConstructorOnStartup]
    public static class VariationMenuFix
    {
        static MethodInfo isPenis;
        static MethodInfo isVagina;

        static VariationMenuFix()
        {
            MethodInfo target = AccessTools.Method(typeof(SizedApparel.SizedApparelBodyPartDetail), "ShowVariationsSelect");
            if (target == null)
            {
                Log.Warning("[RJW Animal Textures] Sized Apparel's variation menu was not found. The dev menu fix was not applied.");
                return;
            }
            Type helper = AccessTools.TypeByName("rjw.Genital_Helper");
            if (helper != null)
            {
                isPenis = AccessTools.Method(helper, "is_penis", new[] { typeof(Hediff) });
                isVagina = AccessTools.Method(helper, "is_vagina", new[] { typeof(Hediff) });
            }
            new Harmony("mathieu.rjwanimaltextures.variationmenu").Patch(
                target,
                prefix: new HarmonyMethod(typeof(VariationMenuFix), "Prefix"));
        }

        static bool Ask(MethodInfo method, Hediff hediff)
        {
            if (method == null)
            {
                return false;
            }
            try
            {
                return (bool)method.Invoke(null, new object[] { hediff });
            }
            catch (Exception)
            {
                return false;
            }
        }

        // Same order as SizedApparelBodyPartDetail.CompPostMake.
        static string PartName(Hediff hediff)
        {
            string defName = hediff.def.defName;
            if (SizedApparel.SizedApparelUtility.isBreast(defName)) return "Breasts";
            if (Ask(isVagina, hediff)) return "Vagina";
            if (SizedApparel.SizedApparelUtility.isAnus(defName)) return "Anus";
            if (Ask(isPenis, hediff)) return "Penis";
            return defName;
        }

        public static void Prefix(SizedApparel.SizedApparelBodyPartDetail selectedDetail)
        {
            try
            {
                if (selectedDetail == null || selectedDetail.variationDef != null || selectedDetail.parent == null)
                {
                    return;
                }
                if (selectedDetail.bodyPartName == null)
                {
                    selectedDetail.bodyPartName = PartName(selectedDetail.parent);
                }
                string part = selectedDetail.bodyPartName;
                selectedDetail.variationDef = DefDatabase<SizedApparel.SizedApparelBodyPartVariationDef>.AllDefs
                    .FirstOrDefault(d => d.bodyPartName == part);
            }
            catch (Exception e)
            {
                Log.Warning("[RJW Animal Textures] Could not restore Sized Apparel variations for the dev menu: " + e.Message);
            }
        }
    }
}
