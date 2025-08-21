package com.example.flutter_sunmi_customer_display

import android.app.Presentation
import android.content.Context
import android.hardware.display.DisplayManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Display
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.URL
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Typeface
import android.view.Gravity
import android.view.View
import java.text.SimpleDateFormat
import java.util.*

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.flutter_customer_display/sunmi_display"
    private var customerDisplayPresentation: CustomerDisplayPresentation? = null
    private var currentStoreId: String = ""
    private var currentStoreName: String = ""
    private var currentStoreLogoUrl: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d("CustomerDisplay", "🔧 configureFlutterEngine called")

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            Log.d("CustomerDisplay", "📢 MethodChannel call → method=${call.method}, args=${call.arguments}")

            when (call.method) {

                "showWelcome" -> {
                    Log.d("CustomerDisplay", "➡ showWelcome invoked")
                    if (showWelcomeOnCustomerDisplay()) {
                        Log.d("CustomerDisplay", "✔ Welcome displayed")
                        result.success("Welcome shown")
                    } else {
                        Log.e("CustomerDisplay", "❌ No secondary display found for Welcome")
                        result.error("NO_DISPLAY", "No secondary display found", null)
                    }
                }

                "showWelcomeWithStore" -> {
                    val storeId = call.argument<String>("storeId") ?: ""
                    val storeName = call.argument<String>("storeName") ?: ""
                    val storeLogoUrl = call.argument<String>("storeLogoUrl")

                    Log.d("CustomerDisplay", "➡ showWelcomeWithStore invoked → storeId=$storeId, storeName=$storeName, logoUrl=$storeLogoUrl")

                    currentStoreId = storeId
                    currentStoreName = storeName
                    currentStoreLogoUrl = storeLogoUrl

                    customerDisplayPresentation?.updateWelcomeWithStore(storeId, storeName, storeLogoUrl)
                    result.success("Welcome updated with store")
                }

                "showCustomerData" -> {
                    val orderId = call.argument<Int>("orderId") ?: 0
                    val items = call.argument<List<Map<String, Any>>>("items") ?: emptyList()
                    val grossTotal = call.argument<Double>("grossTotal") ?: 0.0
                    val discount = call.argument<Double>("discount") ?: 0.0
                    val merchantDiscount = call.argument<Double>("merchantDiscount") ?: 0.0
                    val netTotal = call.argument<Double>("netTotal") ?: 0.0
                    val tax = call.argument<Double>("tax") ?: 0.0
                    val netPayable = call.argument<Double>("netPayable") ?: 0.0

                    Log.d("CustomerDisplay", "➡ showCustomerData invoked → orderId=$orderId, items=${items.size}, grossTotal=$grossTotal, discount=$discount, merchantDiscount=$merchantDiscount, netTotal=$netTotal, tax=$tax, netPayable=$netPayable")

                    val success = showDataOnCustomerDisplay(
                        orderId, currentStoreId, currentStoreName, currentStoreLogoUrl, items,
                        grossTotal, discount, merchantDiscount, netTotal, tax, netPayable
                    )

                    if (success) {
                        Log.d("CustomerDisplay", "✔ Customer data displayed")
                        result.success("Data displayed")
                    } else {
                        Log.e("CustomerDisplay", "❌ No secondary display found for Customer data")
                        result.error("NO_DISPLAY", "No secondary display found", null)
                    }
                }

                "showThankYou" -> {
                    Log.d("CustomerDisplay", "➡ showThankYou invoked")
                    if (showThankYouOnCustomerDisplay()) {
                        Log.d("CustomerDisplay", "✔ Thank You displayed")
                        result.success("Thank You shown")
                    } else {
                        Log.e("CustomerDisplay", "❌ No secondary display found for Thank You")
                        result.error("NO_DISPLAY", "No secondary display found", null)
                    }
                }

                else -> {
                    Log.w("CustomerDisplay", "⚠ Method not implemented: ${call.method}")
                    result.notImplemented()
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        Log.d("CustomerDisplay", "➡ onResume called")
        showWelcomeOnCustomerDisplay()
    }

    private fun showWelcomeOnCustomerDisplay(): Boolean {
        val displayManager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        val displays = displayManager.displays
        Log.d("CustomerDisplay", "Detected displays: ${displays.size}")

        return if (displays.size > 1) {
            val secondaryDisplay = displays[1]
            Log.d("CustomerDisplay", "Secondary display found: ${secondaryDisplay.name}")

            if (customerDisplayPresentation == null || customerDisplayPresentation?.display != secondaryDisplay) {
                customerDisplayPresentation?.dismiss()
                customerDisplayPresentation = CustomerDisplayPresentation(this, secondaryDisplay)
                customerDisplayPresentation?.show()
                Log.d("CustomerDisplay", "✔ CustomerDisplayPresentation shown on secondary display")
            }
            true
        } else {
            showToast("No secondary display found")
            Log.e("CustomerDisplay", "❌ No secondary display available")
            false
        }
    }

    private fun showDataOnCustomerDisplay(
        orderId: Int,
        storeId: String,
        storeName: String,
        storeLogoUrl: String?,
        items: List<Map<String, Any>>,
        grossTotal: Double,
        discount: Double,
        merchantDiscount: Double,
        netTotal: Double,
        tax: Double,
        netPayable: Double
    ): Boolean {
        if (customerDisplayPresentation == null) {
            Log.d("CustomerDisplay", "CustomerDisplayPresentation null, showing Welcome first")
            showWelcomeOnCustomerDisplay()
        }

        customerDisplayPresentation?.updateCustomerData(
            orderId, storeId, storeName, storeLogoUrl, items, grossTotal,
            discount, merchantDiscount, netTotal, tax, netPayable
        )
        Log.d("CustomerDisplay", "✔ CustomerDisplayPresentation updated with order #$orderId")
        return customerDisplayPresentation != null
    }

    private fun showThankYouOnCustomerDisplay(): Boolean {
        val displayManager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        val displays = displayManager.displays
        Log.d("CustomerDisplay", "Detected displays: ${displays.size} for Thank You")

        return if (displays.size > 1) {
            val secondaryDisplay = displays[1]
            Log.d("CustomerDisplay", "Secondary display found: ${secondaryDisplay.name} for Thank You")

            if (customerDisplayPresentation == null || customerDisplayPresentation?.display != secondaryDisplay) {
                customerDisplayPresentation?.dismiss()
                customerDisplayPresentation = CustomerDisplayPresentation(this, secondaryDisplay)
                customerDisplayPresentation?.show()
            }

            customerDisplayPresentation?.showThankYouLayout()
            Log.d("CustomerDisplay", "✔ Thank You layout displayed")

            Handler(Looper.getMainLooper()).postDelayed({
                Log.d("CustomerDisplay", "➡ Reverting back to Welcome after Thank You")
                customerDisplayPresentation?.updateWelcomeWithStore(currentStoreId, currentStoreName, currentStoreLogoUrl)
            }, 5000)

            true
        } else {
            showToast("No secondary display found")
            Log.e("CustomerDisplay", "❌ No secondary display available for Thank You")
            false
        }
    }

    private fun showToast(message: String) {
        runOnUiThread {
            Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
        }
        Log.d("CustomerDisplay", "🍿 Toast: $message")
    }

    override fun onDestroy() {
        Log.d("CustomerDisplay", "➡ onDestroy called, dismissing CustomerDisplayPresentation")
        customerDisplayPresentation?.dismiss()
        super.onDestroy()
    }

    // ---------------------- CustomerDisplayPresentation ----------------------
    class CustomerDisplayPresentation(context: Context, display: Display) : Presentation(context, display) {
        private var firstOrderShown = false

        private lateinit var orderIdView: TextView
        private lateinit var itemsContainer: LinearLayout
        private lateinit var grossView: TextView
        private lateinit var discountView: TextView
        private lateinit var merchantDiscountView: TextView
        private lateinit var netTotalView: TextView
        private lateinit var taxView: TextView
        private lateinit var netPayableView: TextView
        private lateinit var welcomeText: TextView

        private lateinit var storeLogoView: ImageView
        private lateinit var storeInfoText: TextView

        private lateinit var paymentDate: TextView
        private lateinit var paymentTime: TextView
        private val handler = Handler(Looper.getMainLooper())

        private var currentStoreId: String = ""
        private var currentStoreName: String = ""
        private var currentStoreLogoUrl: String? = null

        private val dateTimeUpdater = object : Runnable {
            override fun run() {
                val now = Calendar.getInstance().time
                val dateFormat = SimpleDateFormat("EEEE, dd MMMM yyyy", Locale.getDefault())
                val timeFormat = SimpleDateFormat("hh:mm a", Locale.getDefault())

                if (this@CustomerDisplayPresentation::paymentDate.isInitialized) {
                    paymentDate.text = dateFormat.format(now)
                }
                if (this@CustomerDisplayPresentation::paymentTime.isInitialized) {
                    paymentTime.text = timeFormat.format(now)
                }
                Log.d("CustomerDisplay", "⏰ Current Date: ${dateFormat.format(now)}, Time: ${timeFormat.format(now)}")
                handler.postDelayed(this, 1000)
            }
        }

        override fun onCreate(savedInstanceState: Bundle?) {
            super.onCreate(savedInstanceState)
            Log.d("CustomerDisplay", "➡ CustomerDisplayPresentation onCreate")
            setContentView(R.layout.welcome_layout)
            welcomeText = findViewById(R.id.welcome_text)
        }

        fun updateWelcomeWithStore(storeId: String, storeName: String, storeLogoUrl: String? = null) {
            currentStoreId = storeId
            currentStoreName = storeName
            currentStoreLogoUrl = storeLogoUrl

            Log.d("CustomerDisplay", "➡ Updating Welcome → storeId=$storeId, storeName=$storeName, logoUrl=$storeLogoUrl")

            welcomeText.text = if (storeName.isNotEmpty()) {
                "Welcome to $storeName"
            } else {
                "👋 Welcome to Pinaka"
            }

            val footerText = findViewById<TextView>(R.id.footer_text)
            footerText.visibility = if (storeName.isNotEmpty()) View.VISIBLE else View.GONE

            val logoView = findViewById<ImageView>(R.id.welcome_logo)
            if (!storeLogoUrl.isNullOrEmpty()) {
                Thread {
                    try {
                        val input = URL(storeLogoUrl).openStream()
                        val bitmap = BitmapFactory.decodeStream(input)
                        Handler(Looper.getMainLooper()).post {
                            logoView.setImageBitmap(bitmap)
                            Log.d("CustomerDisplay", "✅ Welcome logo loaded from URL")
                        }
                    } catch (e: Exception) {
                        Handler(Looper.getMainLooper()).post {
                            logoView.setImageResource(R.drawable.pinaka_logo)
                            Log.e("CustomerDisplay", "❌ Failed to load Welcome logo: ${e.message}")
                        }
                    }
                }.start()
            } else {
                logoView.setImageResource(R.drawable.pinaka_logo)
                Log.d("CustomerDisplay", "✅ Using default Welcome logo")
            }
        }

        fun updateCustomerData(
            orderId: Int,
            storeId: String,
            storeName: String,
            storeLogoUrl: String?,
            items: List<Map<String, Any>>,
            grossTotal: Double,
            discount: Double,
            merchantDiscount: Double,
            netTotal: Double,
            tax: Double,
            netPayable: Double
        ) {
            currentStoreId = storeId
            currentStoreName = storeName
            currentStoreLogoUrl = storeLogoUrl

            if (!firstOrderShown) {
                Log.d("CustomerDisplay", "➡ Showing customer_display_layout for first order")
                setContentView(R.layout.customer_display_layout)
                bindOrderViews()
                firstOrderShown = true

                // Start date/time updater
                handler.post(dateTimeUpdater)
            }

            updateStoreInfo(currentStoreId, currentStoreName, currentStoreLogoUrl)

            Log.d("CustomerDisplay", "➡ Updating order #$orderId with ${items.size} items")
            orderIdView.text = "Order #$orderId (${storeId.ifEmpty { "Store" }})"
            itemsContainer.removeAllViews()

            var totalItemCount = 0

            for (item in items) {
                val qty = (item["qty"] as? Number)?.toInt() ?: 0
                totalItemCount += qty
                val cardLayout = LinearLayout(context).apply {
                    orientation = LinearLayout.HORIZONTAL
                    setPadding(16, 16, 16, 16)
                    layoutParams = LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.MATCH_PARENT,
                        LinearLayout.LayoutParams.WRAP_CONTENT
                    ).apply { setMargins(0, 8, 0, 8) }
                    setBackgroundResource(R.drawable.card_bg)
                    elevation = 4f
                }

                // Item image
                val imageView = ImageView(context).apply {
                    layoutParams = LinearLayout.LayoutParams(120, 120).apply { marginEnd = 16 }
                    scaleType = ImageView.ScaleType.CENTER_CROP
                    setBackgroundColor(Color.LTGRAY)
                    clipToOutline = true
                }

                // Item name + qty × price
                val detailsLayout = LinearLayout(context).apply {
                    orientation = LinearLayout.VERTICAL
                    layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                }

                val nameQtyView = TextView(context).apply {
                    textSize = 16f
                    setTextColor(Color.BLACK)
                    typeface = Typeface.DEFAULT_BOLD
                    text = "${item["name"]}  (${qty} × ${item["unitPrice"]})"
                }

                detailsLayout.addView(nameQtyView)

                // Item total price
                val priceView = TextView(context).apply {
                    layoutParams = LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.WRAP_CONTENT,
                        LinearLayout.LayoutParams.MATCH_PARENT
                    )
                    textSize = 16f
                    setTextColor(Color.BLACK)
                    typeface = Typeface.DEFAULT_BOLD
                    gravity = Gravity.END or Gravity.CENTER_VERTICAL
                    text = "$${item["total"]}"
                }

                cardLayout.addView(imageView)
                cardLayout.addView(detailsLayout)
                cardLayout.addView(priceView)

                itemsContainer.addView(cardLayout)
            }


            // Update total items count
            val totalItemsView = findViewById<TextView>(R.id.label_total_items)
            totalItemsView.text = "Total Items : $totalItemCount"

            // Update totals
            grossView.text = "Gross Total: $%.2f".format(grossTotal)
            discountView.text = "Discount: -$%.2f".format(discount)
            merchantDiscountView.text = "Merchant Discount: -$%.2f".format(merchantDiscount)
            netTotalView.text = "Net Total: $%.2f".format(netTotal)
            taxView.text = "Tax: $%.2f".format(tax)
            netPayableView.text = "Net Payable: $%.2f".format(netPayable)

            Log.d("CustomerDisplay", "✔ Order #$orderId totals updated on display, Total Items: $totalItemCount")
        }

        private fun bindOrderViews() {
            orderIdView = findViewById(R.id.customer_order_id)
            itemsContainer = findViewById(R.id.customer_items_container)
            grossView = findViewById(R.id.value_gross_total)
            discountView = findViewById(R.id.value_discount)
            merchantDiscountView = findViewById(R.id.value_merchant_discount)
            netTotalView = findViewById(R.id.value_net_total)
            taxView = findViewById(R.id.value_tax)
            netPayableView = findViewById(R.id.value_net_payable)

            storeLogoView = findViewById(R.id.store_logo)
            storeInfoText = findViewById(R.id.store_info_text)

            paymentDate = findViewById(R.id.payment_date)
            paymentTime = findViewById(R.id.payment_time)

            Log.d("CustomerDisplay", "✔ Customer order views bound")
        }

        private fun updateStoreInfo(storeId: String, storeName: String, storeLogoUrl: String?) {
            storeInfoText.text = storeName
            val now = Calendar.getInstance().time
            val dateFormat = SimpleDateFormat("EEEE, dd MMMM yyyy", Locale.getDefault())
            val timeFormat = SimpleDateFormat("hh:mm a", Locale.getDefault())
            Log.d(
                "CustomerDisplay",
                "➡ Store Info Update → Store: $storeName, LogoUrl: $storeLogoUrl, Date: ${dateFormat.format(now)}, Time: ${timeFormat.format(now)}"
            )

            if (!storeLogoUrl.isNullOrEmpty()) {
                Thread {
                    try {
                        val input = URL(storeLogoUrl).openStream()
                        val bitmap = BitmapFactory.decodeStream(input)
                        Handler(Looper.getMainLooper()).post {
                            storeLogoView.setImageBitmap(bitmap)
                            Log.d("CustomerDisplay", "✅ Loaded store logo from $storeLogoUrl")
                        }
                    } catch (e: Exception) {
                        Handler(Looper.getMainLooper()).post {
                            storeLogoView.setImageResource(R.drawable.pinaka_logo)
                            Log.e("CustomerDisplay", "❌ Failed to load store logo from $storeLogoUrl: ${e.message}")
                        }
                    }
                }.start()
            } else {
                storeLogoView.setImageResource(R.drawable.pinaka_logo)
                Log.d("CustomerDisplay", "✅ Using default store logo")
            }
        }

        fun showThankYouLayout() {
            setContentView(R.layout.thank_you_layout)

            val storeLogoView = findViewById<ImageView>(R.id.thank_you_store_logo)
            val thankYouText = findViewById<TextView>(R.id.thank_you_text)
            val visitAgainText = findViewById<TextView>(R.id.visit_again_text)

            thankYouText.text = "Thank You!"
            visitAgainText.text = "Please Visit Again"

            if (!currentStoreLogoUrl.isNullOrEmpty()) {
                Thread {
                    try {
                        val input = URL(currentStoreLogoUrl).openStream()
                        val bitmap = BitmapFactory.decodeStream(input)
                        Handler(Looper.getMainLooper()).post {
                            storeLogoView.setImageBitmap(bitmap)
                        }
                    } catch (e: Exception) {
                        Handler(Looper.getMainLooper()).post {
                            storeLogoView.setImageResource(R.drawable.pinaka_logo)
                        }
                    }
                }.start()
            } else {
                storeLogoView.setImageResource(R.drawable.pinaka_logo)
            }
        }

        override fun onDetachedFromWindow() {
            super.onDetachedFromWindow()
            handler.removeCallbacks(dateTimeUpdater)
        }
    }
}