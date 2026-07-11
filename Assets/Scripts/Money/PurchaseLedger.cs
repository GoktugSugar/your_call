using System.Collections.Generic;

namespace YourCall
{
    /// <summary>
    /// A run-scoped record of what the player bought and passed on in the money chapter (Chapter 3), so the
    /// end-of-chapter overview / receipt (see <see cref="ChapterOverview"/>) can list the purchases with
    /// their doodles and prices. A plain service, not a scene object: <see cref="SequencePlayer"/> creates
    /// one when a chapter has a <see cref="MoneyBalance"/> and hands it to the beats on the
    /// <see cref="SequenceContext"/>, null in every other chapter. One job: keep the run's purchase list.
    /// </summary>
    public sealed class PurchaseLedger
    {
        /// <summary>One line on the receipt: what it was (its item name and its doodle), what was paid, and
        /// how many units (1 for a single buy, N for a bulk buy like years of life).</summary>
        public sealed class Entry
        {
            public readonly string Name;       // English source string, localized at display time
            public readonly DoodleKind Doodle;
            public readonly int Amount;        // total paid (for a skip, the price they passed on)
            public readonly int Count;         // units bought (0 for a skip)

            public Entry(string name, DoodleKind doodle, int amount, int count)
            {
                Name = name; Doodle = doodle; Amount = amount; Count = count;
            }
        }

        public readonly List<Entry> Bought = new List<Entry>();
        public readonly List<Entry> Skipped = new List<Entry>();

        /// <summary>Record a purchase (a single buy, or a bulk buy of <paramref name="count"/> units).</summary>
        public void RecordBuy(string name, DoodleKind doodle, int amount, int count = 1)
        {
            if (count <= 0 || amount <= 0) return;
            Bought.Add(new Entry(name, doodle, amount, count));
        }

        /// <summary>Record something the player passed on, so the overview can note what they gave up.</summary>
        public void RecordSkip(string name, DoodleKind doodle, int price)
        {
            Skipped.Add(new Entry(name, doodle, price, 0));
        }

        /// <summary>Undo a recorded buy by name (the poverty refund: End Poverty was bought, then refunded,
        /// so it should not appear as a purchase on the receipt).</summary>
        public void RemoveBought(string name)
        {
            if (string.IsNullOrEmpty(name)) return;
            Bought.RemoveAll(e => e.Name == name);
        }

        /// <summary>Total the player actually spent on things they kept (net of any removed/refunded buys).</summary>
        public int TotalSpent
        {
            get { int s = 0; for (int i = 0; i < Bought.Count; i++) s += Bought[i].Amount; return s; }
        }

        /// <summary>Replace the ledger with a saved snapshot (Continue restoring a mid-chapter money run), so
        /// the buyback and the end-of-chapter receipt see exactly what the player had bought and skipped.</summary>
        public void LoadFrom(IEnumerable<Entry> savedBought, IEnumerable<Entry> savedSkipped)
        {
            Bought.Clear();
            Skipped.Clear();
            if (savedBought != null) Bought.AddRange(savedBought);
            if (savedSkipped != null) Skipped.AddRange(savedSkipped);
        }
    }
}
