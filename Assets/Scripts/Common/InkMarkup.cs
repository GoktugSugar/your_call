using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// Turns the writer's simple emphasis tags into TextMeshPro colour tags, using the one
    /// palette so nothing new is invented. The colour-to-meaning mapping (see docs/art-and-ui.md),
    /// applied the same way every time so it reads as a system: [amber] stresses the stakes and
    /// the emphasis (the counts, the weight of the choice); [red] marks death and the guilty
    /// (killing, the murderer, the wretched, the villain), and also colours a word that names the
    /// red button; [blue] names the blue button. A few meaningful words per line, not everything.
    /// Emphasis is authored per line in the copy, never hardcoded here. Any other bracket is left untouched.
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
