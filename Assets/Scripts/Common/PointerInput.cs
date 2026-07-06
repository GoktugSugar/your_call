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
#if ENABLE_INPUT_SYSTEM
                if (Mouse.current != null) return Mouse.current.leftButton.wasPressedThisFrame;
#endif
                return false;
            }
        }

        /// <summary>Any mouse click or key press this frame. Used to advance / replay.</summary>
        public static bool AdvancePressed
        {
            get
            {
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
