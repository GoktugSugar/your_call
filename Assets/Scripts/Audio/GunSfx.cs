using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The gun's one shot: a single placeholder gunshot clip played once when the player fires,
    /// on its own AudioSource so no audio lives in the shooting presenter (the same split as
    /// <see cref="ImpVoice"/>, which keeps audio out of the narrator). The presenter calls
    /// <see cref="Fire"/> on the committed shot. Volume is exposed; the clip is a placeholder,
    /// easy to swap. One job: bang, once, on request.
    /// </summary>
    [RequireComponent(typeof(AudioSource))]
    public sealed class GunSfx : MonoBehaviour
    {
        [Tooltip("The gunshot clip (placeholder, easy to swap).")]
        [SerializeField] private AudioClip _clip;
        [SerializeField, Range(0f, 1f)] private float _volume = 0.8f;

        private AudioSource _source;

        private void Awake()
        {
            _source = GetComponent<AudioSource>();
            _source.playOnAwake = false;
            _source.spatialBlend = 0f; // 2D
        }

        /// <summary>Play the gunshot once.</summary>
        public void Fire()
        {
            if (_source == null || _clip == null) return;
            _source.PlayOneShot(_clip, _volume);
        }
    }
}
