using System;
using System.Collections.Generic;
using UnityEngine;

namespace NativeDialog
{
    /// <summary>
    /// Popup Native Dialog
    /// </summary>
    public sealed class DialogManager : MonoBehaviour, IDialogReceiver
    {

        #region Singleton
        private static DialogManager instance;
        public static DialogManager Instance
        {
            get
            {
                if (instance == null)
                {
                    // Find if there is already DialogManager in the scene
                    instance = FindObjectOfType<DialogManager>();
                    if (instance == null)
                    {
                        instance = new GameObject("DialogManager").AddComponent<DialogManager>();
                    }
                    DontDestroyOnLoad(instance.gameObject);
                }
                return instance;
            }
        }
        #endregion

        #region Members
        private Dictionary<int, Action<bool>> callbacks;
        private IDialog dialog;
        #endregion

        #region Lyfecycles
        private void Awake()
        {
            if (instance == null)
            {
                // If I am the first instance, make me the Singleton
                instance = this;
                DontDestroyOnLoad(this);

                callbacks = new Dictionary<int, Action<bool>>();
                dialog = CreateDialog();

                // Set default label - updated to match game style
                SetLabel("OK", "CANCEL", "Try again");
            }
            else
            {
                // If a singleton already exists and you find
                // another reference in scene, destroy it!
                if (this != instance)
                {
                    Destroy(gameObject);
                }
            }
        }

        private IDialog CreateDialog()
        {
#if UNITY_EDITOR
            var mock = gameObject.AddComponent<DialogMock>();
            mock.Initialize(this, true);
            return mock;
#elif UNITY_ANDROID
            return new DialogAndroid();
#elif UNITY_IOS
            return new DialogIOS();
#else
            Debug.LogWarning($"{Application.platform} is not supported.");
            var mock = gameObject.AddComponent<DialogMock>();
            mock.Initialize(this, true);
            return mock;
#endif
        }

        private void OnDestroy()
        {
            if (callbacks != null)
            {
                callbacks.Clear();
                callbacks = null;
            }

            dialog.Dispose();
        }
        #endregion

        #region Public Methods
        /// <summary>
        /// Set the label text for dialog buttons
        /// </summary>
        /// <param name="decide">Text for Yes/OK button</param>
        /// <param name="cancel">Text for No/Cancel button</param>
        /// <param name="close">Text for Close/Done button</param>
        public static void SetLabel(string decide, string cancel, string close)
        {
            Instance.dialog.SetLabel(decide, cancel, close);
        }

        /// <summary>
        /// Show a dialog with Yes/No options
        /// </summary>
        /// <param name="message">Dialog message</param>
        /// <param name="callback">Callback action (true = Yes, false = No)</param>
        /// <returns>Dialog ID</returns>
        public static int ShowSelect(string message, Action<bool> callback)
        {
            int id = Instance.dialog.ShowSelect(message);
            Instance.callbacks.Add(id, callback);
            return id;
        }

        /// <summary>
        /// Show a dialog with Yes/No options and title
        /// </summary>
        /// <param name="title">Dialog title</param>
        /// <param name="message">Dialog message</param>
        /// <param name="callback">Callback action (true = Yes, false = No)</param>
        /// <returns>Dialog ID</returns>
        public static int ShowSelect(string title, string message, Action<bool> callback)
        {
            int id = Instance.dialog.ShowSelect(title, message);
            Instance.callbacks.Add(id, callback);
            return id;
        }

        /// <summary>
        /// Show a dialog with a single Close button
        /// </summary>
        /// <param name="message">Dialog message</param>
        /// <param name="callback">Callback action (always true)</param>
        /// <returns>Dialog ID</returns>
        public static int ShowSubmit(string message, Action<bool> callback)
        {
            int id = Instance.dialog.ShowSubmit(message);
            Instance.callbacks.Add(id, callback);
            return id;
        }

        /// <summary>
        /// Show a dialog with a single Close button and title
        /// </summary>
        /// <param name="title">Dialog title</param>
        /// <param name="message">Dialog message</param>
        /// <param name="callback">Callback action (always true)</param>
        /// <returns>Dialog ID</returns>
        public static int ShowSubmit(string title, string message, Action<bool> callback)
        {
            int id = Instance.dialog.ShowSubmit(title, message);
            Instance.callbacks.Add(id, callback);
            return id;
        }

        /// <summary>
        /// Show a connection error dialog with the Clash Royale style
        /// </summary>
        /// <param name="callback">Callback action when Try Again is pressed</param>
        /// <returns>Dialog ID</returns>
        public static int ShowConnectionError(Action<bool> callback)
        {
            // Set the label to "Try again" to get special styling
            SetLabel("OK", "CANCEL", "Try again");
            
            // Show the connection error dialog with standard message
            return ShowSubmit(
                "Connection error",
                "Unable to connect with the server.\nCheck your internet connection and try again.",
                callback
            );
        }

        /// <summary>
        /// Dismiss a dialog by ID
        /// </summary>
        /// <param name="id">Dialog ID to dismiss</param>
        public static void Dissmiss(int id)
        {
            Instance.dialog.Dissmiss(id);

            var callbacks = Instance.callbacks;
            if (callbacks.ContainsKey(id))
            {
                Instance.callbacks[id](false);
                callbacks.Remove(id);
            }
            else
            {
                Debug.LogWarning("undefined id:" + id);
            }
        }
        #endregion

        #region Invoked from Native Plugin
        public void OnSubmit(string idStr)
        {
            int id = int.Parse(idStr);
            if (callbacks.ContainsKey(id))
            {
                callbacks[id](true);
                callbacks.Remove(id);
            }
            else
            {
                Debug.LogWarning("Undefined id:" + idStr);
            }
        }

        public void OnCancel(string idStr)
        {
            int id = int.Parse(idStr);
            if (callbacks.ContainsKey(id))
            {
                callbacks[id](false);
                callbacks.Remove(id);
            }
            else
            {
                Debug.LogWarning("Undefined id:" + idStr);
            }
        }
        #endregion
    }

    /// <summary>
    /// Extension methods for DialogManager to provide convenience methods
    /// </summary>
    public static class DialogManagerExtensions
    {
        /// <summary>
        /// Show a connection error dialog with retry callback
        /// </summary>
        /// <param name="dialogManager">DialogManager instance</param>
        /// <param name="onTryAgain">Action to execute when Try again is pressed</param>
        /// <returns>Dialog ID</returns>
        public static int ShowConnectionError(this DialogManager dialogManager, Action onTryAgain)
        {
            // Set the "Try again" label to ensure proper styling
            DialogManager.SetLabel("OK", "CANCEL", "Try again");
            
            // Convert the simple Action to match DialogManager's callback
            Action<bool> callback = (result) => {
                if (result && onTryAgain != null)
                {
                    onTryAgain();
                }
            };
            
            // Show the connection error dialog
            return DialogManager.ShowSubmit(
                "Connection error",
                "Unable to connect with the server.\nCheck your internet connection and try again.",
                callback
            );
        }
    }
}