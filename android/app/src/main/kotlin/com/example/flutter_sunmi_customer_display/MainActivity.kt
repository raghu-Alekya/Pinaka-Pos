package com.example.flutter_sunmi_customer_display

import android.app.Presentation
import android.content.Context
import android.hardware.display.DisplayManager
import android.os.Bundle
import android.util.Log
import android.view.Display
import android.view.LayoutInflater
import android.widget.TextView
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.flutter_customer_display/sunmi_display"
    private var customerDisplayPresentation: CustomerDisplayPresentation? = null
    private val TAG = "CustomerDisplay"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "showCustomerData") {
                val customerData = call.argument<String>("data")
                if (customerData != null) {
                    val success = showDataOnCustomerDisplay(customerData)
                    if (success) {
                        result.success("Data displayed on customer screen")
                    } else {
                        result.error("NO_DISPLAY", "No secondary display found", null)
                    }
                } else {
                    showToast("Customer data cannot be null")
                    result.error("INVALID_ARGUMENT", "Customer data cannot be null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun showDataOnCustomerDisplay(data: String): Boolean {
        val displayManager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        val displays = displayManager.getDisplays()

        Log.d(TAG, "Number of displays detected: ${displays.size}")
        return if (displays.size > 1) {
            val customerDisplay = displays[1]
            Log.d(TAG, "Using secondary display: ${customerDisplay.name}")
            if (customerDisplayPresentation == null || customerDisplayPresentation?.display != customerDisplay) {
                customerDisplayPresentation?.dismiss()
                customerDisplayPresentation = CustomerDisplayPresentation(this, customerDisplay)
                customerDisplayPresentation?.show()
            }
            customerDisplayPresentation?.updateCustomerData(data)
            showToast("Data displayed on customer screen")
            true
        } else {
            Log.e(TAG, "No secondary display found.")
            showToast("No secondary display found")
            false
        }
    }

    private fun showToast(message: String) {
        runOnUiThread {
            Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
        }
    }

    override fun onDestroy() {
        customerDisplayPresentation?.dismiss()
        super.onDestroy()
    }

    class CustomerDisplayPresentation(context: Context, display: Display) : Presentation(context, display) {
        private lateinit var customerTextView: TextView

        override fun onCreate(savedInstanceState: Bundle?) {
            super.onCreate(savedInstanceState)
            setContentView(LayoutInflater.from(context).inflate(R.layout.customer_display_layout, null))
            customerTextView = findViewById(R.id.customer_data_text_view)
        }

        fun updateCustomerData(data: String) {
            customerTextView.text = data
        }
    }
}