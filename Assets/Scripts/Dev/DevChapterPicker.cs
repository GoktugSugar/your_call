using UnityEngine;
#if UNITY_EDITOR || DEVELOPMENT_BUILD
using UnityEngine.SceneManagement;
#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif
#endif

namespace YourCall.Dev
{
    /// <summary>
    /// DEV-ONLY chapter / beat picker, a testing tool that never ships. It lets a developer jump
    /// straight to the start of any chapter (or any beat within the current chapter) so a specific
    /// dilemma can be tested without replaying from the top. It runs the real thing: it just loads
    /// the chapter scene and, for a beat jump, tells the <see cref="SequencePlayer"/> to enter partway
    /// (see <see cref="SequencePlayer.PendingStartBeat"/>), then the normal loop plays.
    ///
    /// Gated three ways so it can never reach a player: the whole body is compiled only in the editor
    /// or a development build (<c>UNITY_EDITOR || DEVELOPMENT_BUILD</c>), it is auto-spawned only under
    /// that same gate (so a shipping build never even creates it, and no game scene references it), and
    /// a runtime <see cref="_devToolsEnabled"/> toggle can switch it off. In a normal release build this
    /// is an inert, never-instantiated empty component. One job: the dev picker overlay.
    ///
    /// The overlay is plain IMGUI on purpose (it never ships, so it does not follow the game's art
    /// style). Open it with the hotkey (default F1). The chapter list is the one place scenes are named
    /// (keep it in sync with Build Settings); beats are read live from the loaded sequence, so they
    /// never drift.
    /// </summary>
    public sealed class DevChapterPicker : MonoBehaviour
    {
        [Tooltip("Master toggle for the dev picker. The tool is ALSO compile-gated to the editor and " +
                 "development builds, so a real build strips it regardless of this flag.")]
        [SerializeField] private bool _devToolsEnabled = true;
#if ENABLE_INPUT_SYSTEM
        [Tooltip("Key that opens/closes the dev picker overlay.")]
        [SerializeField] private Key _openKey = Key.F1;
#endif

#if UNITY_EDITOR || DEVELOPMENT_BUILD
        // The ONE place chapters/scenes are listed. Keep in sync with Build Settings and the scenes on
        // disk. Beats are not listed here (they are read live from the loaded SequencePlayer, no drift).
        private readonly struct ChapterEntry
        {
            public readonly string Label;
            public readonly string Scene;
            public ChapterEntry(string label, string scene) { Label = label; Scene = scene; }
        }

        private static readonly ChapterEntry[] _chapters =
        {
            new ChapterEntry("Chapter 1: The Tracks (baby opener + 10 trolleys)", "Opening"),
            new ChapterEntry("Chapter 2: The Buttons (blue/red, offer, timer)", "ChapterTwo"),
            new ChapterEntry("Chapter 3: The Money (finite pot, priceable things, cigarette auction)", "ChapterThree"),
            new ChapterEntry("Chapter 4: The Gun (bear opener + aim-and-fire beats)", "ChapterFour"),
            new ChapterEntry("Chapter 5: Who Would Win (ten barroom matchups)", "ChapterFive"),
            new ChapterEntry("Chapter 7: The Confession Booth (ten judgment cases)", "ChapterSeven"),
            new ChapterEntry("Standalone: Trolley", "Dilemma"),
            new ChapterEntry("Standalone: Blue/Red Button", "BlueRedButton"),
            new ChapterEntry("Standalone: The Last Bear (+ shoot the imp)", "BearDilemma"),
            new ChapterEntry("Main Menu (normal boot)", "MainMenu"),
        };

        private static DevChapterPicker _instance;
        private bool _open;
        private Vector2 _scroll;

        // Auto-spawn a single persistent picker so it is available from ANY scene (including a scene
        // opened directly in the editor), with no per-scene setup and nothing referencing it in a shipping
        // scene. Stripped entirely from a release build along with the rest of the gated body.
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        private static void Bootstrap()
        {
            if (FindAnyObjectByType<DevChapterPicker>() != null) return;
            var go = new GameObject("[DevChapterPicker]");
            go.AddComponent<DevChapterPicker>();
        }

        private void Awake()
        {
            if (_instance != null && _instance != this) { Destroy(gameObject); return; }
            _instance = this;
            DontDestroyOnLoad(gameObject);
        }

        private void Update()
        {
            if (!_devToolsEnabled) return;
#if ENABLE_INPUT_SYSTEM
            var kb = Keyboard.current;
            if (kb == null) return;
            if (kb[_openKey].wasPressedThisFrame) _open = !_open;
            if (_open && kb.escapeKey.wasPressedThisFrame) _open = false;
#endif
        }

        private void OnGUI()
        {
            if (!_devToolsEnabled) return;

            // Always-on hint, so it is obvious a dev tool is live and how to open it.
            var hint = new GUIStyle(GUI.skin.label) { fontSize = 12, fontStyle = FontStyle.Bold };
            hint.normal.textColor = new Color(0.85f, 0.2f, 0.75f);
            GUI.Label(new Rect(8, 6, 500, 20), "DEV TOOLS  [" + OpenKeyName() + "] chapter / beat picker", hint);

            if (!_open) return;

            float w = 380f;
            float h = Mathf.Min(Screen.height - 44f, 620f);
            var box = new Rect(8f, 28f, w, h);
            GUI.Box(box, GUIContent.none);

            GUILayout.BeginArea(new Rect(box.x + 10f, box.y + 8f, box.width - 20f, box.height - 16f));
            GUILayout.Label("DEV: Chapter / Beat Picker", Header());
            GUILayout.Label("Current scene: " + SceneManager.GetActiveScene().name);
            GUILayout.Space(4f);

            _scroll = GUILayout.BeginScrollView(_scroll);

            GUILayout.Label("Jump to chapter / scene start:", Header());
            for (int i = 0; i < _chapters.Length; i++)
            {
                if (GUILayout.Button(_chapters[i].Label))
                    Jump(_chapters[i].Scene, 0);
            }

            // Beats of the sequence in THIS scene, read live so they never drift from the real order.
            var sp = FindAnyObjectByType<SequencePlayer>();
            GUILayout.Space(8f);
            if (sp != null && sp.Beats != null && sp.Beats.Count > 0)
            {
                GUILayout.Label("Jump to a beat in this chapter (reloads it):", Header());
                var beats = sp.Beats;
                for (int i = 0; i < beats.Count; i++)
                {
                    // The GameObject name is the most descriptive label (e.g. 05_Baby, C2_BlueRed),
                    // falling back to the beat's Note / type name if a beat GameObject is unnamed.
                    string label = i.ToString("00") + "   " + (beats[i] != null ? beats[i].name : "(missing)");
                    if (GUILayout.Button(label))
                        Jump(SceneManager.GetActiveScene().name, i);
                }
            }
            else
            {
                GUILayout.Label("(this scene has no sequence to list beats; load a chapter first)");
            }

            GUILayout.EndScrollView();

            GUILayout.Space(4f);
            if (GUILayout.Button("Close [Esc]")) _open = false;
            GUILayout.EndArea();
        }

        private void Jump(string scene, int beatIndex)
        {
            SequencePlayer.PendingStartBeat = beatIndex;   // consumed by the target scene's SequencePlayer
            // A dev jump is not the real run: switch off auto-save so testing never overwrites the player's
            // save, and never clears it on an ending reached mid-test. New Game / Continue turn it back on.
            if (SaveService.Instance != null) SaveService.Instance.SetRealRun(false);
            _open = false;
            SceneManager.LoadScene(scene);
        }

        private static GUIStyle Header()
        {
            return new GUIStyle(GUI.skin.label) { fontStyle = FontStyle.Bold };
        }

        private string OpenKeyName()
        {
#if ENABLE_INPUT_SYSTEM
            return _openKey.ToString();
#else
            return "F1";
#endif
        }
#endif // UNITY_EDITOR || DEVELOPMENT_BUILD
    }
}
