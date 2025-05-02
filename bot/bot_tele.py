import os
import time
import logging
import subprocess

from telegram import Update
from telegram.ext import (
    Updater,
    CommandHandler,
    MessageHandler,
    Filters,
    CallbackContext,
    ConversationHandler
)

# Setup Logging
logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                    level=logging.INFO)
logger = logging.getLogger(__name__)

# Step identifiers for conversation
USERNAME, PASSWORD, LIMIT_IP, EXPIRATION, BALANCE, TOPUP = range(6)

# Path to your existing SSH account management scripts and logs
USERNEW_PATH = "/root/usernew.sh"
LOG_DIR = "/etc/klmpk/log-ssh/"
BALANCE_DIR = "/etc/bot/balance/"
TOKEN_FILE = "/etc/bot/management-akun.db"

# Load token from file
def load_token(path):
    if not os.path.exists(path):
        raise FileNotFoundError(f"Token file '{path}' tidak ditemukan.")
    with open(path, "r") as f:
        token = f.read().strip()
    if not token:
        raise ValueError("Token kosong di file token.")
    return token

# Start message
def start(update: Update, context: CallbackContext) -> int:
    update.message.reply_text("Selamat datang! Ketik /saldo untuk cek saldo atau /topup untuk menambah saldo.")
    return ConversationHandler.END

def check_balance(update: Update, context: CallbackContext) -> int:
    username = update.message.from_user.username
    balance_file = os.path.join(BALANCE_DIR, f"{username}.txt")
    if os.path.exists(balance_file):
        with open(balance_file, 'r') as f:
            balance = f.read()
        update.message.reply_text(f"Saldo Anda: {balance} MB")
    else:
        update.message.reply_text("Saldo Anda belum ada. Silakan top-up terlebih dahulu.")
    return ConversationHandler.END

def top_up(update: Update, context: CallbackContext) -> int:
    update.message.reply_text("Masukkan username untuk top-up saldo.")
    return TOPUP

def process_topup(update: Update, context: CallbackContext) -> int:
    username = update.message.text.strip()
    context.user_data['topup_username'] = username
    update.message.reply_text(f"Masukkan jumlah saldo (MB) yang ingin ditambahkan untuk {username}.")
    return BALANCE

def update_balance(update: Update, context: CallbackContext) -> int:
    amount = update.message.text.strip()
    if not amount.isdigit():
        update.message.reply_text("Jumlah saldo harus berupa angka. Coba lagi.")
        return BALANCE
    amount = int(amount)
    username = context.user_data['topup_username']
    balance_file = os.path.join(BALANCE_DIR, f"{username}.txt")
    os.makedirs(BALANCE_DIR, exist_ok=True)
    current_balance = 0
    if os.path.exists(balance_file):
        with open(balance_file, 'r') as f:
            current_balance = int(f.read())
    new_balance = current_balance + amount
    with open(balance_file, 'w') as f:
        f.write(str(new_balance))
    update.message.reply_text(f"Saldo untuk {username} ditambahkan. Sekarang: {new_balance} MB.")
    return ConversationHandler.END

def get_username(update: Update, context: CallbackContext) -> int:
    username = update.message.text.strip()
    context.user_data['username'] = username
    update.message.reply_text(f"Username: {username}\nMasukkan password untuk akun SSH.")
    return PASSWORD

def get_password(update: Update, context: CallbackContext) -> int:
    context.user_data['password'] = update.message.text.strip()
    update.message.reply_text("Masukkan limit IP.")
    return LIMIT_IP

def get_ip_limit(update: Update, context: CallbackContext) -> int:
    ip_limit = update.message.text.strip()
    if not ip_limit.isdigit():
        update.message.reply_text("Limit IP harus angka.")
        return LIMIT_IP
    context.user_data['ip_limit'] = ip_limit
    update.message.reply_text("Masukkan masa aktif akun (hari).")
    return EXPIRATION

def get_expiration(update: Update, context: CallbackContext) -> int:
    expiration = update.message.text.strip()
    if not expiration.isdigit():
        update.message.reply_text("Expired harus angka.")
        return EXPIRATION
    username = context.user_data['username']
    password = context.user_data['password']
    ip_limit = context.user_data['ip_limit']
    create_cmd = f"bash {USERNEW_PATH} {username} {password} {ip_limit} {expiration}"
    try:
        subprocess.run(create_cmd, shell=True, check=True)
        log_file = os.path.join(LOG_DIR, f"{username}.txt")
        if os.path.exists(log_file):
            with open(log_file, 'r') as f:
                update.message.reply_text(f"Akun SSH berhasil dibuat:\n\n{f.read()}")
        else:
            update.message.reply_text("Akun dibuat, tapi log tidak ditemukan.")
    except subprocess.CalledProcessError:
        update.message.reply_text("Gagal menjalankan script.")
    return ConversationHandler.END

def cancel(update: Update, context: CallbackContext) -> int:
    update.message.reply_text("Proses dibatalkan.")
    return ConversationHandler.END

# Main
def main():
    try:
        token = load_token(TOKEN_FILE)
    except Exception as e:
        print(f"Gagal memuat token: {e}")
        return

    updater = Updater(token, use_context=True)
    dispatcher = updater.dispatcher

    conv_handler = ConversationHandler(
        entry_points=[
            CommandHandler('start', start),
            CommandHandler('saldo', check_balance),
            CommandHandler('topup', top_up)
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

    dispatcher.add_handler(conv_handler)

    updater.start_polling()
    updater.idle()

if __name__ == '__main__':
    main()
