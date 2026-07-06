using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The blue/red button room: a seeded room of the newly dead (a fixed backdrop) plus one
    /// distinguished soul, the player's charge. Blue spares the charge for certain; red gambles
    /// the charge on the room. When the gamble fails, only the charge folds and fades as one
    /// unit (reuse the Figure fold); the room, the aggregate that decided it, stays standing.
    /// One presenter, one job; the struck/spared outcome comes from the resolver.
    /// </summary>
    public sealed class RoomConsequence : ConsequencePresenter
    {
        [Header("References")]
        [SerializeField] private Figure _figurePrefab;
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private ButtonChoice _buttons;

        [Header("The charge (the soul in the player's care)")]
        [SerializeField] private Vector2 _chargePosition = new Vector2(0f, -1.0f);
        [SerializeField] private float _chargeScale = 1.1f;
        [SerializeField] private string _chargeParty = "charge";

        [Header("The room (seeded crowd, a fixed backdrop)")]
        [SerializeField] private int _roomCount = 14;
        [SerializeField] private int _perRow = 7;
        [SerializeField] private Vector2 _roomCenter = new Vector2(0f, -2.6f);
        [SerializeField] private float _columnSpacing = 0.55f;
        [SerializeField] private float _rowSpacing = 0.8f;
        [SerializeField] private float _roomScale = 0.72f;
        [SerializeField] private float _rowShrink = 0.05f;
        [SerializeField] private float _jitter = 0.06f;

        [Header("Timing")]
        [SerializeField] private float _resolveBeat = 0.35f;
        [SerializeField] private float _foldDuration = 0.7f;
        [SerializeField] private float _foldSettle = 0.35f;

        private Figure _charge;

        public override void BuildScene(Dilemma dilemma)
        {
            var room = new GameObject("Room").transform;
            room.SetParent(transform, false);
            BuildRoom(room);

            _charge = Instantiate(_figurePrefab, new Vector3(_chargePosition.x, _chargePosition.y, 0f), Quaternion.identity, transform);
            _charge.name = "Charge";
            _charge.transform.localScale = new Vector3(_chargeScale, _chargeScale, 1f);

            if (_buttons != null)
            {
                _buttons.Build();
                _buttons.Chosen += RaiseChosen;
                _buttons.Arm(false);
            }
        }

        private void BuildRoom(Transform parent)
        {
            int rows = Mathf.CeilToInt(_roomCount / (float)Mathf.Max(1, _perRow));
            int made = 0;
            for (int row = 0; row < rows && made < _roomCount; row++)
            {
                int inRow = Mathf.Min(_perRow, _roomCount - made);
                float rowWidth = (inRow - 1) * _columnSpacing;
                for (int col = 0; col < inRow; col++)
                {
                    float x = _roomCenter.x - rowWidth * 0.5f + col * _columnSpacing + Hash(made * 3 + 1) * _jitter;
                    float y = _roomCenter.y - row * _rowSpacing + Hash(made * 3 + 2) * _jitter;
                    var fig = Instantiate(_figurePrefab, new Vector3(x, y, 0f), Quaternion.identity, parent);
                    float scale = _roomScale * (1f - row * _rowShrink);
                    fig.transform.localScale = new Vector3(scale, scale, 1f);
                    made++;
                }
            }
        }

        public override void ArmChoice(bool on) { if (_buttons != null) _buttons.Arm(on); }

        public override void OnCommitted(DilemmaChoice choice, int index)
        {
            if (_buttons != null) _buttons.Lock(index);
        }

        public override IEnumerator PlayConsequence(DilemmaChoice choice, DilemmaOutcome outcome)
        {
            yield return new WaitForSeconds(_resolveBeat);

            if (outcome.Strikes(_chargeParty) && _charge != null)
            {
                SpawnPuff(_charge.transform.position + Vector3.up * (0.6f * _chargeScale));
                _charge.Strike(_foldDuration);
                yield return new WaitForSeconds(_foldDuration + _foldSettle);
            }
            else
            {
                // Spared: a held breath, then the charge stays standing.
                yield return new WaitForSeconds(_resolveBeat);
            }
        }

        private void SpawnPuff(Vector3 pos)
        {
            var go = new GameObject("PuffCue");
            var puff = go.AddComponent<PuffCue>();
            puff.Configure(_inkMaterial);
            puff.Play(pos);
        }

        private void OnDestroy()
        {
            if (_buttons != null) _buttons.Chosen -= RaiseChosen;
        }

        private static float Hash(int x)
        {
            unchecked
            {
                x = (x ^ 61) ^ (x >> 16);
                x += x << 3;
                x ^= x >> 4;
                x *= 0x27d4eb2d;
                x ^= x >> 15;
                return (((x & 0x7fffffff) % 1000) / 1000f) - 0.5f;
            }
        }
    }
}
