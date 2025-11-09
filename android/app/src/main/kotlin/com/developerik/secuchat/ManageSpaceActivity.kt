package com.developerik.secuchat

import io.flutter.embedding.android.FlutterActivity

class ManageSpaceActivity : FlutterActivity(){
    // override fun getCachedEngineId(): String? {
    //     return null
    // }
    override fun getInitialRoute(): String {
        return "/manage-storage"
    }
}