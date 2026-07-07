namespace YourCall
{
    /// <summary>
    /// The imp's face, as a small set of eyes-and-mouth configurations drawn in its own ink line.
    /// Used only when <see cref="ImpFigure"/> has expressions switched on; with the toggle off the
    /// imp keeps its single default face and this is ignored. A bark can carry one so a smug line
    /// shows a smug face, otherwise the neutral grin. Kept deliberately small and on-model.
    /// </summary>
    public enum ImpExpression
    {
        Grin,       // the default: slanted eyes, a wide little grin (matches the imp's original face)
        WideGrin,   // a bigger, delighted grin
        Smug,       // half-lidded eyes and a one-sided smirk
        Glare,      // sharp down-angled eyes and a small frown
        Surprised   // round eyes and a small open mouth
    }
}
