package com.example.frontend

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

class BlockedAppActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Make it look like an overlay
        window.setFlags(
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
        )

        val blockedApp = intent.getStringExtra("blocked_app_name") ?: "this app"

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(0xF0111418.toInt())
            setPadding(80, 120, 80, 120)
        }

        // Shield icon
        val icon = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_secure)
            layoutParams = LinearLayout.LayoutParams(160, 160).apply {
                gravity = Gravity.CENTER
                bottomMargin = 48
            }
            setColorFilter(0xFF00FF40.toInt())
        }
        layout.addView(icon)

        // Title
        val title = TextView(this).apply {
            text = "ACCESS BLOCKED"
            textSize = 24f
            setTextColor(0xFFFF1744.toInt())
            gravity = Gravity.CENTER
            typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.BOLD)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = 32 }
        }
        layout.addView(title)

        // Message
        val message = TextView(this).apply {
            text = "The Guardian has blocked access to \"$blockedApp\".\n\nThis app has been restricted by Parental Controls. To unlock it, open The Guardian app and remove it from the blocked list."
            textSize = 15f
            setTextColor(0xCCFFFFFF.toInt())
            gravity = Gravity.CENTER
            setLineSpacing(0f, 1.4f)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = 64 }
        }
        layout.addView(message)

        // "Open Guardian" button
        val openBtn = Button(this).apply {
            text = "OPEN THE GUARDIAN"
            textSize = 14f
            setTextColor(0xFF000000.toInt())
            setBackgroundColor(0xFF00FF40.toInt())
            setPadding(60, 32, 60, 32)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = 24 }
            setOnClickListener {
                val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                if (launchIntent != null) {
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    startActivity(launchIntent)
                }
                finish()
            }
        }
        layout.addView(openBtn)

        // "Go Home" button
        val homeBtn = Button(this).apply {
            text = "GO TO HOME SCREEN"
            textSize = 14f
            setTextColor(0xAAFFFFFF.toInt())
            setBackgroundColor(0xFF222633.toInt())
            setPadding(60, 32, 60, 32)
            setOnClickListener {
                val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_HOME)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(homeIntent)
                finish()
            }
        }
        layout.addView(homeBtn)

        setContentView(layout)
    }

    override fun onBackPressed() {
        // Send user to home screen instead of back to the blocked app
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
        finish()
    }
}
