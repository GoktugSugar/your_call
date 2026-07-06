namespace YourCall
{
    /// <summary>The inputs a verb resolver needs to decide an outcome.</summary>
    public sealed class DilemmaContext
    {
        public readonly Dilemma Dilemma;
        public readonly int ChosenIndex;

        public DilemmaContext(Dilemma dilemma, int chosenIndex)
        {
            Dilemma = dilemma;
            ChosenIndex = chosenIndex;
        }

        public DilemmaChoice Chosen => Dilemma.Choices[ChosenIndex];
    }
}
