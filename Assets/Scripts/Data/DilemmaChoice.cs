using System;
using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// One option the player can take in a dilemma. Data only. Player-facing strings
    /// carry no dashes (a project-wide rule). profileImpact is recorded silently and
    /// never drawn.
    /// </summary>
    [Serializable]
    public class DilemmaChoice
    {
        [SerializeField] private string _id;
        [SerializeField, TextArea] private string _label;
        [SerializeField, TextArea] private string _narratorReact;

        [Tooltip("Which track the trolley runs / which group is struck, e.g. \"straight\" or \"spur\".")]
        [SerializeField] private string _route = "straight";

        [Tooltip("Does this choice throw the lever?")]
        [SerializeField] private bool _diverts;

        [Tooltip("Display-only seeded tally for the aftermath screen.")]
        [SerializeField] private int _seedVotes;

        [SerializeField] private List<AxisImpact> _profileImpact = new List<AxisImpact>();

        public string Id => _id;
        public string Label => _label;
        public string NarratorReact => _narratorReact;
        public string Route => _route;
        public bool Diverts => _diverts;
        public int SeedVotes => _seedVotes;
        public IReadOnlyList<AxisImpact> ProfileImpact => _profileImpact;
    }
}
