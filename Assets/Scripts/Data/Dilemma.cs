using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Serialization;

namespace YourCall
{
    /// <summary>
    /// A self-contained dilemma as data. New content is a new asset, not new loop code
    /// (see docs/tech.md, data model). Adding a dilemma is a new asset plus, for a new
    /// verb, a new resolver, never edits to the core loop.
    /// </summary>
    [CreateAssetMenu(fileName = "Dilemma", menuName = "Your Call/Dilemma")]
    public class Dilemma : ScriptableObject
    {
        [SerializeField] private string _id;
        [SerializeField] private DilemmaVerb _verb = DilemmaVerb.Binary;

        [Tooltip("Scales the consequence duration.")]
        [SerializeField] private DilemmaWeight _weight = DilemmaWeight.Medium;

        [SerializeField, TextArea(2, 6)] private string _narratorPrompt;
        [SerializeField] private List<DilemmaChoice> _choices = new List<DilemmaChoice>();

        [Header("Figures (trolley beats)")]
        [Tooltip("How many figures stand on the main (straight) track. Lets one shared trolley station serve many dilemmas.")]
        [SerializeField] private int _mainFigureCount = 5;
        [Tooltip("How many figures stand on the branch (spur) track.")]
        [SerializeField] private int _spurFigureCount = 1;
        [Tooltip("The main-track figures are branded with a red outline (the imp's damned wretches). The Marked Ones trolley only.")]
        [SerializeField] private bool _figuresBranded = false;
        [Tooltip("Optional: a different figure prefab for the main track (for example the baby). Empty uses the station's default figure.")]
        [SerializeField] private Figure _mainFigurePrefab;
        [Tooltip("Optional: a different figure prefab for the branch track. Empty uses the station's default figure.")]
        [SerializeField] private Figure _spurFigurePrefab;
        [Tooltip("Optional: a short plea floated in ink over the lone branch figure (the Begging trolley). Empty shows none.")]
        [SerializeField, TextArea] private string _spurPlea;

        [Header("Aftermath stats")]
        [SerializeField] private string _statsHeading = "how others chose";

        [Header("Coordination gamble (ignored by other verbs)")]
        [Tooltip("Seeded fraction of the room that pressed blue.")]
        [FormerlySerializedAs("_crowdSafeFraction")]
        [SerializeField, Range(0f, 1f)] private float _roomBlueFraction = 0.43f;
        [Tooltip("The blue fraction the room must reach for the blue gamble to spare the charge.")]
        [SerializeField, Range(0f, 1f)] private float _crowdThreshold = 0.5f;
        [Tooltip("Label for the threshold marker on the stats screen.")]
        [SerializeField] private string _thresholdLabel = "the line";

        public string Id => _id;
        public DilemmaVerb Verb => _verb;
        public DilemmaWeight Weight => _weight;
        public string NarratorPrompt => _narratorPrompt;
        public IReadOnlyList<DilemmaChoice> Choices => _choices;
        public int MainFigureCount => _mainFigureCount;
        public int SpurFigureCount => _spurFigureCount;
        public bool FiguresBranded => _figuresBranded;
        public Figure MainFigurePrefab => _mainFigurePrefab;
        public Figure SpurFigurePrefab => _spurFigurePrefab;
        public string SpurPlea => _spurPlea;
        public string StatsHeading => _statsHeading;
        public float RoomBlueFraction => _roomBlueFraction;
        public float CrowdThreshold => _crowdThreshold;
        public string ThresholdLabel => _thresholdLabel;
    }
}
