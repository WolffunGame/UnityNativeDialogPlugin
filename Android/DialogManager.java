package unity.plugins.dialog;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.util.Log;
import android.util.SparseArray;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup.LayoutParams;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;

import com.unity3d.player.UnityPlayer;

/**
 * @author koki ibukuro
 * Enhanced version with modern game-styled UI
 */
public class DialogManager {
    private static DialogManager _instance;
    
    private int _id;
    private SparseArray<AlertDialog> _dialogs;
    
    private String decideLabel;
    private String cancelLabel;
    private String closeLabel;
    
    // Color constants
    private static final String BACKGROUND_COLOR = "#2A2A35"; // Dark blue-gray background
    private static final String BUTTON_COLOR = "#3B88C3";     // Bright blue for buttons
    private static final String TITLE_COLOR = "#FFFFFF";      // White for title
    private static final String MESSAGE_COLOR = "#E0E0E0";    // Light gray for message
    private static final String DIVIDER_COLOR = "#444444";    // Dark gray for dividers
    
    /**
     * singleton class 
     */
    private DialogManager() {
        _id = 0;
        _dialogs = new SparseArray<AlertDialog>();
        decideLabel = "Yes";
        cancelLabel = "No";
        closeLabel = "Close";
    }
    
    public static DialogManager getInstance() {
        if(_instance == null) {
            _instance = new DialogManager();
        }
        return _instance;
    }
    
    /**
     * @param msg
     * @return id
     */
    public int showSelectDialog(final String msg) {
        ++_id;
        
        final int id = _id; 
        final Activity a = UnityPlayer.currentActivity;
        a.runOnUiThread(new Runnable() {
            public void run() {
                createGameStyleDialog(a, null, msg, id, true);
            }
        });
        return id;
    }
    
    /**
     * @param title
     * @param msg
     * @return id
     */
    public int showSelectDialog(final String title, final String message) {
        ++_id;
        
        final int id = _id;
        final Activity a = UnityPlayer.currentActivity;
        a.runOnUiThread(new Runnable() {
            public void run() {
                createGameStyleDialog(a, title, message, id, true);
            }
        });
        
        return id;
    }
    
    /**
     * @param msg
     * @return id
     */
    public int showSubmitDialog(final String msg) {
        ++_id;
        
        final int id = _id;
        final Activity a = UnityPlayer.currentActivity;
        a.runOnUiThread(new Runnable() {
            public void run() {
                createGameStyleDialog(a, null, msg, id, false);
            }
        });
        
        return id;
    }
    
    /**
     * @param title
     * @param msg
     * @return id
     */
    public int showSubmitDialog(final String title, final String msg) {
        ++_id;
        
        final int id = _id;
        final Activity a = UnityPlayer.currentActivity;
        a.runOnUiThread(new Runnable() {
            public void run() {
                createGameStyleDialog(a, title, msg, id, false);
            }
        });
        
        return id;
    }
    
    private void createGameStyleDialog(Activity activity, String title, String message, final int id, boolean showCancel) {
        // Create a custom dialog with game style
        AlertDialog.Builder builder = new AlertDialog.Builder(activity);
        
        // Create a custom view for the dialog
        LinearLayout dialogLayout = new LinearLayout(activity);
        dialogLayout.setOrientation(LinearLayout.VERTICAL);
        dialogLayout.setPadding(50, 40, 50, 30);
        
        // Create a background drawable with rounded corners
        GradientDrawable backgroundDrawable = new GradientDrawable();
        backgroundDrawable.setColor(Color.parseColor(BACKGROUND_COLOR));
        backgroundDrawable.setCornerRadius(20);
        dialogLayout.setBackground(backgroundDrawable);
        
        // Create title text view if title exists
        if (title != null && !title.isEmpty()) {
            TextView titleView = new TextView(activity);
            titleView.setText(title);
            titleView.setTextColor(Color.parseColor(TITLE_COLOR));
            titleView.setTextSize(20);
            titleView.setGravity(Gravity.CENTER);
            titleView.setPadding(0, 0, 0, 30);
            titleView.setTypeface(null, Typeface.BOLD);
            dialogLayout.addView(titleView);
        }
        
        // Create message text view
        TextView messageView = new TextView(activity);
        messageView.setText(message);
        messageView.setTextColor(Color.parseColor(MESSAGE_COLOR));
        messageView.setTextSize(16);
        messageView.setGravity(Gravity.CENTER);
        messageView.setPadding(0, 10, 0, 40);
        dialogLayout.addView(messageView);
        
        // Add divider
        View divider = new View(activity);
        divider.setBackgroundColor(Color.parseColor(DIVIDER_COLOR));
        LinearLayout.LayoutParams dividerParams = new LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, 1);
        dividerParams.setMargins(0, 0, 0, 20);
        dialogLayout.addView(divider, dividerParams);
        
        // Create button layout
        LinearLayout buttonLayout = new LinearLayout(activity);
        buttonLayout.setOrientation(LinearLayout.HORIZONTAL);
        buttonLayout.setGravity(Gravity.CENTER);
        
        // Create styled button function
        Button positiveButton = createStyledButton(activity, showCancel ? decideLabel : closeLabel);
        positiveButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                try {
                    AlertDialog dialog = _dialogs.get(id);
                    if (dialog != null) {
                        UnityPlayer.UnitySendMessage("DialogManager", "OnSubmit", String.valueOf(id));
                        _dialogs.delete(id);
                        dialog.dismiss();
                    }
                } catch (Exception e) {
                    Log.e("DialogManager", "Error in onClick: " + e.getMessage());
                }
            }
        });
        
        if (showCancel) {
            Button negativeButton = createStyledButton(activity, cancelLabel);
            negativeButton.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    try {
                        AlertDialog dialog = _dialogs.get(id);
                        if (dialog != null) {
                            UnityPlayer.UnitySendMessage("DialogManager", "OnCancel", String.valueOf(id));
                            _dialogs.delete(id);
                            dialog.dismiss();
                        }
                    } catch (Exception e) {
                        Log.e("DialogManager", "Error in onClick: " + e.getMessage());
                    }
                }
            });
            
            // For two buttons layout
            LinearLayout.LayoutParams buttonParams = new LinearLayout.LayoutParams(0, LayoutParams.WRAP_CONTENT);
            buttonParams.weight = 1;
            buttonParams.setMargins(10, 0, 10, 0);
            
            buttonLayout.addView(negativeButton, buttonParams);
            buttonLayout.addView(positiveButton, buttonParams);
        } else {
            // For single button layout
            LinearLayout.LayoutParams buttonParams = new LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT);
            buttonLayout.addView(positiveButton, buttonParams);
        }
        
        dialogLayout.addView(buttonLayout);
        
        // Create and show the dialog
        AlertDialog dialog = builder.create();
        dialog.setCancelable(false);
        dialog.getWindow().setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
        dialog.setView(dialogLayout);
        dialog.show();
        
        _dialogs.put(Integer.valueOf(id), dialog);
    }
    
    private Button createStyledButton(Activity activity, String text) {
        Button button = new Button(activity);
        button.setText(text);
        button.setTextColor(Color.parseColor(BUTTON_COLOR));
        button.setBackgroundColor(Color.TRANSPARENT);
        button.setTextSize(16);
        button.setAllCaps(false);
        button.setTypeface(null, Typeface.BOLD);
        return button;
    }
    
    public void dissmissDialog(int id) {
        AlertDialog dialog = _dialogs.get(id);
        if(dialog == null) {
            return;
        }
        dialog.dismiss();
        _dialogs.remove(id);
    }
    
    public void setLabel(String decide, String cancel, String close) {
        this.decideLabel = decide;
        this.cancelLabel = cancel;
        this.closeLabel = close;
    }
    
    /* Static methods for Unity */
    public static int ShowSelectDialog(String msg) {
        return DialogManager.getInstance().showSelectDialog(msg);
    }
    
    public static int ShowSelectTitleDialog(String title, String msg) {
        return DialogManager.getInstance().showSelectDialog(title, msg);
    }
    
    public static int ShowSubmitDialog(String msg) {
        return DialogManager.getInstance().showSubmitDialog(msg);
    }
    
    public static int ShowSubmitTitleDialog(String title, String msg) {
        return DialogManager.getInstance().showSubmitDialog(title, msg);
    }
    
    public static void DissmissDialog(int id) {
        DialogManager.getInstance().dissmissDialog(id);
    }
    
    public static void SetLabel(String decide, String cancel, String close) {
        DialogManager.getInstance().setLabel(decide, cancel, close);
    }
}