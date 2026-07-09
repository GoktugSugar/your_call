using System;
using System.Collections.Generic;
using System.Globalization;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// The localization layer. Every player-facing string is routed through here at the point it is
    /// shown (the narrator box, the choice buttons, the stats, the menus, the credits), keyed by its
    /// English source text. English is the default and needs no file: <see cref="Localize"/> returns
    /// the source unchanged, so the game reads exactly as authored and nothing is hardcoded past this
    /// layer. Selecting another language loads its overlay file (Assets/Resources/Localization/&lt;code&gt;.json)
    /// and <see cref="Localize"/> returns the translation for a key, falling back to the English source
    /// whenever a key is missing, so a partial translation never shows blank.
    ///
    /// Adding a language is one data file of the same keys plus one line in <see cref="Languages"/>.
    /// Numbers and currency route through <see cref="Number"/> / <see cref="Money"/> so they format for
    /// the active language's culture (and the currency shape itself is overridable per language). Authored
    /// colour markup ([amber], [red], ...) and format placeholders ({0}) travel inside each string, so a
    /// translation marks its own words and keeps its own number slots.
    ///
    /// Static, so it survives scene loads with no object to place; <see cref="GameSettings"/> drives it
    /// from the saved setting on boot. One job: turn an English source string into the active language.
    /// </summary>
    public static class Localization
    {
        /// <summary>The active language code ("en", "tr", ...).</summary>
        public static string CurrentCode { get; private set; } = Languages.DefaultCode;

        /// <summary>The culture used for number and currency formatting in the active language.</summary>
        public static CultureInfo Culture { get; private set; } = SafeCulture(Languages.Get(Languages.DefaultCode).Culture);

        /// <summary>Raised after the language changes, so persistent UI (menu, settings) can re-localize live.</summary>
        public static event Action LanguageChanged;

        // The active overlay: English source -> translation. Null for English (the source is used directly).
        private static Dictionary<string, string> _map;
        private static bool _applied;

        // PlayerPrefs key, shared with GameSettings, so the saved choice applies even in scenes that have
        // no GameSettings (the standalone test scenes and dev-picker jumps).
        private const string LanguageKey = "settings.language";

        /// <summary>
        /// Apply the saved language before any scene loads, so every scene respects the player's choice,
        /// not just the main-menu flow. GameSettings re-applies the same value on boot where present
        /// (a no-op here, thanks to the same-code guard below). Runs in play mode and in builds.
        /// </summary>
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        private static void Bootstrap()
        {
            SetLanguage(PlayerPrefs.GetString(LanguageKey, Languages.DefaultCode));
        }

        /// <summary>
        /// Select the active language by code. English clears the overlay (source strings are used as is);
        /// any other language loads its file. Unknown codes fall back to English. Safe to call repeatedly:
        /// a redundant call for the language already active does nothing (so it never reloads or re-broadcasts).
        /// </summary>
        public static void SetLanguage(string code)
        {
            if (!Languages.Has(code)) code = Languages.DefaultCode;
            if (_applied && string.Equals(code, CurrentCode, StringComparison.OrdinalIgnoreCase)) return;
            _applied = true;
            CurrentCode = code;
            Culture = SafeCulture(Languages.Get(code).Culture);
            _map = string.Equals(code, Languages.DefaultCode, StringComparison.OrdinalIgnoreCase) ? null : LoadMap(code);
            LanguageChanged?.Invoke();
        }

        /// <summary>
        /// The active-language string for an English source. Returns the translation if the current
        /// language has one, else <paramref name="fallback"/> if given, else the source itself, so a
        /// missing key shows the English (never blank). For plain player copy pass just the source;
        /// the optional fallback is for the few id-style format keys (see <see cref="Money"/>).
        /// </summary>
        public static string Localize(string source, string fallback = null)
        {
            if (_map != null && !string.IsNullOrEmpty(source)
                && _map.TryGetValue(source, out string v) && !string.IsNullOrEmpty(v))
                return v;
            return fallback ?? source;
        }

        /// <summary>Localize a format template, then fill it with <paramref name="args"/> in the active culture.
        /// The template is localized BEFORE formatting, so each language keeps its own wording around the slots.</summary>
        public static string Format(string sourceFormat, params object[] args)
        {
            string f = Localize(sourceFormat);
            if (string.IsNullOrEmpty(f) || args == null || args.Length == 0) return f;
            try { return string.Format(Culture, f, args); }
            catch (FormatException) { return f; }
        }

        /// <summary>A whole number grouped for the active culture (English "1,000", Turkish "1.000").</summary>
        public static string Number(long value) => value.ToString("#,0", Culture);

        /// <summary>A money amount for the active culture. The currency shape is itself localizable via the
        /// "money.pattern" key ({0} is the grouped number); the default keeps the game's dollar sign.</summary>
        public static string Money(long amount)
        {
            string pattern = Localize("money.pattern", "${0}");
            string n = Number(amount);
            try { return string.Format(Culture, pattern, n); }
            catch (FormatException) { return "$" + n; }
        }

        private static Dictionary<string, string> LoadMap(string code)
        {
            var asset = Resources.Load<TextAsset>("Localization/" + code);
            if (asset == null)
            {
                Debug.LogWarning("[Localization] No file at Resources/Localization/" + code + ".json; falling back to English.");
                return null;
            }

            LocalizationData data;
            try { data = JsonUtility.FromJson<LocalizationData>(asset.text); }
            catch (Exception e)
            {
                Debug.LogError("[Localization] Failed to parse " + code + ".json: " + e.Message);
                return null;
            }
            if (data == null || data.entries == null) return null;

            var map = new Dictionary<string, string>(data.entries.Count, StringComparer.Ordinal);
            for (int i = 0; i < data.entries.Count; i++)
            {
                var e = data.entries[i];
                if (e == null || string.IsNullOrEmpty(e.k)) continue;
                map[e.k] = e.v;   // last one wins if a key repeats
            }
            return map;
        }

        private static CultureInfo SafeCulture(string name)
        {
            try { return CultureInfo.GetCultureInfo(name); }
            catch (CultureNotFoundException) { return CultureInfo.InvariantCulture; }
        }
    }
}
