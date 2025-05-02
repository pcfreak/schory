import os
import logging
import subprocess
from telegram import Update
from telegram.ext import Updater, CommandHandler, MessageHandler, Filters, CallbackContext, ConversationHandler

# Logging
logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)
logger = logging.getLogger(__name__)

# Step identifier
USERNAME, PASSWORD, LIMIT_IP, EXPIRATION, BALANCE, TOPUP = range(6)

# Path konfigurasi
USERNEW_PATH = "/root/usernew.sh"
LOG_DIR = "/etc/klmpk/log-ssh/"
BALANCE_DIR = "/etc/bot/balance/"
BOT_DB = "/etc/bot/management-akun.db"

# Mulai
def start(update: Update, context: CallbackContext) -> int:
    update.message.reply_text("Selamat datang!\nKetik /saldo untuk cek saldo atau /topup untuk isi saldo.")
    return ConversationHandler.END

def check_balance(update: Update, context: CallbackContext) -> int:
    username = update.message.from_user.username
    balance_file = os.path.join(BALANCE_DIR, f"{username}.txt")
    if os.path.exists(balance_file):
        with open(balance_file, 'r') as f:
            balance = f.read()
        update.message.reply_text(f"Saldo Anda: {balance} MB")
    else:
        update.message.reply_text("Saldo belum tersedia. Silakan top-up.")
    return ConversationHandler.END

def top_up(update: Update, context: CallbackContext) -> int:
    update.message.reply_text("Masukkan username yang ingin di-topup:")
    return TOPUP

def process_topup(update: Update, context: CallbackContext) -> int:
    context.user_data['topup_username'] = update.message.text
    update.message.reply_text("Masukkan jumlah saldo (MB) yang ingin ditambahkan:")
    return BALANCE

def update_balance(update: Update, context: CallbackContext) -> int:
    amount = update.message.text
    if not amount.isdigit():
        update.message.reply_text("Jumlah harus berupa angka.")
        return BALANCE
    amount = int(amount)
    username = context.user_data['topup_username']
    balance_file = os.path.join(BALANCE_DIR, f"{username}.txt")
    if os.path.exists(balance_file):
        with open(balance_file, 'r') as f:
            current_balance = int(f.read())
        new_balance = current_balance + amount
    else:
        new_balance = amount
    with open(balance_file, 'w') as f:
        f.write(str(new_balance))
    update.message.reply_text(f"Saldo untuk {username} sekarang: {new_balance} MB.")
    return ConversationHandler.END

def get_username(update: Update, context: CallbackContext) -> int:
    context.user_data['username'] = update.message.text
    update.message.reply_text("Masukkan password:")
    return PASSWORD

def get_password(update: Update, context: CallbackContext) -> int:
    context.user_data['password'] = update.message.text
    update.message.reply_text("Masukkan limit IP:")
    return LIMIT_IP

def get_ip_limit(update: Update, context: CallbackContext) -> int:
    if not update.message.text.isdigit():
        update.message.reply_text("Limit IP harus berupa angka.")
        return LIMIT_IP
    context.user_data['ip_limit'] = update.message.text
    update.message.reply_text("Masukkan masa aktif akun (hari):")
    return EXPIRATION

def get_expiration(update: Update, context: CallbackContext) -> int:
    if not update.message.text.isdigit():
        update.message.reply_text("Expired harus berupa angka.")
        return EXPIRATION
    username = context.user_data['username']
    password = context.user_data['password']
    ip_limit = context.user_data['ip_limit']
    expiration = update.message.text
    try:
        subprocess.run(f"bash {USERNEW_PATH} {username} {password} {ip_limit} {expiration}", shell=True, check=True)
        log_file = os.path.join(LOG_DIR, f"{username}.txt")
        if os.path.exists(log_file):
            with open(log_file, 'r') as f:
                log_content = f.read()
            update.message.reply_text(f"Akun SSH berhasil dibuat:\n\n{log_content}")
        else:
            update.message.reply_text("Gagal membaca log akun.")
    except subprocess.CalledProcessError as e:
        update.message.reply_text(f"Error: {e}")
    return ConversationHandler.END

def cancel(update: Update, context: CallbackContext) -> int:
    update.message.reply_text("Proses dibatalkan.")
    return ConversationHandler.END

# ===== MAIN =====
def main():
    if not os.path.exists(BOT_DB):
        print("File database bot tidak ditemukan.")
        return

    with open(BOT_DB, 'r') as f:
        parts = f.read().strip().split()
        if len(parts) < 3:
            print("Format database tidak valid.")
            return
        token = parts[1]

    updater = Updater(token, use_context=True)
    dp = updater.dispatcher

    conv_handler = ConversationHandler(
        entry_points=[
            CommandHandler('start', start),
            CommandHandler('saldo', check_balance),
            CommandHandler('topup', top_up),
        ],
        states={
            USERNAME: [MessageHandler(Filters.text & ~Filters.command, get_username)],
            PASSWORD: [MessageHandler(Filters.text & ~Filters.command, get_password)],
            LIMIT_IP: [MessageHandler(Filters.text & ~Filters.command, get_ip_limit)],
            EXPIRATION: [MessageHandler(Filters.text & ~Filters.command, get_expiration)],
            BALANCE: [MessageHandler(Filters.text & ~Filters.command, update_balance)],
            TOPUP: [MessageHandler(Filters.text & ~Filters.command, process_topup)],
        },
        fallbacks=[CommandHandler('cancel', cancel)],
    )

    dp.add_handler(conv_handler)
    updater.start_polling()
    updater.idle()

if __name__ == '__main__':
    main()
