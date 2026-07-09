using System;
using System.Collections.Generic;

namespace YourCall
{
    /// <summary>
    /// The on-disk shape of one language file (Assets/Resources/Localization/&lt;code&gt;.json), parsed by
    /// Unity's JsonUtility so any characters, punctuation, colour markup and format placeholders survive
    /// intact. A flat list of entries: <see cref="LocEntry.k"/> is the English source string (the key the
    /// runtime looks up) and <see cref="LocEntry.v"/> is the translation. <see cref="LocEntry.area"/> is
    /// documentation only (it groups the file for a human translator and is ignored at runtime). Adding a
    /// language means writing one of these files with the same keys; see <see cref="Localization"/>.
    /// </summary>
    [Serializable]
    public sealed class LocalizationData
    {
        public List<LocEntry> entries = new List<LocEntry>();
    }

    [Serializable]
    public sealed class LocEntry
    {
        /// <summary>Documentation only: which part of the game this string belongs to (menu, dilemma, ...).</summary>
        public string area;

        /// <summary>The key: the exact English source string the game passes to the localization layer.</summary>
        public string k;

        /// <summary>The translation shown for this language. Empty falls back to the English key.</summary>
        public string v;
    }
}
