using System.Collections.Generic;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The bridge between the live run and the on-disk <see cref="SaveData"/>: it reads the profile, money
    /// balance, and purchase ledger off a <see cref="SequenceContext"/> into a save, and applies a save back
    /// onto them. Kept out of both the SaveService (which stays a dumb file store) and the SequencePlayer
    /// (which only decides WHEN to save), so the conversion lives in one small place. One job: translate
    /// between run state and save state.
    /// </summary>
    public static class SaveCapture
    {
        /// <summary>Snapshot the current run into a save aimed at the given chapter scene and beat.</summary>
        public static SaveData Build(string scene, int beatIndex, SequenceContext ctx)
        {
            var data = new SaveData { chapterScene = scene, beatIndex = Mathf.Max(0, beatIndex) };

            if (ctx != null && ctx.Profile != null)
            {
                var snap = ctx.Profile.Snapshot();
                for (int i = 0; i < snap.Count; i++)
                    data.profile.Add(new SaveData.AxisValue(snap[i].Axis.ToString(), snap[i].Value));
            }

            // The money chapter (Chapter 3) carries a balance and a purchase ledger; other chapters do not.
            if (ctx != null && ctx.Money != null)
            {
                data.hasMoney = true;
                data.balance = ctx.Money.Balance;
                if (ctx.Ledger != null)
                {
                    FillRows(data.bought, ctx.Ledger.Bought);
                    FillRows(data.skipped, ctx.Ledger.Skipped);
                }
            }

            return data;
        }

        /// <summary>Apply a saved run onto the live context (Continue restoring a resumed chapter): the
        /// profile tally, and, in the money chapter, the balance and the ledger, all before the beat plays.</summary>
        public static void RestoreInto(SaveData data, SequenceContext ctx)
        {
            if (data == null || ctx == null) return;

            if (ctx.Profile != null)
            {
                var snap = new List<AxisImpact>(data.profile.Count);
                for (int i = 0; i < data.profile.Count; i++)
                    if (System.Enum.TryParse(data.profile[i].axis, out MoralAxis axis))
                        snap.Add(new AxisImpact(axis, data.profile[i].value));
                ctx.Profile.LoadSnapshot(snap);
            }

            if (data.hasMoney && ctx.Money != null)
            {
                ctx.Money.SetBalance(data.balance);
                if (ctx.Ledger != null)
                    ctx.Ledger.LoadFrom(ToEntries(data.bought), ToEntries(data.skipped));
            }
        }

        private static void FillRows(List<SaveData.LedgerRow> dest, List<PurchaseLedger.Entry> src)
        {
            for (int i = 0; i < src.Count; i++)
            {
                var e = src[i];
                dest.Add(new SaveData.LedgerRow(e.Name, (int)e.Doodle, e.Amount, e.Count));
            }
        }

        private static List<PurchaseLedger.Entry> ToEntries(List<SaveData.LedgerRow> rows)
        {
            var list = new List<PurchaseLedger.Entry>(rows.Count);
            for (int i = 0; i < rows.Count; i++)
            {
                var r = rows[i];
                DoodleKind kind = System.Enum.IsDefined(typeof(DoodleKind), r.doodle) ? (DoodleKind)r.doodle : DoodleKind.None;
                list.Add(new PurchaseLedger.Entry(r.name, kind, r.amount, r.count));
            }
            return list;
        }
    }
}
