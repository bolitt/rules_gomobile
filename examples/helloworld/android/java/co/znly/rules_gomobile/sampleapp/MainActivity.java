package co.znly.rules_gomobile.sampleapp;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.graphics.Color;
import android.os.Bundle;
import android.support.v4.app.NotificationCompat;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;

import co.znly.helloworld.Helloworld;


public class MainActivity extends AppCompatActivity {
    private static final String TAG = "SampleApp::MainActivity";
    private Button mButton;
    private ViewGroup mLayout;
    private int counter = 0;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_main);

        mLayout = (ViewGroup)findViewById(R.id.layout);
        mButton = (Button)findViewById(R.id.generate_button);

        mButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                String input = String.format("golang[%d]", counter);
                String ret = Helloworld.hello(input);
                counter ++;
                mButton.setText(String.format("Return: %s. Counter: %d", ret, counter));
            }
        });
    }

    @Override
    protected void onResume() {
        Log.d(TAG, "onResume");
        super.onResume();
    }

    @Override
    protected void onPause() {
        Log.d(TAG, "onPause");
        super.onPause();
    }
}
