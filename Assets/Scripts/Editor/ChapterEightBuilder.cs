#if UNITY_EDITOR
using System.Collections.Generic;
using TMPro;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace YourCall.EditorTools
{
    /// <summary>
    /// Builds Chapter 8 (The Campaign) scene, <c>Assets/Scenes/ChapterEight.unity</c>, from
    /// <c>ChapterSeven.unity</c> using the editor's scene API so Unity assigns every fileID and every reference
    /// resolves (the same way chapters 5 and 7 were built). It FORKS ChapterSeven (which carries the whole
    /// persistent cast, the Ending + CreditsRoll, and the reusable intro / closer ImpLineBeats), then swaps the
    /// ten confession cases and the ConfessionKit / ConfessionBooth for the campaign kit and the campaign beats,
    /// rewrites the intro / closer narration to the Dungeon Master framing, wires the finale's secret ending to
    /// the scene's Ending, sets the beat order, and adds the scene to Build Settings. Editor only; never ships.
    ///
    /// Run from the menu (Tools ▸ Your Call ▸ Build Chapter 8) or headless:
    ///   Unity.exe -batchmode -quit -projectPath &lt;proj&gt; -executeMethod YourCall.EditorTools.ChapterEightBuilder.Build
    /// It leaves ChapterSeven.unity on disk untouched (it only ever saves to the ChapterEight path).
    /// </summary>
    public static class ChapterEightBuilder
    {
        private const string SourcePath = "Assets/Scenes/ChapterSeven.unity";
        private const string TargetPath = "Assets/Scenes/ChapterEight.unity";
        private const string InkMaterialPath = "Assets/Art/InkMaterial.mat";
        private const string FontPath = "Assets/Fonts/Caveat SDF.asset";

        private static readonly string[] IntroLines =
        {
            "New game. New everything. Put the tracks and the buttons and the gun clean out of your head, we are doing something completely different tonight, you and I. We are going on an adventure.",
            "I am going to be your Dungeon Master. It is a game the living play, with dice and heroes and dragons, and the whole point is that I describe a world and you pretend to walk through it and make choices, and I pretend those choices matter. I am very good at it. I have never once let anybody win who I did not want to.",
            "So sit up. Roll up a hero. Try, for one hour, to be a knight instead of a defendant. It will not last. It never does. But let us find out who you are when there are dragons in front of you instead of dilemmas. Begin.",
        };

        private static readonly string[] CloserLines =
        {
            "And that is the adventure. The whole silly, earnest, made up thing. Knights and dice and a dragon I built a size too big on purpose.",
            "You want to know the funny part. You were more honest in there, pretending to be somebody else, than you have been in a single one of the real questions. People always are. Hand a man a mask and he finally shows you his actual face.",
            "Rest your sword arm, hero. There is more, of course. There is always more. But that was a good one. Even I had fun, and I am dead inside, professionally.",
        };

        [UnityEditor.MenuItem("Tools/Your Call/Build Chapter 8")]
        public static void Build()
        {
            if (!System.IO.File.Exists(SourcePath))
            {
                Debug.LogError("[ChapterEightBuilder] Source scene not found: " + SourcePath);
                return;
            }

            var inkMat = AssetDatabase.LoadAssetAtPath<Material>(InkMaterialPath);
            var font = AssetDatabase.LoadAssetAtPath<TMP_FontAsset>(FontPath);
            if (inkMat == null) Debug.LogError("[ChapterEightBuilder] Missing ink material: " + InkMaterialPath);
            if (font == null) Debug.LogError("[ChapterEightBuilder] Missing font: " + FontPath);

            // Fork ChapterSeven into ChapterEight, so ChapterSeven on disk is never touched.
            var scene = EditorSceneManager.OpenScene(SourcePath, OpenSceneMode.Single);
            if (!EditorSceneManager.SaveScene(scene, TargetPath, false))
            {
                Debug.LogError("[ChapterEightBuilder] Failed to fork the scene to " + TargetPath);
                return;
            }

            var sp = Object.FindFirstObjectByType<SequencePlayer>();
            if (sp == null) { Debug.LogError("[ChapterEightBuilder] No SequencePlayer in the scene."); return; }
            sp.gameObject.name = "CampaignSequence";

            // Pull the reusable beats out of the current order.
            SequenceBeat voidWake = null, impAppear = null, intro = null, closer = null;
            var impLines = new List<ImpLineBeat>();
            var confessionBeats = new List<SequenceBeat>();
            Transform beatsParent = null;
            foreach (var b in sp.Beats)
            {
                if (b == null) continue;
                if (beatsParent == null) beatsParent = b.transform.parent;
                if (b is VoidWakeBeat && voidWake == null) voidWake = b;
                else if (b is ImpAppearBeat && impAppear == null) impAppear = b;
                else if (b is ImpLineBeat il) impLines.Add(il);
                else if (b is ConfessionCaseBeat) confessionBeats.Add(b);
            }
            if (impLines.Count > 0) intro = impLines[0];
            if (impLines.Count > 1) closer = impLines[impLines.Count - 1];
            if (voidWake == null || impAppear == null || intro == null || closer == null)
            {
                Debug.LogError("[ChapterEightBuilder] Could not find the reusable intro/closer beats in ChapterSeven.");
                return;
            }

            var ending = Object.FindFirstObjectByType<Ending>();
            if (ending == null) Debug.LogError("[ChapterEightBuilder] No Ending found for the secret ending; the finale's cheat path will fall back to honest.");

            // Remove the confession-specific content.
            foreach (var cb in confessionBeats) if (cb != null) Object.DestroyImmediate(cb.gameObject);
            var kitOld = Object.FindFirstObjectByType<ConfessionKit>();
            if (kitOld != null) Object.DestroyImmediate(kitOld.gameObject);
            var booth = Object.FindFirstObjectByType<ConfessionBooth>();
            if (booth != null) Object.DestroyImmediate(booth.gameObject);

            // The campaign apparatus tray.
            var kitGo = new GameObject("CampaignKit");
            kitGo.transform.SetParent(sp.transform, false);
            var kit = kitGo.AddComponent<CampaignKit>();
            SetRef(kit, "_inkMaterial", inkMat);
            SetRef(kit, "_font", font);

            // Rewrite the reused intro / closer narration to the DM framing.
            intro.gameObject.name = "C8_02_Intro";
            SetLines((ImpLineBeat)intro, IntroLines);
            closer.gameObject.name = "C8_13_Closer";
            SetLines((ImpLineBeat)closer, CloserLines);
            voidWake.gameObject.name = "C8_00_VoidWake";
            impAppear.gameObject.name = "C8_01_ImpAppear";

            // The campaign beats, in order (copy lives in code defaults; only _kit and the finale _ending wire).
            var cls = NewBeat<CampaignClassBeat>("C8_03_Class", beatsParent, kit);
            var reason = NewBeat<CampaignReasonBeat>("C8_04_Reason", beatsParent, kit);
            var firstRoll = NewBeat<CampaignFirstRollBeat>("C8_05_FirstRoll", beatsParent, kit);
            var tavern = NewBeat<CampaignTavernBeat>("C8_06_Tavern", beatsParent, kit);
            var fork = NewBeat<CampaignForkBeat>("C8_07_Fork", beatsParent, kit);
            var companion = NewBeat<CampaignCompanionBeat>("C8_08_Companion", beatsParent, kit);
            var village = NewBeat<CampaignVillageBeat>("C8_09_Village", beatsParent, kit);
            var treasure = NewBeat<CampaignTreasureBeat>("C8_10_Treasure", beatsParent, kit);
            var boss = NewBeat<CampaignBossBeat>("C8_11_Boss", beatsParent, kit);
            var finale = NewBeat<CampaignFinaleBeat>("C8_12_Finale", beatsParent, kit);
            if (ending != null) SetRef(finale, "_ending", ending);

            // The ordered beat list.
            var order = new List<SequenceBeat>
            {
                voidWake, impAppear, intro,
                cls, reason, firstRoll, tavern, fork, companion, village, treasure, boss, finale,
                closer,
            };
            SetBeats(sp, order);
            SetString(sp, "_nextScene", "");   // Chapter 8 holds at its end (dev-picker only, like Chapter 7)

            EditorSceneManager.MarkSceneDirty(scene);
            if (!EditorSceneManager.SaveScene(scene, TargetPath, false))
            {
                Debug.LogError("[ChapterEightBuilder] Failed to save " + TargetPath);
                return;
            }

            AddToBuildSettings(TargetPath);
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();

            // Validate: no missing scripts, the expected beat count.
            int missing = 0;
            foreach (var mb in Object.FindObjectsByType<Transform>(FindObjectsInactive.Include, FindObjectsSortMode.None))
                foreach (var c in mb.GetComponents<Component>())
                    if (c == null) missing++;
            Debug.Log("[ChapterEightBuilder] Built " + TargetPath + " with " + order.Count + " beats; missing components: " + missing + ".");
        }

        // ---------- helpers ----------

        private static T NewBeat<T>(string name, Transform parent, CampaignKit kit) where T : CampaignBeat
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            var b = go.AddComponent<T>();
            SetRef(b, "_kit", kit);
            return b;
        }

        private static void SetRef(Object target, string prop, Object value)
        {
            var so = new SerializedObject(target);
            var p = so.FindProperty(prop);
            if (p == null) { Debug.LogError("[ChapterEightBuilder] No serialized field '" + prop + "' on " + target.GetType().Name); return; }
            p.objectReferenceValue = value;
            so.ApplyModifiedPropertiesWithoutUndo();
        }

        private static void SetString(Object target, string prop, string value)
        {
            var so = new SerializedObject(target);
            var p = so.FindProperty(prop);
            if (p == null) return;
            p.stringValue = value;
            so.ApplyModifiedPropertiesWithoutUndo();
        }

        private static void SetLines(ImpLineBeat beat, string[] lines)
        {
            var so = new SerializedObject(beat);
            var arr = so.FindProperty("_lines");
            arr.arraySize = lines.Length;
            for (int i = 0; i < lines.Length; i++) arr.GetArrayElementAtIndex(i).stringValue = lines[i];
            so.ApplyModifiedPropertiesWithoutUndo();
        }

        private static void SetBeats(SequencePlayer sp, List<SequenceBeat> beats)
        {
            var so = new SerializedObject(sp);
            var arr = so.FindProperty("_beats");
            arr.arraySize = beats.Count;
            for (int i = 0; i < beats.Count; i++) arr.GetArrayElementAtIndex(i).objectReferenceValue = beats[i];
            so.ApplyModifiedPropertiesWithoutUndo();
        }

        private static void AddToBuildSettings(string scenePath)
        {
            var scenes = new List<EditorBuildSettingsScene>(EditorBuildSettings.scenes);
            foreach (var s in scenes) if (s.path == scenePath) return;   // already present
            scenes.Add(new EditorBuildSettingsScene(scenePath, true));
            EditorBuildSettings.scenes = scenes.ToArray();
        }
    }
}
#endif
