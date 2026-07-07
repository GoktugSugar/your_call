using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// Turns the writer's simple emphasis tags into TextMeshPro colour tags, using the one
    /// palette so nothing new is invented. The rules (see docs/art-and-ui.md): [amber]word[/amber]
    /// stresses a word in the accent; [red]word[/red] and [blue]word[/blue] colour a word that
    /// names one of the button dilemma's coloured buttons, echoing it. Emphasis is authored per
    /// line in the copy, never hardcoded here. Any other bracket is left untouched.
    /// </summary>
    public static class InkMarkup
    {
        private static string _amber, _red, _blue;

        public static string ToRichText(string authored)
        {
            if (string.IsNullOrEmpty(authored)) return authored;
            if (_amber == null)
            {
                _amber = ColorUtility.ToHtmlStringRGB(Palette.Amber);
                _red = ColorUtility.ToHtmlStringRGB(Palette.InkRed);
                _blue = ColorUtility.ToHtmlStringRGB(Palette.InkBlue);
            }
            string s = authored;
            s = Wrap(s, "amber", _amber);
            s = Wrap(s, "red", _red);
            s = Wrap(s, "blue", _blue);
            return s;
        }

        private static string Wrap(string s, string tag, string hex)
        {
            if (s.IndexOf('[') < 0) return s;
            return s.Replace("[" + tag + "]", "<color=#" + hex + ">")
                    .Replace("[/" + tag + "]", "</color>");
        }
    }
}
