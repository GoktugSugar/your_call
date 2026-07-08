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
        [Tooltip("The main-track figures are branded with a red (guilty) outline (all of them). The Marked Ones trolley.")]
        [SerializeField] private bool _figuresBranded = false;
        [Tooltip("Indices of specific main-track figures drawn with a red (guilty) outline, on top of Figures Branded. The murderer in The Passenger.")]
        [SerializeField] private List<int> _brandedMainIndices = new List<int>();
        [Tooltip("Indices of specific branch-track figures drawn with a red (guilty) outline. The cruel man in The Reformed and the Cruel.")]
        [SerializeField] private List<int> _brandedSpurIndices = new List<int>();
        [Tooltip("The main-track figures are asleep: they show small drifting z marks. The Sleeping.")]
        [SerializeField] private bool _mainAsleep = false;
        [Tooltip("The branch-track figures are asleep: they show small drifting z marks.")]
        [SerializeField] private bool _spurAsleep = false;
        [Tooltip("The main-track figures are the player's partner: pink outline and a little heart. Unused so far.")]
        [SerializeField] private bool _mainPartner = false;
        [Tooltip("The branch-track figures are the player's partner (the loved one): pink outline and a little heart. Someone You Loved.")]
        [SerializeField] private bool _spurPartner = false;
        [Tooltip("Optional: a different figure prefab for the main track (for example the baby). Empty uses the station's default figure.")]
        [SerializeField] private Figure _mainFigurePrefab;
        [Tooltip("Optional: a different figure prefab for the branch track. Empty uses the station's default figure.")]
        [SerializeField] private Figure _spurFigurePrefab;
        [Tooltip("Optional: a short plea floated in ink over the lone branch figure (the Begging trolley). Empty shows none.")]
        [SerializeField, TextArea] private string _spurPlea;
        [Tooltip("Optional: a short plea floated in ink over the lone main-track figure (the Parent, once the parent sits on the default track). Empty shows none.")]
        [SerializeField, TextArea] private string _mainPlea;

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
        public IReadOnlyList<int> BrandedMainIndices => _brandedMainIndices;
        public IReadOnlyList<int> BrandedSpurIndices => _brandedSpurIndices;
        public bool MainAsleep => _mainAsleep;
        public bool SpurAsleep => _spurAsleep;
        public bool MainPartner => _mainPartner;
        public bool SpurPartner => _spurPartner;
        public Figure MainFigurePrefab => _mainFigurePrefab;
        public Figure SpurFigurePrefab => _spurFigurePrefab;
        public string SpurPlea => _spurPlea;
        public string MainPlea => _mainPlea;
        public string StatsHeading => _statsHeading;
        public float RoomBlueFraction => _roomBlueFraction;
        public float CrowdThreshold => _crowdThreshold;
        public string ThresholdLabel => _thresholdLabel;
    }
}
