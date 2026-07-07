using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The shooting apparatus for the man versus the last bear: an ordinary man (a reused
    /// <see cref="Figure"/>) and the last breeding female of her kind (a <see cref="BearFigure"/>)
    /// stand apart in the void, and the player aims a first person
    /// <see cref="Crosshair"/> over them. Whichever the reticle is over takes the amber
    /// <see cref="AimHighlight"/> lock; a click fires at that target and raises a choice. The
    /// struck party then folds and fades with the shared death effect (no strike lines); the
    /// extinction weight is carried by the imp's line, not by any big effect. DilemmaStage sees
    /// only a ConsequencePresenter, so this reuses the binary loop and <see cref="BinaryResolver"/>
    /// untouched: a new dilemma is a new asset plus this station, not new loop code.
    /// </summary>
    public sealed class ShootingConsequence : ConsequencePresenter
    {
        [Header("References")]
        [SerializeField] private Figure _figurePrefab;
        [SerializeField] private BearFigure _bearPrefab;
        [SerializeField] private Crosshair _crosshair;
        [SerializeField] private AimHighlight _aimHighlight;

        [Header("The man (an ordinary life)")]
        [SerializeField] private Vector2 _manFeet = new Vector2(-2.3f, -1.2f);
        [SerializeField] private float _manScale = 1.05f;
        [Tooltip("World centre and full size of the man's aim box (attention lock and hit test).")]
        [SerializeField] private Vector2 _manBoxCenter = new Vector2(-2.3f, -0.6f);
        [SerializeField] private Vector2 _manBoxSize = new Vector2(1.35f, 1.6f);
        [SerializeField] private string _manParty = "man";

        [Header("The bear (the last of her kind)")]
        [SerializeField] private Vector2 _bearFeet = new Vector2(2.2f, -1.2f);
        [SerializeField] private float _bearScale = 1.05f;
        [SerializeField] private Vector2 _bearBoxCenter = new Vector2(2.35f, -0.35f);
        [SerializeField] private Vector2 _bearBoxSize = new Vector2(2.4f, 2f);
        [SerializeField] private string _bearParty = "bear";

        [Header("Timing")]
        [SerializeField] private float _resolveBeat = 0.35f;
        [SerializeField] private float _foldDuration = 0.7f;
        [SerializeField] private float _foldSettle = 0.4f;

        [SerializeField] private Camera _camera;

        private Figure _man;
        private BearFigure _bear;
        private GunSfx _gunSfx;
        private int _manIndex = -1;
        private int _bearIndex = -1;
        private bool _armed;
        private bool _picked;

        private enum Target { None, Man, Bear }

        public override void BuildScene(Dilemma dilemma)
        {
            if (_camera == null) _camera = Camera.main;
            var container = new GameObject("Targets").transform;
            container.SetParent(transform, false);

            _man = Instantiate(_figurePrefab, new Vector3(_manFeet.x, _manFeet.y, 0f), Quaternion.identity, container);
            _man.name = "Man";
            _man.transform.localScale = new Vector3(_manScale, _manScale, 1f);

            _bear = Instantiate(_bearPrefab, new Vector3(_bearFeet.x, _bearFeet.y, 0f), Quaternion.identity, container);
            _bear.name = "Bear";
            _bear.transform.localScale = new Vector3(_bearScale, _bearScale, 1f);

            var choices = dilemma.Choices;
            for (int i = 0; i < choices.Count; i++)
            {
                if (choices[i].StruckParty == _manParty) _manIndex = i;
                else if (choices[i].StruckParty == _bearParty) _bearIndex = i;
            }

            if (_crosshair != null)
            {
                _crosshair.Fired += OnFired;
                _crosshair.Arm(false);
                _gunSfx = _crosshair.GetComponent<GunSfx>();   // the gun's shot lives with the gun
            }
            if (_aimHighlight != null) _aimHighlight.Hide();
        }

        public override void ArmChoice(bool on)
        {
            _armed = on;
            if (_crosshair != null) _crosshair.Arm(on);
            if (!on && _aimHighlight != null) _aimHighlight.Hide();
        }

        public override void OnCommitted(DilemmaChoice choice, int index)
        {
            // The trigger pull: fire the shot once, immediately, on any committed choice (covers the
            // text fallback path too), and lock aiming down.
            _picked = true;
            if (_gunSfx != null) _gunSfx.Fire();
            if (_crosshair != null) _crosshair.Arm(false);
            if (_aimHighlight != null) _aimHighlight.Hide();
        }

        private void Update()
        {
            if (!_armed || _picked) return;
            if (_camera == null) { _camera = Camera.main; if (_camera == null) return; }

            Vector3 aim = PointerInput.WorldPosition(_camera);
            Target t = TargetAt(aim);

            if (_aimHighlight != null)
            {
                if (t == Target.Man) _aimHighlight.Show(_manBoxCenter, _manBoxSize);
                else if (t == Target.Bear) _aimHighlight.Show(_bearBoxCenter, _bearBoxSize);
                else _aimHighlight.Hide();
            }
        }

        private void OnFired(Vector3 aimPoint)
        {
            if (!_armed || _picked) return;
            Target t = TargetAt(aimPoint);
            if (t == Target.Man && _manIndex >= 0) { _picked = true; RaiseChosen(_manIndex); }
            else if (t == Target.Bear && _bearIndex >= 0) { _picked = true; RaiseChosen(_bearIndex); }
            // A shot into the empty void hits nothing and does not choose.
        }

        private Target TargetAt(Vector2 p)
        {
            if (InBox(p, _manBoxCenter, _manBoxSize)) return Target.Man;
            if (InBox(p, _bearBoxCenter, _bearBoxSize)) return Target.Bear;
            return Target.None;
        }

        private static bool InBox(Vector2 p, Vector2 center, Vector2 size)
            => Mathf.Abs(p.x - center.x) <= size.x * 0.5f && Mathf.Abs(p.y - center.y) <= size.y * 0.5f;

        public override IEnumerator PlayConsequence(DilemmaChoice choice, DilemmaOutcome outcome)
        {
            if (_crosshair != null) _crosshair.Arm(false);
            if (_aimHighlight != null) _aimHighlight.Hide();

            yield return new WaitForSeconds(_resolveBeat);

            // The death is only the fold-and-fall, no strike lines: the man, or the bear, folds
            // and fades as one. The extinction weight lives in the imp's line.
            if (outcome.Strikes(_manParty) && _man != null) _man.Strike(_foldDuration);
            if (outcome.Strikes(_bearParty) && _bear != null) _bear.Strike(_foldDuration);

            yield return new WaitForSeconds(_foldDuration + _foldSettle);
        }

        private void OnDestroy()
        {
            if (_crosshair != null) _crosshair.Fired -= OnFired;
        }
    }
}
