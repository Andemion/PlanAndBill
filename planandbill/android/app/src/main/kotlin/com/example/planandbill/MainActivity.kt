package com.arttherapy.planandbill

import android.app.AlarmManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "exact_alarm_permission"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "isExactAlarmAllowed") {
                val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val isAllowed = alarmManager.canScheduleExactAlarms()
                result.success(isAllowed)
            } else {
                result.notImplemented()
            }
        }
    }
}

