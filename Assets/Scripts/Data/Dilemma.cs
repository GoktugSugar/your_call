using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// A self-contained dilemma as data. New content is a new asset, not new loop code
    /// (see docs/tech.md, data model). The first dilemma ships as Assets/Data/Trolley.asset.
    /// </summary>
    [CreateAssetMenu(fileName = "Dilemma", menuName = "Your Call/Dilemma")]
    public class Dilemma : ScriptableObject
    {
        [SerializeField] private string _id;
        [SerializeField] private DilemmaVerb _verb = DilemmaVerb.Binary;

        [Tooltip("Scales the consequence duration.")]
        [SerializeField] private DilemmaWeight _weight = DilemmaWeight.Medium;

        [SerializeField, TextArea(2, 5)] private string _narratorPrompt;
        [SerializeField] private List<DilemmaChoice> _choices = new List<DilemmaChoice>();

        public string Id => _id;
        public DilemmaVerb Verb => _verb;
        public DilemmaWeight Weight => _weight;
        public string NarratorPrompt => _narratorPrompt;
        public IReadOnlyList<DilemmaChoice> Choices => _choices;
    }
}
