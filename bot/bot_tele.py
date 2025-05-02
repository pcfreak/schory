#!/usr/bin/env python3
import os
import sys
from telegram import Update
from telegram.ext import ApplicationBuilder, CommandHandler, ContextTypes

DB_PATH = "/etc/bot/management-akun.db"

def get_token_admin(db_path):
    if not os.path.exists(db_path):
        print("File token tidak ditemukan:", db_path)
        sys.exit(1)

    with open(db_path, "r") as f:
        for line in f:
            if line.startswith("#bot#"):
                parts = line.strip().split()
                if len(parts) >= 3:
                    return parts[1], parts[2]  # BOT_TOKEN, ADMIN_ID

    print("Format token tidak valid di file:", db_path)
    sys.exit(1)

BOT_TOKEN, ADMIN_ID = get_token_admin(DB_PATH)

# Perintah /start
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Halo! Bot management-akun aktif.")

# Inisialisasi dan jalankan bot
app = ApplicationBuilder().token(BOT_TOKEN).build()
app.add_handler(CommandHandler("start", start))

print("Bot management-akun berjalan...")
app.run_polling()
