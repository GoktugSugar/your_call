using UnityEngine;
#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif

namespace YourCall
{
    /// <summary>
    /// One input path for the whole prototype, on the new Input System. Diegetic
    /// picking is done by callers via Physics2D against <see cref="WorldPosition"/>,
    /// so no EventSystem or input module is required.
    /// </summary>
    public static class PointerInput
    {
        /// <summary>When true, every action read below (clicks, holds, advance) reports nothing, so the whole
        /// game's diegetic input is frozen in one place. The pause overlay raises this while it is open (and
        /// reads the input devices directly itself), so no beat can advance underneath the paused screen.
        /// Pointer POSITION is deliberately still reported; only the button/key ACTIONS are gated.</summary>
        public static bool Suppressed;

        public static Vector2 ScreenPosition
        {
            get
            {
#if ENABLE_INPUT_SYSTEM
                if (Mouse.current != null) return Mouse.current.position.ReadValue();
#endif
                return Vector2.zero;
            }
        }

        public static bool Clicked
        {
            get
            {
                if (Suppressed) return false;
#if ENABLE_INPUT_SYSTEM
                if (Mouse.current != null) return Mouse.current.leftButton.wasPressedThisFrame;
#endif
                return false;
            }
        }

        /// <summary>The primary button held down this frame. Used for dragging (e.g. a settings slider).</summary>
        public static bool Held
        {
            get
            {
                if (Suppressed) return false;
#if ENABLE_INPUT_SYSTEM
                if (Mouse.current != null) return Mouse.current.leftButton.isPressed;
#endif
                return false;
            }
        }

        /// <summary>The primary button released this frame. Used to end a drag.</summary>
        public static bool Released
        {
            get
            {
                if (Suppressed) return false;
#if ENABLE_INPUT_SYSTEM
                if (Mouse.current != null) return Mouse.current.leftButton.wasReleasedThisFrame;
#endif
                return false;
            }
        }

        /// <summary>Any mouse click or key press this frame. Used to advance / replay.</summary>
        public static bool AdvancePressed
        {
            get
            {
                if (Suppressed) return false;
#if ENABLE_INPUT_SYSTEM
                if (Mouse.current != null && Mouse.current.leftButton.wasPressedThisFrame) return true;
                if (Keyboard.current != null && Keyboard.current.anyKey.wasPressedThisFrame) return true;
#endif
                return false;
            }
        }

        public static Vector3 WorldPosition(Camera cam, float worldZ = 0f)
        {
            if (cam == null) return Vector3.zero;
            Vector2 s = ScreenPosition;
            float dist = Mathf.Abs(cam.transform.position.z - worldZ);
            return cam.ScreenToWorldPoint(new Vector3(s.x, s.y, dist));
        }
    }
}
