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
    
    private void createGameStyleDialog(Activity activity, String title, String message, final int id, boolean showCancel) {
        // Create a custom dialog with game style
        AlertDialog.Builder builder = new AlertDialog.Builder(activity);
        
        // Create a custom view for the dialog
        LinearLayout dialogLayout = new LinearLayout(activity);
        dialogLayout.setOrientation(LinearLayout.VERTICAL);
        dialogLayout.setPadding(30, 30, 30, 30);
        dialogLayout.setBackgroundColor(Color.parseColor("#80000000")); // Semi-transparent background
        
        // Create title text view if title exists
        if (title != null && !title.isEmpty()) {
            TextView titleView = new TextView(activity);
            titleView.setText(title);
            titleView.setTextColor(Color.WHITE);
            titleView.setTextSize(20);
            titleView.setGravity(Gravity.CENTER);
            titleView.setPadding(0, 0, 0, 20);
            titleView.setTypeface(null, Typeface.BOLD);
            dialogLayout.addView(titleView);
        }
        
        // Create message text view
        TextView messageView = new TextView(activity);
        messageView.setText(message);
        messageView.setTextColor(Color.WHITE);
        messageView.setTextSize(16);
        messageView.setGravity(Gravity.CENTER);
        messageView.setPadding(0, 10, 0, 30);
        dialogLayout.addView(messageView);
        
        // Add divider
        View divider = new View(activity);
        divider.setBackgroundColor(Color.parseColor("#444444"));
        LinearLayout.LayoutParams dividerParams = new LinearLayout.LayoutParams(LayoutParams.MATCH_PARENT, 1);
        dialogLayout.addView(divider, dividerParams);
        
        // Create button(s)
        Button positiveButton = new Button(activity);
        positiveButton.setText(showCancel ? decideLabel : closeLabel);
        positiveButton.setTextColor(Color.parseColor("#3B88C3")); // Clash Royale blue
        positiveButton.setBackgroundColor(Color.TRANSPARENT);
        positiveButton.setTextSize(16);
        positiveButton.setAllCaps(false); // No all caps to match game style
        positiveButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                UnityPlayer.UnitySendMessage("DialogManager", "OnSubmit", String.valueOf(id));
                _dialogs.delete(id);
                _dialogs.get(id).dismiss();
            }
        });
        
        LinearLayout buttonLayout = new LinearLayout(activity);
        buttonLayout.setOrientation(LinearLayout.HORIZONTAL);
        buttonLayout.setGravity(Gravity.CENTER);
        
        if (showCancel) {
            Button negativeButton = new Button(activity);
            negativeButton.setText(cancelLabel);
            negativeButton.setTextColor(Color.parseColor("#3B88C3")); // Clash Royale blue
            negativeButton.setBackgroundColor(Color.TRANSPARENT);
            negativeButton.setTextSize(16);
            negativeButton.setAllCaps(false); // No all caps to match game style
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