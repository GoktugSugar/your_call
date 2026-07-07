using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The imp's gibberish voice: as a line inks on, it fires a random pitched blip every couple of
    /// characters, skipping whitespace (colour tags are already skipped upstream by NarratorView),
    /// for an Animal-Crossing / Undertale style of talking. It listens to the reused NarratorView's
    /// Typed event, so nothing audio is baked into the narrator itself; the blips stop the instant a
    /// line finishes or is advanced (the events stop). Tuned for the current lower, warmer clips: a
    /// narrow pitch spread so it reads as a talky mutter rather than a shrill stutter, and it always
    /// blips on the first revealed character so it never silently drops out. The clips are
    /// placeholders, easy to swap. One job: turn typing into a voice.
    /// </summary>
    [RequireComponent(typeof(AudioSource))]
    public sealed class ImpVoice : MonoBehaviour
    {
        [Header("References")]
        [SerializeField] private NarratorView _narrator;
        [Tooltip("Six short pitched blips; a random one plays per blip.")]
        [SerializeField] private AudioClip[] _clips;

        [Header("Feel")]
        [SerializeField, Range(0f, 1f)] private float _volume = 0.5f;
        [Tooltip("Random pitch each blip. A narrow spread around 1 keeps the low, warm clips talky " +
                 "rather than shrill; widen it for more gibberish variety.")]
        [SerializeField] private float _pitchMin = 0.94f;
        [SerializeField] private float _pitchMax = 1.14f;
        [Tooltip("One blip per this many revealed non-whitespace characters (the first char always blips).")]
        [SerializeField, Min(1)] private int _charsPerBlip = 2;

        private AudioSource _source;
        private int _untilBlip;

        private void Awake()
        {
            _source = GetComponent<AudioSource>();
            _source.playOnAwake = false;
            _source.spatialBlend = 0f; // 2D
        }

        private void OnEnable()
        {
            if (_narrator != null) { _narrator.Typed += OnTyped; _narrator.Speaking += OnSpeaking; }
        }

        private void OnDisable()
        {
            if (_narrator != null) { _narrator.Typed -= OnTyped; _narrator.Speaking -= OnSpeaking; }
        }

        private void OnSpeaking(bool on)
        {
            if (on) _untilBlip = 0; // fresh line: the first revealed character blips
        }

        private void OnTyped(char c)
        {
            if (c == ' ' || c == '\n' || c == '\r' || c == '\t') return; // silence on gaps
            if (_untilBlip <= 0) { Blip(); _untilBlip = Mathf.Max(1, _charsPerBlip); }
            _untilBlip--;
        }

        private void Blip()
        {
            if (_source == null || _clips == null || _clips.Length == 0) return;
            var clip = _clips[Random.Range(0, _clips.Length)];
            if (clip == null) return;
            _source.pitch = Random.Range(_pitchMin, _pitchMax);
            _source.PlayOneShot(clip, _volume * GameSettings.SfxScalar);
        }
    }
}
