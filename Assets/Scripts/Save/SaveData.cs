using System;
using System.Collections.Generic;

namespace YourCall
{
    /// <summary>
    /// The serialized shape of a single continuous run, written to disk by <see cref="SaveService"/> and
    /// used by Continue to resume at the EXACT beat the player left off. It captures everything a resume
    /// needs, not just a beat pointer (see docs/tech.md): WHERE in the sequence (the chapter scene and the
    /// beat to enter), WHO the player is becoming (the silent profile tally), and the money chapter's
    /// economy (the balance and the purchase ledger), plus a small forward-looking record of endings seen.
    ///
    /// Versioned so a future format change can be migrated or safely invalidated rather than crashing on an
    /// old file (<see cref="SaveService.TryLoad"/> rejects an unrecognised version, which just disables
    /// Continue). Plain public fields and nested [Serializable] types so Unity's JsonUtility round-trips it.
    /// The profile axis is stored by NAME and the doodle by ordinal, so appending new axes / doodles (the
    /// documented append-only rule) never invalidates an existing save. One job: be the on-disk run state.
    /// </summary>
    [Serializable]
    public sealed class SaveData
    {
        /// <summary>Bump when the shape changes incompatibly; <see cref="SaveService"/> invalidates mismatches.</summary>
        public const int CurrentVersion = 1;

        public int version = CurrentVersion;

        // ---- WHERE: the exact position in the run ----
        // The chapter scene to load (Opening / ChapterTwo / ChapterThree)...
        public string chapterScene = "";
        // ...and the beat index within that chapter's SequencePlayer to resume at.
        public int beatIndex = 0;

        // ---- WHO: the silent profile, stored by axis NAME (unknown names ignored on load) ----
        public List<AxisValue> profile = new List<AxisValue>();

        // ---- The money chapter (Chapter 3) economy; hasMoney is false in the other chapters ----
        public bool hasMoney = false;
        public int balance = 0;
        public List<LedgerRow> bought = new List<LedgerRow>();
        public List<LedgerRow> skipped = new List<LedgerRow>();

        /// <summary>One profile axis and its accumulated value. Stored by name so appending a new
        /// <see cref="MoralAxis"/> value never shifts what an old save decodes to.</summary>
        [Serializable]
        public struct AxisValue
        {
            public string axis;   // MoralAxis name
            public float value;
            public AxisValue(string axis, float value) { this.axis = axis; this.value = value; }
        }

        /// <summary>One purchase-ledger row (a bought or skipped item), mirroring
        /// <see cref="PurchaseLedger.Entry"/> in a JsonUtility-friendly shape.</summary>
        [Serializable]
        public struct LedgerRow
        {
            public string name;    // English source item name, localized at display time
            public int doodle;     // DoodleKind ordinal (the enum is append-only, so this is stable)
            public int amount;     // total paid (for a skip, the price passed on)
            public int count;      // units bought (0 for a skip)
            public LedgerRow(string name, int doodle, int amount, int count)
            {
                this.name = name; this.doodle = doodle; this.amount = amount; this.count = count;
            }
        }
    }
}
