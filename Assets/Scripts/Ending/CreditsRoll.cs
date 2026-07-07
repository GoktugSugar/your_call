using System;
using System.Collections;
using TMPro;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace YourCall
{
    /// <summary>
    /// A simple, reusable placeholder credits roll in the game's style: a full paper background with
    /// the credits scrolling upward, each ROLE highlighted in amber over the name in black ink, in the
    /// Caveat hand. Content is a plain list of role/name pairs (placeholder). It builds its own
    /// background so it can be dropped into any scene, scrolls to the end, then a click or key returns
    /// to the start (reloads the active scene) to replay, as the prototype does. Reusable by any ending.
    /// One job: roll the credits and return to the start.
    /// </summary>
    public sealed class CreditsRoll : MonoBehaviour
    {
        [Serializable]
        public struct Credit { public string role; public string name; }

        [Header("Type (Caveat, consistent with the dialogue)")]
        [SerializeField] private TMP_FontAsset _font;
        [SerializeField] private Color _roleColor = Palette.Amber;
        [SerializeField] private Color _nameColor = Palette.Ink;
        [SerializeField] private Color _titleColor = Palette.Ink;
        [SerializeField] private Color _background = Palette.Paper;
        [SerializeField] private float _titleSize = 4.2f;
        [SerializeField] private float _roleSize = 2.4f;
        [SerializeField] private float _nameSize = 3.2f;

        [Header("Layout")]
        [SerializeField] private string _title = "Your Call";
        [SerializeField] private float _titleGap = 2.4f;
        [SerializeField] private float _roleToName = 0.62f;
        [SerializeField] private float _blockGap = 1.5f;
        [SerializeField] private float _textWidth = 12f;

        [Header("Scroll")]
        [SerializeField] private float _scrollSpeed = 2.4f;
        [SerializeField] private float _startDelay = 0.5f;
        [SerializeField] private float _endHold = 1.0f;
        [Tooltip("Extra travel so the last line scrolls fully off the top before it stops.")]
        [SerializeField] private float _tailMargin = 3f;
        [Tooltip("A click sooner than this is ignored, so a leftover click never skips or replays instantly.")]
        [SerializeField] private float _inputLockout = 0.4f;

        [Header("Content (placeholder)")]
        [SerializeField] private Credit[] _credits = DefaultCredits();

        [Header("Sorting (above everything)")]
        [SerializeField] private int _sortingOrder = 100;

        [SerializeField] private Camera _camera;

        private Transform _column;
        private bool _built;

        private static Credit[] DefaultCredits() => new[]
        {
            new Credit { role = "Design",         name = "Goktug Baytar" },
            new Credit { role = "Writing",        name = "Goktug Baytar" },
            new Credit { role = "Art",            name = "Goktug Baytar" },
            new Credit { role = "Programming",    name = "Goktug Baytar" },
            new Credit { role = "Music",          name = "Goktug Baytar" },
            new Credit { role = "Sound",          name = "Goktug Baytar" },
            new Credit { role = "Special Thanks", name = "Goktug Baytar" },
        };

        /// <summary>Roll the credits, then wait for a click or key and return to the start (reload).</summary>
        public IEnumerator Play()
        {
            if (_camera == null) _camera = Camera.main;
            Build();

            float half = OrthoHalfHeight();
            float camX = _camera != null ? _camera.transform.position.x : 0f;
            float camY = _camera != null ? _camera.transform.position.y : 0f;
            float top = camY + half, bottom = camY - half;

            float columnHeight = LayOut();
            // Start the top line at the bottom edge, scroll up until the whole column clears the top.
            float startY = bottom;
            float travel = (top - bottom) + columnHeight + _tailMargin;
            _column.position = new Vector3(camX, startY, 0f);

            yield return new WaitForSeconds(_startDelay);

            float moved = 0f, t = 0f;
            while (moved < travel)
            {
                t += Time.deltaTime;
                if (t > _inputLockout && PointerInput.AdvancePressed) break;   // skip to the end
                moved += _scrollSpeed * Time.deltaTime;
                _column.position = new Vector3(camX, startY + moved, 0f);
                yield return null;
            }

            yield return new WaitForSeconds(_endHold);

            // Return to the start / replay, as the prototype does.
            float w = 0f;
            while (!(w > _inputLockout && PointerInput.AdvancePressed)) { w += Time.deltaTime; yield return null; }
            SceneManager.LoadScene(gameObject.scene.name);
        }

        private void Build()
        {
            if (_built) return;

            // A full paper page so the credits read clean over whatever was on screen.
            var tex = new Texture2D(2, 2, TextureFormat.RGBA32, false);
            var px = new Color32[4];
            for (int i = 0; i < px.Length; i++) px[i] = new Color32(255, 255, 255, 255);
            tex.SetPixels32(px); tex.Apply();
            var spr = Sprite.Create(tex, new Rect(0, 0, 2, 2), new Vector2(0.5f, 0.5f), 2f);

            var bg = new GameObject("Background");
            bg.transform.SetParent(transform, false);
            bg.transform.localScale = new Vector3(80f, 50f, 1f);
            if (_camera != null) bg.transform.position = new Vector3(_camera.transform.position.x, _camera.transform.position.y, 0f);
            var sr = bg.AddComponent<SpriteRenderer>();
            sr.sprite = spr;
            sr.color = _background;
            sr.sortingOrder = _sortingOrder;

            _column = new GameObject("Column").transform;
            _column.SetParent(transform, false);

            _built = true;
        }

        // Lay the lines out top-down in the column's local space (y = 0 at the top, going negative),
        // centred on x. Returns the column's total height.
        private float LayOut()
        {
            float y = 0f;
            if (!string.IsNullOrEmpty(_title))
            {
                AddLine(_title, _titleSize, _titleColor, y);
                y -= _titleGap;
            }
            for (int i = 0; i < _credits.Length; i++)
            {
                AddLine(_credits[i].role, _roleSize, _roleColor, y);
                y -= _roleToName;
                AddLine(_credits[i].name, _nameSize, _nameColor, y);
                y -= _blockGap;
            }
            return -y;
        }

        private void AddLine(string content, float size, Color color, float localY)
        {
            var t = InkText.Create(_column, "Line", size, color, TextAlignmentOptions.Center, _sortingOrder + 1);
            if (_font != null) t.font = _font;
            t.text = content;
            t.rectTransform.sizeDelta = new Vector2(_textWidth, size);
            t.rectTransform.localPosition = new Vector3(0f, localY, 0f);
        }

        private float OrthoHalfHeight()
        {
            if (_camera != null && _camera.orthographic) return _camera.orthographicSize;
            return 5f;
        }
    }
}
