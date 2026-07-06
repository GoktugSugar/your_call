using System;
using System.Collections;
using UnityEngine;

namespace YourCall
{
    /// <summary>
    /// Owns the verb-specific scene apparatus (figures, diegetic input, and the animated
    /// consequence) so DilemmaStage can drive any verb generically, with no verb branches.
    /// Concrete presenters: TrolleyConsequence, CrowdConsequence. Decoupled from the loop
    /// through <see cref="Chosen"/>.
    /// </summary>
    public abstract class ConsequencePresenter : MonoBehaviour
    {
        /// <summary>A diegetic choice was made (a lever pulled, a mark clicked): choice index.</summary>
        public event Action<int> Chosen;
        protected void RaiseChosen(int index) => Chosen?.Invoke(index);

        /// <summary>Spawn figures/parties and place apparatus for this dilemma.</summary>
        public abstract void BuildScene(Dilemma dilemma);

        /// <summary>Enable or disable diegetic choice input.</summary>
        public abstract void ArmChoice(bool on);

        /// <summary>Called once a choice is committed (to lock a mark or throw a lever).</summary>
        public virtual void OnCommitted(DilemmaChoice choice, int index) { }

        /// <summary>Play the animated consequence and fold the struck parties. Yields until done.</summary>
        public abstract IEnumerator PlayConsequence(DilemmaChoice choice, DilemmaOutcome outcome);
    }
}
