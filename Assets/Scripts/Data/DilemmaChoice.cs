using System;
using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// One option the player can take in a dilemma. Data only. Player-facing strings
    /// carry no dashes (a project-wide rule). profileImpact is recorded silently and
    /// never drawn. The verb resolver reads the resolution fields; the presenter reads
    /// the presentation fields.
    /// </summary>
    [Serializable]
    public class DilemmaChoice
    {
        [SerializeField] private string _id;
        [SerializeField, TextArea] private string _label;

        [Header("Narrator")]
        [SerializeField, TextArea] private string _narratorReact;
        [Tooltip("Optional reaction used when this choice's at-risk party is struck (for example a lost coordination gamble). Falls back to Narrator React if empty.")]
        [SerializeField, TextArea] private string _narratorReactStruck;

        [Header("Resolution (read by the verb resolver)")]
        [Tooltip("A party this choice always strikes, for example \"main\" or \"spur\". Empty means none.")]
        [SerializeField] private string _struckParty;
        [Tooltip("A party struck only if a coordination gamble fails, for example \"charge\". Empty means none.")]
        [SerializeField] private string _gambledParty;

        [Header("Trolley presentation")]
        [Tooltip("Which track the trolley runs, for example \"straight\" or \"spur\".")]
        [SerializeField] private string _route = "straight";
        [Tooltip("Does this choice throw the lever?")]
        [SerializeField] private bool _diverts;

        [Header("Stats")]
        [Tooltip("Display-only seeded tally for the aftermath screen (reflective verbs).")]
        [SerializeField] private int _seedVotes;

        [Header("Ending (a choice-triggered ending, like shooting the imp)")]
        [Tooltip("If set, taking this choice ends the run: after the consequence plays, the loop hands off " +
                 "to an ending (the imp's break line, then the credits) instead of the normal reaction and " +
                 "stats. The baby opener's kill-the-baby choice uses this. Ignored unless the beat wires an " +
                 "ending handler, so it is safe to leave off everywhere else.")]
        [SerializeField] private bool _endsGame;

        [SerializeField] private List<AxisImpact> _profileImpact = new List<AxisImpact>();

        public string Id => _id;
        public string Label => _label;
        public string NarratorReact => _narratorReact;
        public string NarratorReactStruck => _narratorReactStruck;
        public string StruckParty => _struckParty;
        public string GambledParty => _gambledParty;
        public string Route => _route;
        public bool Diverts => _diverts;
        public int SeedVotes => _seedVotes;
        public bool EndsGame => _endsGame;
        public IReadOnlyList<AxisImpact> ProfileImpact => _profileImpact;
    }
}
