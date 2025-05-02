#!/usr/bin/env python3
import os
import sys
import random
import subprocess
from telegram import Update
from telegram.ext import (
    ApplicationBuilder, CommandHandler, ContextTypes
)

DB_PATH = "/etc/bot/management-akun.db"
SALDO_DIR = "/etc/bot/saldo"
SCRIPT_SSH = "/usr/bin/usernew.sh"
HARGA_SSH = 1000

# Ambil token dan admin dari file
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

# Perintah /start dan /menu
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "*Selamat datang!*\n\nPerintah yang tersedia:\n"
        "`/saldo` - Cek saldo kamu\n"
        "`/ssh [hari]` - Beli akun SSH (default 1 hari)\n",
        parse_mode="Markdown"
    )

# Perintah /saldo
async def saldo(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = str(update.effective_user.id)
    saldo_path = os.path.join(SALDO_DIR, user_id)

    if not os.path.exists(saldo_path):
        await update.message.reply_text("Kamu belum terdaftar atau belum punya saldo.")
        return

    with open(saldo_path) as f:
        saldo = f.read().strip()

    await update.message.reply_text(f"Saldo kamu saat ini:\n*Rp{saldo}*", parse_mode="Markdown")

# Perintah /ssh [hari]
async def ssh(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = str(update.effective_user.id)
    saldo_path = os.path.join(SALDO_DIR, user_id)

    if not os.path.exists(saldo_path):
        await update.message.reply_text("Kamu belum punya saldo. Hubungi admin untuk topup.")
        return

    try:
        with open(saldo_path) as f:
            saldo = int(f.read().strip())

        if saldo < HARGA_SSH:
            await update.message.reply_text(f"Saldo tidak cukup! Harga: Rp{HARGA_SSH}, Saldo kamu: Rp{saldo}")
            return

        # Ambil argumen hari
        hari = int(context.args[0]) if context.args else 1
        username = f"user{random.randint(1000,9999)}"

        # Eksekusi usernew.sh
        result = subprocess.check_output(
            [SCRIPT_SSH, username, str(hari)],
            stderr=subprocess.STDOUT,
            text=True
        )

        # Kurangi saldo
        saldo_baru = saldo - HARGA_SSH
        with open(saldo_path, "w") as f:
            f.write(str(saldo_baru))

        await update.message.reply_text(
            f"*Akun SSH berhasil dibuat!*\n\n```{result}```\nSisa saldo: *Rp{saldo_baru}*",
            parse_mode="Markdown"
        )

    except subprocess.CalledProcessError as e:
        await update.message.reply_text(f"Gagal membuat akun:\n```{e.output}```", parse_mode="Markdown")
    except Exception as e:
        await update.message.reply_text(f"Terjadi kesalahan:\n`{e}`", parse_mode="Markdown")

# Inisialisasi dan jalankan bot
app = ApplicationBuilder().token(BOT_TOKEN).build()
app.add_handler(CommandHandler("start", start))
app.add_handler(CommandHandler("menu", start))
app.add_handler(CommandHandler("saldo", saldo))
app.add_handler(CommandHandler("ssh", ssh))

print("Bot management-akun berjalan...")
app.run_polling()
