from telegram import Update
from telegram.ext import ApplicationBuilder, CommandHandler, ContextTypes
import sqlite3
import os

BOT_DIR = "/etc/bot"
DB_PATH = os.path.join(BOT_DIR, "db", "member.db")

os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

conn = sqlite3.connect(DB_PATH, check_same_thread=False)
cursor = conn.cursor()
cursor.execute('''
CREATE TABLE IF NOT EXISTS members (
    user_id INTEGER PRIMARY KEY,
    username TEXT,
    saldo INTEGER DEFAULT 0
)
''')
conn.commit()

ADMIN_IDS = ["123456789"]  # Ganti dengan Telegram user ID admin

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Selamat datang di Bot Management Akun!")

async def add_member(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if str(update.effective_user.id) not in ADMIN_IDS:
        await update.message.reply_text("Akses ditolak.")
        return

    if len(context.args) != 2:
        await update.message.reply_text("Usage: /add_member <user_id> <username>")
        return

    user_id, username = context.args
    try:
        cursor.execute("INSERT INTO members (user_id, username) VALUES (?, ?)", (user_id, username))
        conn.commit()
        await update.message.reply_text(f"Member {username} berhasil ditambahkan.")
    except sqlite3.IntegrityError:
        await update.message.reply_text("Member sudah terdaftar.")

async def saldo(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    cursor.execute("SELECT saldo FROM members WHERE user_id = ?", (user_id,))
    result = cursor.fetchone()
    if result:
        await update.message.reply_text(f"Saldo kamu: {result[0]} poin")
    else:
        await update.message.reply_text("Kamu belum terdaftar.")

async def topup(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if str(update.effective_user.id) not in ADMIN_IDS:
        await update.message.reply_text("Akses ditolak.")
        return

    if len(context.args) != 2:
        await update.message.reply_text("Usage: /topup <user_id> <jumlah>")
        return

    user_id, jumlah = context.args
    try:
        cursor.execute("UPDATE members SET saldo = saldo + ? WHERE user_id = ?", (int(jumlah), user_id))
        conn.commit()
        await update.message.reply_text(f"Saldo user {user_id} ditambah {jumlah} poin.")
    except Exception as e:
        await update.message.reply_text(f"Gagal: {str(e)}")

app = ApplicationBuilder().token("YOUR_BOT_TOKEN").build()
app.add_handler(CommandHandler("start", start))
app.add_handler(CommandHandler("add_member", add_member))
app.add_handler(CommandHandler("saldo", saldo))
app.add_handler(CommandHandler("topup", topup))

print("Bot Management Akun berjalan...")
app.run_polling()
