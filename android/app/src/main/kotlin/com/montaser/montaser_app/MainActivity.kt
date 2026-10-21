package com.montaser.montaser_app

import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * A fragment activity rather than the plain one.
 *
 * The fingerprint prompt on Android is a BiometricPrompt, and a BiometricPrompt
 * is a fragment: it has to be shown by something that can host one. Left as
 * FlutterActivity, asking for a fingerprint throws at the moment it is asked —
 * which is the moment a customer is holding a finger to the sensor.
 */
class MainActivity : FlutterFragmentActivity()
