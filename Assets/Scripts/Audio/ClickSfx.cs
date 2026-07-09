using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// A short placeholder button-press click, played on request. If no clip is assigned it synthesises a
    /// small percussive thock at runtime (a noise transient plus a fast decaying low tone), so no audio
    /// asset is needed for the placeholder; a real clip can be dropped in later. Plays on its own
    /// AudioSource and scales by the player's saved SFX volume, the same split as <see cref="GunSfx"/> and
    /// <see cref="ImpVoice"/> (no audio living in the beats). One job: click, once, on request.
    /// </summary>
    [RequireComponent(typeof(AudioSource))]
    public sealed class ClickSfx : MonoBehaviour
    {
        [Tooltip("Optional press clip. Empty synthesises a small click at runtime (placeholder, easy to swap).")]
        [SerializeField] private AudioClip _clip;
        [SerializeField, Range(0f, 1f)] private float _volume = 0.5f;
        [Tooltip("Synthesised click: length in seconds.")]
        [SerializeField] private float _synthDuration = 0.09f;
        [Tooltip("Synthesised click: body tone frequency (Hz).")]
        [SerializeField] private float _synthFrequency = 180f;

        private AudioSource _source;

        private void Awake()
        {
            _source = GetComponent<AudioSource>();
            _source.playOnAwake = false;
            _source.spatialBlend = 0f; // 2D
            if (_clip == null) _clip = Synthesise();
        }

        /// <summary>Play the click once, scaled by the saved SFX volume.</summary>
        public void Play()
        {
            if (_source == null || _clip == null) return;
            _source.PlayOneShot(_clip, _volume * GameSettings.SfxScalar);
        }

        private AudioClip Synthesise()
        {
            const int rate = 44100;
            int n = Mathf.Max(1, Mathf.RoundToInt(rate * Mathf.Max(0.02f, _synthDuration)));
            var data = new float[n];
            float transient = rate * 0.003f; // ~3ms of click attack
            for (int i = 0; i < n; i++)
            {
                float t = (float)i / rate;
                float env = Mathf.Exp(-t * 55f);                       // fast decay
                float body = Mathf.Sin(2f * Mathf.PI * _synthFrequency * t) * 0.6f;
                float click = i < transient ? (Mathf.PingPong(i * 0.5f, 1f) * 2f - 1f) * 0.5f : 0f;
                data[i] = Mathf.Clamp((body + click) * env, -1f, 1f);
            }
            var clip = AudioClip.Create("ButtonClick", n, 1, rate, false);
            clip.SetData(data, 0);
            return clip;
        }
    }
}
