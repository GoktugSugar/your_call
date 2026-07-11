using System;
using System.IO;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The one place the single continuous save lives: reads, writes, and deletes the run's save file on
    /// disk (JSON under Application.persistentDataPath), and answers whether a save is present so the main
    /// menu's Continue can enable itself. A guarded, auto-spawned persistent singleton (the same shape as
    /// GameSettings and the dev picker), so it is available from the menu and from every chapter with no
    /// per-scene wiring. One job: own the save file and the run-lifecycle flags around it.
    ///
    /// It is deliberately dumb about game state: <see cref="SaveCapture"/> builds a <see cref="SaveData"/>
    /// from the live run and applies it back, and <see cref="SequencePlayer"/> decides WHEN to save. This
    /// service only serialises, persists, and validates (robust to a missing, empty, corrupt, or
    /// wrong-version file: any of those simply reads as "no save", which disables Continue and leaves the
    /// game behaving exactly as it did before a save system existed).
    /// </summary>
    [DefaultExecutionOrder(-200)]
    public sealed class SaveService : MonoBehaviour
    {
        public static SaveService Instance { get; private set; }

        private const string FileName = "savegame.json";
        // Endings the player has ever reached, kept in PlayerPrefs so it survives the run save being cleared
        // when an ending is reached. Forward-looking meta (a future ending gallery could read it); not used
        // by resume. Stored as a small '|'-separated list of ending ids.
        private const string EndingsSeenKey = "save.endingsSeen";

        /// <summary>
        /// The run to restore on the next chapter load, handed off by Continue exactly like the dev picker
        /// hands off <see cref="SequencePlayer.PendingStartBeat"/>: the menu sets this, then loads the saved
        /// chapter scene, and that chapter's <see cref="SequencePlayer"/> consumes it to restore the profile
        /// and money before playing. Static so it survives the scene load. Null in normal (New Game) boots.
        /// </summary>
        public static SaveData PendingResume;

        private string _path;

        /// <summary>Whether a valid save is on disk right now (cached; updated by load / write / delete).</summary>
        public bool HasSave { get; private set; }

        /// <summary>The last loaded/written save, or null if none. A convenience cache; the file is the truth.</summary>
        public SaveData Current { get; private set; }

        /// <summary>
        /// True while a REAL player run is in progress (a New Game or a Continue), false on the menu and on
        /// dev-picker jumps. Gates the destructive "clear the save when an ending is reached" so a dev jump
        /// that happens to hit an ending never wipes the player's actual save. Set by <see cref="SequencePlayer"/>.
        /// </summary>
        public bool RealRunActive { get; private set; }

        // ---------- lifecycle ----------

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        private static void Bootstrap()
        {
            if (Instance != null) return;
            var go = new GameObject("[SaveService]");
            go.AddComponent<SaveService>();   // Awake wires the singleton and loads the file
        }

        /// <summary>Lazily ensure the service exists even if the auto-spawn did not run (e.g. a scene opened
        /// directly in the editor without going through boot).</summary>
        public static SaveService Ensure()
        {
            if (Instance == null)
            {
                var go = new GameObject("[SaveService]");
                go.AddComponent<SaveService>();
            }
            return Instance;
        }

        private void Awake()
        {
            if (Instance != null && Instance != this) { Destroy(gameObject); return; }
            Instance = this;
            DontDestroyOnLoad(gameObject);
            _path = Path.Combine(Application.persistentDataPath, FileName);
            TryLoad(out _);   // populate HasSave / Current for the menu
        }

        private void OnDestroy()
        {
            if (Instance == this) Instance = null;
        }

        // ---------- file IO ----------

        /// <summary>Read and validate the save file. Returns false (and reports "no save") on a missing,
        /// empty, corrupt, or wrong-version file, so a bad file never crashes the game or resumes garbage.</summary>
        public bool TryLoad(out SaveData data)
        {
            data = null;
            try
            {
                if (string.IsNullOrEmpty(_path)) _path = Path.Combine(Application.persistentDataPath, FileName);
                if (!File.Exists(_path)) return MarkNone();

                string json = File.ReadAllText(_path);
                if (string.IsNullOrWhiteSpace(json)) return MarkNone();

                var parsed = JsonUtility.FromJson<SaveData>(json);
                if (parsed == null || parsed.version != SaveData.CurrentVersion || string.IsNullOrEmpty(parsed.chapterScene))
                    return MarkNone();

                data = parsed;
                Current = parsed;
                HasSave = true;
                return true;
            }
            catch (Exception e)
            {
                Debug.LogWarning("[SaveService] Could not read save (" + e.Message + "); treating as no save.");
                return MarkNone();
            }
        }

        /// <summary>Write the run state to disk (auto-save on beat boundaries, or a manual save). Immediate
        /// and synchronous, so nothing is lost on a later quit.</summary>
        public void Write(SaveData data)
        {
            if (data == null) return;
            data.version = SaveData.CurrentVersion;
            try
            {
                if (string.IsNullOrEmpty(_path)) _path = Path.Combine(Application.persistentDataPath, FileName);
                File.WriteAllText(_path, JsonUtility.ToJson(data, true));
                Current = data;
                HasSave = true;
            }
            catch (Exception e)
            {
                Debug.LogWarning("[SaveService] Could not write save: " + e.Message);
            }
        }

        /// <summary>Remove the save (New Game replacing it, or a run reaching an ending). Continue then
        /// reports nothing to resume.</summary>
        public void Delete()
        {
            try { if (!string.IsNullOrEmpty(_path) && File.Exists(_path)) File.Delete(_path); }
            catch (Exception e) { Debug.LogWarning("[SaveService] Could not delete save: " + e.Message); }
            Current = null;
            HasSave = false;
        }

        private bool MarkNone() { Current = null; HasSave = false; return false; }

        // ---------- run lifecycle ----------

        /// <summary>Mark whether a real player run is active (see <see cref="RealRunActive"/>).</summary>
        public void SetRealRun(bool on) { RealRunActive = on; }

        /// <summary>Called when a run reaches an ending (any credits roll). For a real run it records the
        /// ending as seen and clears the save (the run is over, so there is nothing to continue). A no-op for
        /// a dev-jump-triggered ending, so testing never wipes the player's save.</summary>
        public void OnRunEnded(string endingId)
        {
            if (!RealRunActive) return;
            MarkEndingSeen(string.IsNullOrEmpty(endingId) ? "ending" : endingId);
            Delete();
            RealRunActive = false;
        }

        // ---------- endings-seen meta (persists across runs) ----------

        public void MarkEndingSeen(string id)
        {
            if (string.IsNullOrEmpty(id) || HasSeenEnding(id)) return;
            string cur = PlayerPrefs.GetString(EndingsSeenKey, "");
            PlayerPrefs.SetString(EndingsSeenKey, string.IsNullOrEmpty(cur) ? id : cur + "|" + id);
            PlayerPrefs.Save();
        }

        public bool HasSeenEnding(string id)
        {
            if (string.IsNullOrEmpty(id)) return false;
            string cur = PlayerPrefs.GetString(EndingsSeenKey, "");
            if (string.IsNullOrEmpty(cur)) return false;
            var parts = cur.Split('|');
            for (int i = 0; i < parts.Length; i++) if (parts[i] == id) return true;
            return false;
        }
    }
}
