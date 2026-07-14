#if UNITY_EDITOR
using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using TMPro;
using UnityEditor;
using UnityEngine;

namespace YourCall.EditorTools
{
    /// <summary>
    /// Editor-only verification for Chapter 8 (The Campaign), used offline in place of a play-mode click
    /// through. <see cref="SmokeTest"/> exercises every choice beat's BuildData across all classes and (for the
    /// boss) the companion / village flag combinations, asserting the data is well formed and that no
    /// player-facing string contains a dash (the hard constraint), then constructs each new doodle and the die
    /// to prove the drawing code does not throw. <see cref="Preview"/> renders the new doodles and the die to a
    /// PNG so the art can be eyeballed. Never ships. Run: Tools ▸ Your Call ▸ Verify Chapter 8, or headless via
    /// -executeMethod YourCall.EditorTools.ChapterEightVerify.Verify.
    /// </summary>
    public static class ChapterEightVerify
    {
        private const string InkMaterialPath = "Assets/Art/InkMaterial.mat";
        private const string FontPath = "Assets/Fonts/Caveat SDF.asset";

        [UnityEditor.MenuItem("Tools/Your Call/Verify Chapter 8")]
        public static void Verify()
        {
            SmokeTest();
            CheckTurkish();
            Preview();
        }

        // ---------- localization: a sample of Chapter 8 keys resolve to Turkish (not the English fallback) ----------

        public static void CheckTurkish()
        {
            // tr.json was edited on disk; Resources.Load caches, so force a reimport, then reload the map by
            // bouncing the language (the same-language guard makes a redundant SetLanguage a no-op).
            AssetDatabase.ImportAsset("Assets/Resources/Localization/tr.json", ImportAssetOptions.ForceUpdate);
            var loc = typeof(Localization);
            var setLang = loc.GetMethod("SetLanguage", BindingFlags.Public | BindingFlags.Static);
            var localize = loc.GetMethod("Localize", new[] { typeof(string), typeof(string) });
            if (setLang == null || localize == null) { Debug.LogError("[C8 TR] Localization API not found"); return; }
            setLang.Invoke(null, new object[] { "en" });
            setLang.Invoke(null, new object[] { "tr" });

            string[] sample =
            {
                "The Knight", "The Cleric", "Pick your class.", "For the gold", "Fight it", "Trick it",
                "Take the cursed blade", "Refuse the roll", "Let him fix the die", "... oh.",
                "how others took the dragon", "what others did when I offered to cheat",
                "roll a [amber]{0}[/amber] or higher and you clear it",
            };
            int ok = 0, miss = 0;
            foreach (var k in sample)
            {
                var v = (string)localize.Invoke(null, new object[] { k, null });
                if (string.IsNullOrEmpty(v) || v == k) { miss++; Debug.LogError("[C8 TR] NOT translated: " + k); }
                else ok++;
            }
            setLang.Invoke(null, new object[] { "en" });   // restore the default
            Debug.Log("[C8 TR] " + ok + " resolved, " + miss + " missing (of " + sample.Length + ")" + (miss == 0 ? "  (PASS)" : "  (FAIL)"));
        }

        // ---------- smoke test: BuildData across states, plus doodle / die construction ----------

        public static void SmokeTest()
        {
            var mat = AssetDatabase.LoadAssetAtPath<Material>(InkMaterialPath);
            var font = AssetDatabase.LoadAssetAtPath<TMP_FontAsset>(FontPath);
            var root = new GameObject("__c8_smoke");
            int checks = 0, fails = 0;
            try
            {
                var beatTypes = new[]
                {
                    typeof(CampaignClassBeat), typeof(CampaignReasonBeat), typeof(CampaignTavernBeat),
                    typeof(CampaignForkBeat), typeof(CampaignCompanionBeat), typeof(CampaignVillageBeat),
                    typeof(CampaignTreasureBeat), typeof(CampaignBossBeat),
                };
                var classes = (CampaignClass[])Enum.GetValues(typeof(CampaignClass));

                foreach (var bt in beatTypes)
                {
                    var beat = (CampaignBeat)root.AddComponent(bt);
                    var build = bt.GetMethod("BuildData", BindingFlags.Instance | BindingFlags.NonPublic);
                    if (build == null) { fails++; Debug.LogError("[C8] " + bt.Name + " has no BuildData"); continue; }

                    foreach (var cls in classes)
                        ValidateData(bt.Name, build, beat, new CampaignState { Class = cls }, cls, ref checks, ref fails);

                    if (bt == typeof(CampaignBossBeat))
                    {
                        foreach (CompanionTreatment comp in Enum.GetValues(typeof(CompanionTreatment)))
                            foreach (VillageOutcome vil in Enum.GetValues(typeof(VillageOutcome)))
                            {
                                var st = new CampaignState { Class = CampaignClass.Knight, Companion = comp, Village = vil };
                                ValidateData("Boss[" + comp + "," + vil + "]", build, beat, st, CampaignClass.Knight, ref checks, ref fails);
                            }
                    }
                }

                // Every new doodle draws without throwing.
                foreach (DoodleKind k in NewKinds())
                {
                    try { var d = InkDoodle.Create(root.transform, "d", Vector3.zero, 1f, k, mat, null, 0.05f, 14); d.SetAlpha(1f); UnityEngine.Object.DestroyImmediate(d.gameObject); checks++; }
                    catch (Exception e) { fails++; Debug.LogError("[C8] doodle " + k + " threw: " + e.Message); }
                }

                // The die builds and cycles every face.
                try
                {
                    var die = DiceRoll.Create(root.transform, "die", Vector3.zero, 1f, mat, font);
                    for (int f = 1; f <= 6; f++) die.SetFace(f);
                    die.ShowInstant();
                    UnityEngine.Object.DestroyImmediate(die.gameObject);
                    checks++;
                }
                catch (Exception e) { fails++; Debug.LogError("[C8] die threw: " + e.Message); }
            }
            finally { UnityEngine.Object.DestroyImmediate(root); }

            Debug.Log("[C8 SmokeTest] " + checks + " checks, " + fails + " FAILURES" + (fails == 0 ? "  (PASS)" : "  (FAIL)"));
        }

        private static void ValidateData(string tag, MethodInfo build, CampaignBeat beat, CampaignState st,
            CampaignClass cls, ref int checks, ref int fails)
        {
            checks++;
            CampaignData data;
            try { data = (CampaignData)build.Invoke(beat, new object[] { st }); }
            catch (Exception e) { fails++; Debug.LogError("[C8] " + tag + " BuildData threw: " + (e.InnerException ?? e).Message); return; }
            if (data == null) { fails++; Debug.LogError("[C8] " + tag + " returned null data"); return; }

            if (data.Narration != null)
                foreach (var n in data.Narration) CheckString(tag + " narration", n, ref fails);
            CheckString(tag + " prompt", data.RulePrompt, ref fails);
            CheckString(tag + " heading", data.Heading, ref fails);

            int visible = 0;
            foreach (var o in data.Options)
            {
                if (o == null) continue;
                if (!o.AvailableTo(cls)) continue;
                visible++;
                if (string.IsNullOrEmpty(o.Label)) { fails++; Debug.LogError("[C8] " + tag + " empty label"); }
                if (string.IsNullOrEmpty(o.React)) { fails++; Debug.LogError("[C8] " + tag + " empty react for '" + o.Label + "'"); }
                if (o.Seed <= 0) { fails++; Debug.LogError("[C8] " + tag + " non-positive seed for '" + o.Label + "'"); }
                CheckString(tag + " label", o.Label, ref fails);
                CheckString(tag + " react", o.React, ref fails);
            }
            if (visible < 2) { fails++; Debug.LogError("[C8] " + tag + " (" + cls + ") only " + visible + " visible option(s)"); }
        }

        // The no-dash constraint: no hyphen-minus, en dash or em dash in any player-facing string.
        private static void CheckString(string where, string s, ref int fails)
        {
            if (string.IsNullOrEmpty(s)) return;
            if (s.IndexOf('-') >= 0 || s.IndexOf('–') >= 0 || s.IndexOf('—') >= 0)
            {
                fails++;
                Debug.LogError("[C8] DASH in " + where + ": " + s);
            }
        }

        private static IEnumerable<DoodleKind> NewKinds()
        {
            return new[]
            {
                DoodleKind.Knight, DoodleKind.Rogue, DoodleKind.Wizard, DoodleKind.Bard, DoodleKind.Cleric,
                DoodleKind.Coins, DoodleKind.Trophy, DoodleKind.QuestHeart, DoodleKind.Signpost,
                DoodleKind.Companion, DoodleKind.TreasureChest,
            };
        }

        // ---------- preview: render the new doodles and the die to a PNG ----------

        public static void Preview()
        {
            var mat = AssetDatabase.LoadAssetAtPath<Material>(InkMaterialPath);
            var font = AssetDatabase.LoadAssetAtPath<TMP_FontAsset>(FontPath);
            var root = new GameObject("__c8_preview");
            var camGo = new GameObject("__c8_cam");
            try
            {
                var cam = camGo.AddComponent<Camera>();
                cam.orthographic = true;
                cam.orthographicSize = 4.2f;
                cam.transform.position = new Vector3(0f, 0f, -10f);
                cam.clearFlags = CameraClearFlags.SolidColor;
                cam.backgroundColor = Palette.Paper;

                var kinds = new[]
                {
                    DoodleKind.Knight, DoodleKind.Rogue, DoodleKind.Wizard, DoodleKind.Bard,
                    DoodleKind.Cleric, DoodleKind.Coins, DoodleKind.Trophy, DoodleKind.QuestHeart,
                    DoodleKind.Signpost, DoodleKind.Companion, DoodleKind.TreasureChest,
                };
                float[] xs = { -6f, -2f, 2f, 6f };
                float[] ys = { 2.7f, 0f, -2.7f };
                for (int i = 0; i < kinds.Length; i++)
                {
                    var pos = new Vector3(xs[i % 4], ys[i / 4], 0f);
                    var d = InkDoodle.Create(root.transform, kinds[i].ToString(), pos, 1.15f, kinds[i], mat,
                        InkDoodle.DefaultColorFor(kinds[i]), 0.055f, 14);
                    d.SetAlpha(1f);
                }
                // the die in the last grid cell
                var die = DiceRoll.Create(root.transform, "die", new Vector3(xs[3], ys[2], 0f), 1.3f, mat, font);
                die.SetFace(5);
                die.ShowInstant();

                int w = 1400, h = 900;
                var rt = new RenderTexture(w, h, 24);
                cam.aspect = (float)w / h;
                cam.targetTexture = rt;
                cam.Render();
                var prev = RenderTexture.active;
                RenderTexture.active = rt;
                var tex = new Texture2D(w, h, TextureFormat.RGB24, false);
                tex.ReadPixels(new Rect(0, 0, w, h), 0, 0);
                tex.Apply();
                RenderTexture.active = prev;
                cam.targetTexture = null;

                // Write outside the project (its parent), so Unity's Temp cleanup on quit does not wipe it.
                string projectRoot = Path.GetDirectoryName(Application.dataPath);
                string dir = Path.GetFullPath(Path.Combine(projectRoot, "..", "c8_doodles.png"));
                File.WriteAllBytes(dir, tex.EncodeToPNG());
                UnityEngine.Object.DestroyImmediate(rt);
                UnityEngine.Object.DestroyImmediate(tex);
                Debug.Log("[C8 Preview] wrote " + dir);
            }
            catch (Exception e) { Debug.LogError("[C8 Preview] threw: " + e); }
            finally { UnityEngine.Object.DestroyImmediate(root); UnityEngine.Object.DestroyImmediate(camGo); }
        }
    }
}
#endif
