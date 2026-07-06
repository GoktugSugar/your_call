using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The coordination gamble apparatus: a crowd of souls and the two ink marks. When the
    /// gamble fails the whole crowd folds together and fades as one connected unit; when it
    /// holds, nothing folds. The outcome (struck or spared) comes from the resolver, not from
    /// here. One presenter, one job.
    /// </summary>
    public sealed class CrowdConsequence : ConsequencePresenter
    {
        [Header("References")]
        [SerializeField] private Figure _figurePrefab;
        [SerializeField] private Material _inkMaterial;
        [SerializeField] private OptionMarks _marks;

        [Header("Crowd layout")]
        [SerializeField] private int _crowdCount = 12;
        [SerializeField] private int _perRow = 6;
        [SerializeField] private Vector2 _crowdCenter = new Vector2(0f, -1.7f);
        [SerializeField] private float _columnSpacing = 0.62f;
        [SerializeField] private float _rowSpacing = 0.95f;
        [SerializeField] private float _jitter = 0.06f;
        [SerializeField] private float _rowShrink = 0.06f;
        [SerializeField] private string _crowdParty = "crowd";

        [Header("Timing")]
        [SerializeField] private float _resolveBeat = 0.35f;
        [SerializeField] private float _foldDuration = 0.75f;
        [SerializeField] private float _foldSettle = 0.35f;

        private readonly List<Figure> _crowd = new List<Figure>();

        public override void BuildScene(Dilemma dilemma)
        {
            var container = new GameObject("Crowd").transform;
            container.SetParent(transform, false);

            int rows = Mathf.CeilToInt(_crowdCount / (float)Mathf.Max(1, _perRow));
            int made = 0;
            for (int row = 0; row < rows && made < _crowdCount; row++)
            {
                int inRow = Mathf.Min(_perRow, _crowdCount - made);
                float rowWidth = (inRow - 1) * _columnSpacing;
                for (int col = 0; col < inRow; col++)
                {
                    float x = _crowdCenter.x - rowWidth * 0.5f + col * _columnSpacing + Hash(made * 3 + 1) * _jitter;
                    float y = _crowdCenter.y - row * _rowSpacing + Hash(made * 3 + 2) * _jitter;
                    var fig = Instantiate(_figurePrefab, new Vector3(x, y, 0f), Quaternion.identity, container);
                    float scale = 1f - row * _rowShrink;
                    fig.transform.localScale = new Vector3(scale, scale, 1f);
                    _crowd.Add(fig);
                    made++;
                }
            }

            if (_marks != null)
            {
                _marks.Build(dilemma);
                _marks.Chosen += RaiseChosen;
                _marks.Arm(false);
            }
        }

        public override void ArmChoice(bool on) { if (_marks != null) _marks.Arm(on); }

        public override void OnCommitted(DilemmaChoice choice, int index)
        {
            if (_marks != null) _marks.Lock(index);
        }

        public override IEnumerator PlayConsequence(DilemmaChoice choice, DilemmaOutcome outcome)
        {
            yield return new WaitForSeconds(_resolveBeat);

            if (outcome.Strikes(_crowdParty))
            {
                SpawnPuff(new Vector3(_crowdCenter.x, _crowdCenter.y + 0.6f, 0f));
                for (int i = 0; i < _crowd.Count; i++) _crowd[i].Strike(_foldDuration);
                yield return new WaitForSeconds(_foldDuration + _foldSettle);
            }
            else
            {
                // Spared: a held breath, then they stay standing.
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
            if (_marks != null) _marks.Chosen -= RaiseChosen;
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
