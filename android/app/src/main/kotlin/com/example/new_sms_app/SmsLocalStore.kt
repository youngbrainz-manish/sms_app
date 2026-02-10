package com.example.new_sms_app

import android.content.Context

object SmsLocalStore {

    fun insert(
        context: Context,
        address: String,
        body: String,
        date: Long
    ) {
        val db = context.openOrCreateDatabase(
            "sms_app.db",
            Context.MODE_PRIVATE,
            null
        )

        db.execSQL("""
            CREATE TABLE IF NOT EXISTS messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                address TEXT,
                body TEXT,
                date INTEGER,
                is_mine INTEGER,
                is_read INTEGER,
                UNIQUE(address, date)
            )
        """)

        val stmt = db.compileStatement("""
            INSERT OR IGNORE INTO messages
            (address, body, date, is_mine, is_read)
            VALUES (?, ?, ?, 0, 0)
        """)

        stmt.bindString(1, address)
        stmt.bindString(2, body)
        stmt.bindLong(3, date)
        stmt.execute()
    }
}
