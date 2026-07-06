using System.Collections.Generic;
using UnityEngine;

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

        [Header("Aftermath stats")]
        [SerializeField] private string _statsHeading = "how others chose";

        [Header("Coordination gamble (ignored by other verbs)")]
        [Tooltip("Seeded fraction of the crowd that holds the line (chooses safe).")]
        [SerializeField, Range(0f, 1f)] private float _crowdSafeFraction = 0.43f;
        [Tooltip("The fraction the crowd must reach for the gamble to spare them.")]
        [SerializeField, Range(0f, 1f)] private float _crowdThreshold = 0.5f;
        [Tooltip("Label for the threshold marker on the stats screen.")]
        [SerializeField] private string _thresholdLabel = "the line";

        public string Id => _id;
        public DilemmaVerb Verb => _verb;
        public DilemmaWeight Weight => _weight;
        public string NarratorPrompt => _narratorPrompt;
        public IReadOnlyList<DilemmaChoice> Choices => _choices;
        public string StatsHeading => _statsHeading;
        public float CrowdSafeFraction => _crowdSafeFraction;
        public float CrowdThreshold => _crowdThreshold;
        public string ThresholdLabel => _thresholdLabel;
    }
}
