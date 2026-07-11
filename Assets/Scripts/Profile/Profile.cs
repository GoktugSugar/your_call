using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The persistent, silent moral profile: a running tally over the axes in
    /// narrative.md, accumulated across dilemmas and replays. Never drawn during play
    /// (see docs/art-and-ui.md); painting a portrait from it is the ending's job.
    /// </summary>
    public class Profile : MonoBehaviour
    {
        public static Profile Instance { get; private set; }

        [Tooltip("Dev only: echo recorded impacts to the console. Never shown in the game view. Off by default.")]
        [SerializeField] private bool _debugLogToConsole = false;

        private readonly Dictionary<MoralAxis, float> _tally = new Dictionary<MoralAxis, float>();

        private void Awake()
        {
            if (Instance != null && Instance != this) { Destroy(gameObject); return; }
            Instance = this;
            DontDestroyOnLoad(gameObject);
            foreach (MoralAxis a in System.Enum.GetValues(typeof(MoralAxis)))
                if (!_tally.ContainsKey(a)) _tally[a] = 0f;
        }

        /// <summary>Lazily ensure a Profile exists even if the scene has none.</summary>
        public static Profile Ensure()
        {
            if (Instance == null)
            {
                var go = new GameObject("Profile");
                Instance = go.AddComponent<Profile>();
            }
            return Instance;
        }

        /// <summary>Fold a choice's impact into the tally. Silent by design.</summary>
        public void Record(IReadOnlyList<AxisImpact> impacts)
        {
            if (impacts == null) return;
            for (int i = 0; i < impacts.Count; i++)
            {
                var im = impacts[i];
                _tally.TryGetValue(im.Axis, out float v);
                _tally[im.Axis] = v + im.Value;
            }
            if (_debugLogToConsole) Debug.Log("[Profile] " + Describe());
        }

        public float Value(MoralAxis axis) { _tally.TryGetValue(axis, out float v); return v; }

        /// <summary>Clear the tally back to zero on every axis. Used when a New Game starts a fresh run, so a
        /// previous run's profile (this is a persistent singleton) never bleeds into the new one.</summary>
        public void ResetState()
        {
            foreach (MoralAxis a in System.Enum.GetValues(typeof(MoralAxis))) _tally[a] = 0f;
        }

        /// <summary>A copy of the current tally, for the save system to persist (see <see cref="SaveService"/>).
        /// Absolute values, not deltas.</summary>
        public List<AxisImpact> Snapshot()
        {
            var list = new List<AxisImpact>(_tally.Count);
            foreach (var kv in _tally) list.Add(new AxisImpact(kv.Key, kv.Value));
            return list;
        }

        /// <summary>Replace the tally with a saved snapshot (Continue restoring a run). Resets first, then sets
        /// each saved axis to its absolute value, so restoring is idempotent and never doubles a resumed run.</summary>
        public void LoadSnapshot(IReadOnlyList<AxisImpact> snapshot)
        {
            ResetState();
            if (snapshot == null) return;
            for (int i = 0; i < snapshot.Count; i++) _tally[snapshot[i].Axis] = snapshot[i].Value;
        }

        /// <summary>Dev-only readout. Not player-facing UI.</summary>
        public string Describe()
        {
            var sb = new System.Text.StringBuilder();
            foreach (var kv in _tally) { sb.Append(kv.Key); sb.Append('='); sb.Append(kv.Value.ToString("0.##")); sb.Append("  "); }
            return sb.ToString();
        }
    }
}
