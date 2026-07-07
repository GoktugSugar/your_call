using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// A small persistent background music player: plays one looped track quietly and keeps
    /// going across beats (and scenes) without restarting. A guarded singleton, so reloading a
    /// scene never doubles or restarts it. Volume is a low default and exposed for tuning.
    /// The clip is a placeholder, easy to swap. One job: keep the music running.
    /// </summary>
    [RequireComponent(typeof(AudioSource))]
    public sealed class MusicPlayer : MonoBehaviour
    {
        public static MusicPlayer Instance { get; private set; }

        [SerializeField] private AudioClip _clip;
        [Tooltip("Low by default; the music sits under everything.")]
        [SerializeField, Range(0f, 1f)] private float _volume = 0.3f;
        [SerializeField] private bool _loop = true;
        [Tooltip("Survive scene loads so it does not restart between scenes.")]
        [SerializeField] private bool _persistAcrossScenes = true;

        private AudioSource _source;

        private void Awake()
        {
            if (Instance != null && Instance != this) { Destroy(gameObject); return; }
            Instance = this;
            if (_persistAcrossScenes) DontDestroyOnLoad(gameObject);

            _source = GetComponent<AudioSource>();
            _source.clip = _clip;
            _source.loop = _loop;
            _source.volume = _volume;
            _source.playOnAwake = false;
            _source.spatialBlend = 0f; // 2D
            if (_clip != null) _source.Play();
        }

        /// <summary>Live-tune the level from the Inspector during play.</summary>
        private void OnValidate()
        {
            if (_source != null) _source.volume = _volume;
        }
    }
}
