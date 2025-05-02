#!/usr/bin/env python3
import os
import sys
import random
import subprocess
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import (
    ApplicationBuilder, CommandHandler, CallbackQueryHandler,
    MessageHandler, ContextTypes, filters
)

DB_PATH = "/etc/bot/management-akun.db"
SALDO_DIR = "/etc/bot/saldo"
SCRIPT_SSH = "/usr/bin/add_ssh_bot"
HARGA_SSH = 1000

# Ambil token dan admin
def get_token_admin(db_path):
    if not os.path.exists(db_path):
        print("File token tidak ditemukan:", db_path)
        sys.exit(1)
    with open(db_path, "r") as f:
        for line in f:
            if line.startswith("#bot#"):
                parts = line.strip().split()
                if len(parts) >= 3:
                    return parts[1], parts[2]
    print("Format token tidak valid.")
    sys.exit(1)

BOT_TOKEN, ADMIN_ID = get_token_admin(DB_PATH)

# MENU utama
def get_main_menu(is_admin=False):
    buttons = [
        [InlineKeyboardButton("💰 Cek Saldo", callback_data="cek_saldo")],
        [InlineKeyboardButton("➕ Buat SSH (1 Hari)", callback_data="buat_ssh")],
    ]
    if is_admin:
        buttons.append([InlineKeyboardButton("⚙️ Topup Saldo Member", callback_data="topup_saldo")])
    return InlineKeyboardMarkup(buttons)

# START
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    is_admin = str(update.effective_user.id) == ADMIN_ID
    await update.message.reply_text(
        "*Selamat datang di Bot Management Akun!*\nGunakan tombol di bawah.",
        reply_markup=get_main_menu(is_admin),
        parse_mode="Markdown"
    )

# CALLBACK tombol
async def handle_button(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    user_id = str(query.from_user.id)
    is_admin = user_id == ADMIN_ID
    saldo_path = os.path.join(SALDO_DIR, user_id)

    if query.data == "cek_saldo":
        if not os.path.exists(saldo_path):
            await query.edit_message_text("Kamu belum punya saldo.\nSilakan hubungi admin.", reply_markup=get_main_menu(is_admin))
            return
        with open(saldo_path) as f:
            saldo = int(f.read().strip())
        keterangan = f"""
*Saldo Kamu:* Rp{saldo:,}
*Harga SSH 1 Hari:* Rp{HARGA_SSH:,}
"""
        await query.edit_message_text(keterangan.strip(), parse_mode="Markdown", reply_markup=get_main_menu(is_admin))

    elif query.data == "buat_ssh":
        if not os.path.exists(saldo_path):
            await query.edit_message_text("Kamu belum punya saldo. Hubungi admin.", reply_markup=get_main_menu(is_admin))
            return
        with open(saldo_path) as f:
            saldo = int(f.read().strip())
        if saldo < HARGA_SSH:
            await query.edit_message_text(
                f"Saldo tidak cukup!\nHarga SSH 1 Hari: Rp{HARGA_SSH:,}\nSaldo kamu: Rp{saldo:,}",
                reply_markup=get_main_menu(is_admin)
            )
            return
        hari = 1
        username = f"user{random.randint(1000,9999)}"
        try:
            result = subprocess.check_output([SCRIPT_SSH, username, str(hari)], stderr=subprocess.STDOUT, text=True)
            saldo_baru = saldo - HARGA_SSH
            with open(saldo_path, "w") as f:
                f.write(str(saldo_baru))
            await query.edit_message_text(
                f"*Akun SSH berhasil dibuat:*\n\n```{result}```\n\n*Sisa Saldo:* Rp{saldo_baru:,}",
                parse_mode="Markdown", reply_markup=get_main_menu(is_admin)
            )
        except subprocess.CalledProcessError as e:
            await query.edit_message_text(f"Gagal membuat akun:\n```{e.output}```", parse_mode="Markdown")
        except Exception as e:
            await query.edit_message_text(f"Terjadi kesalahan:\n`{e}`", parse_mode="Markdown")

    elif query.data == "topup_saldo":
        if not is_admin:
            await query.edit_message_text("Akses ditolak. Hanya admin.", reply_markup=get_main_menu(False))
            return
        await query.edit_message_text("Kirim format:\n`id saldo`\nContoh: `123456789 5000`", parse_mode="Markdown")
        context.user_data["topup_mode"] = True

# HANDLE teks (topup)
async def handle_text(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = str(update.effective_user.id)
    if user_id != ADMIN_ID or "topup_mode" not in context.user_data:
        return
    try:
        parts = update.message.text.strip().split()
        if len(parts) != 2:
            raise ValueError("Format salah.")
        target_id, jumlah = parts
        jumlah = int(jumlah)
        if jumlah <= 0:
            raise ValueError("Jumlah harus > 0.")
        saldo_file = os.path.join(SALDO_DIR, target_id)
        saldo_awal = int(open(saldo_file).read().strip()) if os.path.exists(saldo_file) else 0
        saldo_akhir = saldo_awal + jumlah
        with open(saldo_file, "w") as f:
            f.write(str(saldo_akhir))
        await update.message.reply_text(
            f"Topup berhasil!\nID: `{target_id}`\nSaldo lama: Rp{saldo_awal:,}\nSaldo baru: Rp{saldo_akhir:,}",
            parse_mode="Markdown"
        )
    except Exception as e:
        await update.message.reply_text(f"Format salah atau error:\n`{e}`", parse_mode="Markdown")
    context.user_data.pop("topup_mode", None)

# HANDLE /addssh manual
async def add_ssh_manual(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = str(update.effective_user.id)
    if len(context.args) != 4:
        await update.message.reply_text("Format salah!\nGunakan: /addssh username password iplimit expired")
        return
    username, password, iplimit, expired = context.args
    if not username.isalnum() or not password.isalnum():
        await update.message.reply_text("Username dan password hanya boleh huruf/angka tanpa spasi.")
        return
    saldo_path = os.path.join(SALDO_DIR, user_id)
    if not os.path.exists(saldo_path):
        await update.message.reply_text("Kamu belum punya saldo. Hubungi admin.")
        return
    with open(saldo_path) as f:
        saldo = int(f.read().strip())
    if saldo < HARGA_SSH:
        await update.message.reply_text(f"Saldo tidak cukup!\nHarga SSH: Rp{HARGA_SSH:,}\nSaldo kamu: Rp{saldo:,}")
        return
    try:
        result = subprocess.check_output(
            [SCRIPT_SSH, username, password, iplimit, expired],
            stderr=subprocess.STDOUT, text=True
        )
        saldo_baru = saldo - HARGA_SSH
        with open(saldo_path, "w") as f:
            f.write(str(saldo_baru))
        await update.message.reply_text(
            f"*Akun SSH berhasil dibuat:*\n\n```{result}```\n\n*Sisa Saldo:* Rp{saldo_baru:,}",
            parse_mode="Markdown"
        )
    except subprocess.CalledProcessError as e:
        await update.message.reply_text(f"Gagal membuat akun:\n```{e.output}```", parse_mode="Markdown")

# Bot init
app = ApplicationBuilder().token(BOT_TOKEN).build()
app.add_handler(CommandHandler("start", start))
app.add_handler(CommandHandler("menu", start))
app.add_handler(CallbackQueryHandler(handle_button))
app.add_handler(CommandHandler("addssh", add_ssh_manual))
app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_text))

print("Bot management-akun berjalan...")
app.run_polling()
