package unity.plugins.dialog;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.util.SparseArray;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.TextView;
import android.widget.LinearLayout;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.view.ViewGroup.LayoutParams;
import android.util.Log;

import com.unity3d.player.UnityPlayer;

/**
 * @author koki ibukuro
 * Modified to match Clash Royale style
 */
public class DialogManager {
    private static DialogManager _instance;
    
    private int _id;
    private SparseArray<AlertDialog> _dialogs;
    
    private String decideLabel;
    private String cancelLabel;
    private String closeLabel;
    
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
    
    private Button createGameButton(Activity activity, String text, boolean isPositive) {
        // Create button with custom style
        Button button = new Button(activity);
        button.setText(text);
        button.setTextColor(Color.parseColor("#3B88C3")); // Clash Royale blue
        button.setTextSize(18);
        button.setAllCaps(false);
        button.setPadding(20, 15, 20, 15);
        button.setTypeface(null, Typeface.BOLD);
        
        // Create background drawable for button
        GradientDrawable buttonBackground = new GradientDrawable();
        buttonBackground.setCornerRadius(8); // Rounded corners
        
        if (isPositive && text.equals("Try again")) {
            // Special styling for "Try again" button
            button.setTextColor(Color.WHITE);
            buttonBackground.setColor(Color.parseColor("#3B88C3")); // Blue background
        } else {
            // Default transparent background
            buttonBackground.setColor(Color.TRANSPARENT);
        }
        
        button.setBackground(buttonBackground);
        return button;
    }
    
    private void createGameStyleDialog(Activity activity, String title, String message, final int id, boolean showCancel) {
        // Create a custom dialog with game style
        AlertDialog.Builder builder = new AlertDialog.Builder(activity);
        
        // Create a custom view for the dialog
        LinearLayout dialogLayout = new LinearLayout(activity);
        dialogLayout.setOrientation(LinearLayout.VERTICAL);
        dialogLayout.setPadding(30, 30, 30, 20); // Less padding at bottom
        
        // Set rounded corners for dialog background
        GradientDrawable dialogBackground = new GradientDrawable();
        dialogBackground.setCornerRadius(15); // Rounded corners
        dialogBackground.setColor(Color.parseColor("#463C33")); // Dark brown background
        dialogLayout.setBackground(dialogBackground);
        
        // Create title text view if title exists
        if (title != null && !title.isEmpty()) {
            TextView titleView = new TextView(activity);
            titleView.setText(title);
            titleView.setTextColor(Color.WHITE);
            titleView.setTextSize(20);
            titleView.setGravity(Gravity.CENTER);
            titleView.setPadding(0, 0, 0, 10);
            titleView.setTypeface(null, Typeface.BOLD);
            dialogLayout.addView(titleView);
        }
        
        // Create message text view
        TextView messageView = new TextView(activity);
        messageView.setText(message);
        messageView.setTextColor(Color.WHITE);
        messageView.setTextSize(16);
        messageView.setGravity(Gravity.CENTER);
        messageView.setPadding(20, 10, 20, 30);
        dialogLayout.addView(messageView);
        
        // Add divider
        View divider = new View(activity);
        divider.setBackgroundColor(Color.parseColor("#333333"));
        LinearLayout.LayoutParams dividerParams = new LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, 1);
        dialogLayout.addView(divider, dividerParams);
        
        // Create button layout
        LinearLayout buttonLayout = new LinearLayout(activity);
        buttonLayout.setOrientation(LinearLayout.VERTICAL);
        buttonLayout.setGravity(Gravity.CENTER);
        buttonLayout.setPadding(0, 0, 0, 0);
        
        // Special handling for "Try again" button
        boolean isTryAgainDialog = !showCancel && closeLabel.equals("Try again");
        
        // Create Try Again/OK button (positive button)
        Button positiveButton = createGameButton(activity, 
                                                showCancel ? decideLabel : closeLabel, 
                                                true);
        
        // Adding click listener for the button
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
            // For two buttons layout (horizontal)
            buttonLayout.setOrientation(LinearLayout.HORIZONTAL);
            
            Button negativeButton = createGameButton(activity, cancelLabel, false);
            
            negativeButton.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    UnityPlayer.UnitySendMessage("DialogManager", "OnCancel", String.valueOf(id));
                    _dialogs.delete(id);
                    _dialogs.get(id).dismiss();
                }
            });
            
            // For two buttons layout
            LinearLayout.LayoutParams buttonParams = new LinearLayout.LayoutParams(0, LayoutParams.WRAP_CONTENT);
            buttonParams.weight = 1;
            
            buttonLayout.addView(negativeButton, buttonParams);
            buttonLayout.addView(positiveButton, buttonParams);
        } else {
            // For single button layout (like the "Try again" button in the image)
            LinearLayout.LayoutParams buttonParams = new LinearLayout.LayoutParams(
                LayoutParams.MATCH_PARENT, 
                LayoutParams.WRAP_CONTENT
            );
            buttonParams.setMargins(20, 10, 20, 10);
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
    
    private void log(String msg) {
        //Log.d("DialogsManager", msg);
    }
}