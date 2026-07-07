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
        [Tooltip("The game's own mix level: low, so the music sits under everything. The player's " +
                 "music setting scales this, so at the setting's max the music still sits here.")]
        [SerializeField, Range(0f, 1f)] private float _volume = 0.3f;
        [SerializeField] private bool _loop = true;
        [Tooltip("Survive scene loads so it does not restart between scenes.")]
        [SerializeField] private bool _persistAcrossScenes = true;

        private AudioSource _source;
        private float _settingsScalar = 1f;

        private void Awake()
        {
            if (Instance != null && Instance != this) { Destroy(gameObject); return; }
            Instance = this;
            if (_persistAcrossScenes) DontDestroyOnLoad(gameObject);

            _source = GetComponent<AudioSource>();
            _source.clip = _clip;
            _source.loop = _loop;
            _source.playOnAwake = false;
            _source.spatialBlend = 0f; // 2D
            ApplyVolume();
            if (_clip != null) _source.Play();
        }

        // Read the saved music setting and follow it live. Done in Start (after GameSettings' Awake)
        // so the setting is loaded; if there is no GameSettings, the scalar stays 1 (designed level).
        private void Start()
        {
            if (GameSettings.Instance != null)
            {
                _settingsScalar = GameSettings.Instance.MusicVolume;
                GameSettings.Instance.MusicVolumeChanged += OnSettingsVolumeChanged;
                ApplyVolume();
            }
        }

        private void OnDestroy()
        {
            if (GameSettings.Instance != null) GameSettings.Instance.MusicVolumeChanged -= OnSettingsVolumeChanged;
        }

        private void OnSettingsVolumeChanged(float scalar)
        {
            _settingsScalar = Mathf.Clamp01(scalar);
            ApplyVolume();
        }

        private void ApplyVolume()
        {
            if (_source != null) _source.volume = _volume * _settingsScalar;
        }

        /// <summary>Live-tune the level from the Inspector during play.</summary>
        private void OnValidate()
        {
            ApplyVolume();
        }
    }
}
