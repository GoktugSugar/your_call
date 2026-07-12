using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// A light, silent, in-session record of the things the player has killed across the run (the bear they
    /// shot, and whoever/whatever else), so Chapter 5's "everything you have killed" finale can tally them and
    /// send them at the player all at once (see docs/gameplay.md, the Who Would Win finale). A persistent
    /// singleton like <see cref="Profile"/> (DontDestroyOnLoad), cleared on a New Game.
    ///
    /// Deliberately best-effort, not load-bearing: it is NOT part of the save file, and the finale falls back
    /// to an authored roster when the log is empty (Chapter 5 played on its own via the dev picker, or a fresh
    /// app launch), so the beat always lands. It is never a score, never shown as one; it only feeds the
    /// finale's crowd of vengeful dead. Full per-kill tracking across every killing beat is a later step
    /// (see docs/open-questions.md); today the bear opener records itself and the roster covers the rest.
    /// </summary>
    public sealed class KillLog : MonoBehaviour
    {
        public static KillLog Instance { get; private set; }

        /// <summary>One thing the player killed: an English display label (localized at the finale), the doodle
        /// to draw it with in the mob, and how many of it.</summary>
        public struct Kill
        {
            public string Name;
            public DoodleKind Doodle;
            public int Count;
            public Kill(string name, DoodleKind doodle, int count) { Name = name; Doodle = doodle; Count = count; }
        }

        private readonly List<Kill> _kills = new List<Kill>();
        public IReadOnlyList<Kill> Kills => _kills;

        private void Awake()
        {
            if (Instance != null && Instance != this) { Destroy(gameObject); return; }
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }

        /// <summary>Lazily ensure a KillLog exists even if no scene created one.</summary>
        public static KillLog Ensure()
        {
            if (Instance == null)
            {
                var go = new GameObject("KillLog");
                Instance = go.AddComponent<KillLog>();
            }
            return Instance;
        }

        /// <summary>Record a kill, merging into an existing entry of the same label and doodle so a repeated
        /// kill increments the count rather than piling up duplicate rows. Silent by design.</summary>
        public void Record(string name, DoodleKind doodle, int count = 1)
        {
            if (count <= 0) return;
            for (int i = 0; i < _kills.Count; i++)
            {
                if (_kills[i].Doodle == doodle && _kills[i].Name == name)
                {
                    var k = _kills[i]; k.Count += count; _kills[i] = k; return;
                }
            }
            _kills.Add(new Kill(name, doodle, count));
        }

        /// <summary>The total number of things killed (summed counts), for the finale's tally line.</summary>
        public int Total()
        {
            int n = 0;
            for (int i = 0; i < _kills.Count; i++) n += _kills[i].Count;
            return n;
        }

        /// <summary>Clear the log back to empty. Used when a New Game starts a fresh run, so a previous run's
        /// kills (this is a persistent singleton) never bleed into the new one.</summary>
        public void Clear() { _kills.Clear(); }
    }
}
