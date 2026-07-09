using System;

namespace YourCall
{
    /// <summary>
    /// One available language: its code (the Resources file name, e.g. "tr" for
    /// Localization/tr.json), the name shown in the settings list (written in that language, so
    /// "Türkçe" not "Turkish"), and the .NET culture used for number and currency formatting.
    /// No dashes in player-facing text.
    /// </summary>
    [Serializable]
    public struct LanguageInfo
    {
        public string Code;
        public string NativeName;
        public string Culture;

        public LanguageInfo(string code, string nativeName, string culture)
        {
            Code = code; NativeName = nativeName; Culture = culture;
        }
    }

    /// <summary>
    /// The registry of shipped languages. English is the default and the source of truth (its copy
    /// lives inline in the assets and scenes; see docs/tech.md, localization). Adding a language is
    /// two steps: drop its data file at Assets/Resources/Localization/&lt;code&gt;.json (the same keys,
    /// translated) and add one line here so the settings list offers it. The settings menu reads this
    /// list, so the language picker grows with the files. One job: know which languages exist.
    /// </summary>
    public static class Languages
    {
        public const string DefaultCode = "en";

        public static readonly LanguageInfo[] All =
        {
            new LanguageInfo("en", "English", "en"),
            new LanguageInfo("tr", "Türkçe",  "tr-TR"),
        };

        public static bool Has(string code)
        {
            if (string.IsNullOrEmpty(code)) return false;
            for (int i = 0; i < All.Length; i++)
                if (string.Equals(All[i].Code, code, StringComparison.OrdinalIgnoreCase)) return true;
            return false;
        }

        public static int IndexOf(string code)
        {
            if (!string.IsNullOrEmpty(code))
                for (int i = 0; i < All.Length; i++)
                    if (string.Equals(All[i].Code, code, StringComparison.OrdinalIgnoreCase)) return i;
            return 0;
        }

        public static LanguageInfo Get(string code)
        {
            int i = IndexOf(code);
            return All[i];
        }
    }
}
