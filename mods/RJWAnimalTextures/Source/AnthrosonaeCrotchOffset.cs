using System.Reflection;
using HarmonyLib;
using RimWorld;
using UnityEngine;
using Verse;

namespace RJWAnimalTextures
{
    // Anthrosonae bodies are legless torsos on the human skeleton. The east penis
    // bone sits on the front of that torso. Nudge penis and balls back and down
    // so the sheath meets the bottom of the body. Human pawns are left alone.
    [StaticConstructorOnStartup]
    public static class AnthrosonaeCrotchOffset
    {
        static AnthrosonaeCrotchOffset()
        {
            MethodInfo method = AccessTools.Method(typeof(SizedApparel.SizedApparelBodyPart), "UpdateOffsetsAndLayers");
            if (method == null)
            {
                Log.Warning("[RJW Animal Textures] Sized Apparel body-part offset method was not found. Anthrosonae penis placement was not patched.");
                return;
            }

            new Harmony("mathieu.rjwanimaltextures.anthrosonae").Patch(
                method,
                postfix: new HarmonyMethod(typeof(AnthrosonaeCrotchOffset), "Postfix"));
        }

        static bool warned;

        public static void Postfix(SizedApparel.SizedApparelBodyPart __instance)
        {
            if (__instance == null || __instance.pawn == null || __instance.pawn.story == null)
            {
                return;
            }

            if (__instance.bodyPartOf != SizedApparel.SizedApparelBodyPartOf.Penis
                && __instance.bodyPartOf != SizedApparel.SizedApparelBodyPartOf.Balls)
            {
                return;
            }

            FurDef fur = __instance.pawn.story.furDef;
            if (fur == null || fur.defName == null || !fur.defName.StartsWith("ATK_Anthro"))
            {
                return;
            }

            string bodyType = __instance.pawn.story.bodyType == null ? null : __instance.pawn.story.bodyType.defName;
            float extraX;
            float extraZ;
            if (!TrySideOffset(bodyType, out extraX, out extraZ))
            {
                return;
            }

            float width = 1f;
            if (__instance.apparelRecorderCompCache != null)
            {
                width = __instance.apparelRecorderCompCache.bodyWidth;
            }

            DrawData drawData = __instance.drawData;
            if (drawData == null)
            {
                return;
            }

            try
            {
                Shift(drawData, "dataEast", extraX, extraZ, width);
                Shift(drawData, "dataWest", -extraX, extraZ, width);
                float frontX;
                float frontZ;
                if (TryFrontOffset(bodyType, out frontX, out frontZ))
                {
                    Shift(drawData, "dataSouth", frontX, frontZ, width);
                }
            }
            catch (System.Exception ex)
            {
                if (!warned)
                {
                    warned = true;
                    Log.Warning("[RJW Animal Textures] Anthrosonae penis offset failed: " + ex.Message);
                }
            }
        }

        // East extras, in the same units as the skeleton InitialPosition.
        // Tuned on the anthrogriff female body so the sheath sits on the bottom
        // of the torso. Other body types keep that same gap above their own bottom.
        static bool TrySideOffset(string bodyType, out float extraX, out float extraZ)
        {
            extraX = 0f;
            extraZ = 0f;
            if (bodyType == "Female")
            {
                extraX = -0.078f;
                extraZ = -0.068f;
                return true;
            }

            if (bodyType == "Male")
            {
                extraX = -0.077f;
                extraZ = -0.011f;
                return true;
            }

            if (bodyType == "Thin")
            {
                extraX = -0.019f;
                extraZ = -0.015f;
                return true;
            }

            if (bodyType == "Hulk")
            {
                extraX = -0.034f;
                extraZ = -0.013f;
                return true;
            }

            if (bodyType == "Fat")
            {
                extraX = -0.170f;
                extraZ = 0.007f;
                return true;
            }

            return false;
        }

        // Front extras. The groin mark sits a little left of the mesh center, and
        // the penis base hangs above the bottom of the legless torso.
        static bool TryFrontOffset(string bodyType, out float extraX, out float extraZ)
        {
            extraX = -0.028f;
            extraZ = 0f;
            if (bodyType == "Female")
            {
                extraZ = -0.042f;
                return true;
            }

            if (bodyType == "Male" || bodyType == "Thin")
            {
                extraZ = -0.032f;
                return true;
            }

            if (bodyType == "Hulk")
            {
                extraZ = -0.036f;
                return true;
            }

            if (bodyType == "Fat")
            {
                extraZ = -0.026f;
                return true;
            }

            return false;
        }

        static void Shift(DrawData data, string fieldName, float x, float z, float width)
        {
            FieldInfo field = AccessTools.Field(typeof(DrawData), fieldName);
            if (field == null)
            {
                return;
            }

            object raw = field.GetValue(data);
            if (raw == null)
            {
                return;
            }

            DrawData.RotationalData rotation = (DrawData.RotationalData)raw;
            Vector3 current = rotation.offset.HasValue ? rotation.offset.Value : Vector3.zero;
            rotation.offset = current + new Vector3(x * width, 0f, z * width);
            field.SetValue(data, rotation);
        }
    }
}
