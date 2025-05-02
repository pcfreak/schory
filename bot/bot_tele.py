import os
import time
import logging
from telegram import Update
from telegram.ext import Updater, CommandHandler, MessageHandler, Filters, CallbackContext
from telegram.ext import ConversationHandler
import subprocess

# Setup Logging
logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                    level=logging.INFO)
logger = logging.getLogger(__name__)

# Step identifiers for conversation
USERNAME, PASSWORD, LIMIT_IP, EXPIRATION, BALANCE, TOPUP = range(6)

# Path to your existing SSH account management scripts and logs
USERNEW_PATH = "/root/usernew.sh"
LOG_DIR = "/etc/klmpk/log-ssh/"
BALANCE_DIR = "/etc/bot/balance/"  # Directory to store balances

# Start the conversation
def start(update: Update, context: CallbackContext) -> int:
    update.message.reply_text("Selamat datang! Silakan ketik /saldo untuk cek saldo atau /topup untuk menambah saldo.")
    return ConversationHandler.END

# Cek saldo
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

# Top-up saldo
def top_up(update: Update, context: CallbackContext) -> int:
    update.message.reply_text("Masukkan username untuk top-up saldo.")
    return TOPUP

# Proses top-up saldo
def process_topup(update: Update, context: CallbackContext) -> int:
    username = update.message.text
    context.user_data['topup_username'] = username
    update.message.reply_text(f"Masukkan jumlah saldo (dalam MB) yang ingin ditambahkan untuk {username}.")
    return BALANCE

# Update saldo
def update_balance(update: Update, context: CallbackContext) -> int:
    amount = update.message.text
    if not amount.isdigit():
        update.message.reply_text("Jumlah saldo harus berupa angka. Coba lagi.")
        return BALANCE
    
    amount = int(amount)
    username = context.user_data['topup_username']
    balance_file = os.path.join(BALANCE_DIR, f"{username}.txt")
    
    # Cek apakah saldo sudah ada
    if os.path.exists(balance_file):
        with open(balance_file, 'r') as f:
            current_balance = int(f.read())
        new_balance = current_balance + amount
    else:
        new_balance = amount

    # Update saldo
    with open(balance_file, 'w') as f:
        f.write(str(new_balance))
    
    update.message.reply_text(f"Saldo untuk {username} berhasil di top-up. Saldo sekarang: {new_balance} MB.")
    return ConversationHandler.END

# Get username
def get_username(update: Update, context: CallbackContext) -> int:
    username = update.message.text
    context.user_data['username'] = username
    update.message.reply_text(f"Username yang dipilih: {username}\nSekarang, masukkan password untuk akun SSH.")
    return PASSWORD

# Get password
def get_password(update: Update, context: CallbackContext) -> int:
    password = update.message.text
    context.user_data['password'] = password
    update.message.reply_text(f"Password untuk {context.user_data['username']} telah diterima.\nSekarang, masukkan limit IP.")
    return LIMIT_IP

# Get IP limit
def get_ip_limit(update: Update, context: CallbackContext) -> int:
    ip_limit = update.message.text
    if not ip_limit.isdigit():
        update.message.reply_text("Limit IP harus berupa angka. Coba lagi.")
        return LIMIT_IP

    context.user_data['ip_limit'] = ip_limit
    update.message.reply_text(f"Limit IP: {ip_limit}. Sekarang, masukkan durasi expired (dalam hari).")
    return EXPIRATION

# Get expiration days
def get_expiration(update: Update, context: CallbackContext) -> int:
    expiration = update.message.text
    if not expiration.isdigit():
        update.message.reply_text("Expired harus berupa angka. Coba lagi.")
        return EXPIRATION

    context.user_data['expiration'] = expiration
    # Now create the SSH account using usernew.sh
    username = context.user_data['username']
    password = context.user_data['password']
    ip_limit = context.user_data['ip_limit']
    expiration = context.user_data['expiration']
    
    # Execute the usernew.sh script to create the account
    create_account_command = f"bash {USERNEW_PATH} {username} {password} {ip_limit} {expiration}"
    try:
        # Run the script and wait for completion
        subprocess.run(create_account_command, shell=True, check=True)

        # Send the result log to user
        log_file = os.path.join(LOG_DIR, f"{username}.txt")
        if os.path.exists(log_file):
            with open(log_file, 'r') as f:
                log_content = f.read()
            update.message.reply_text(f"Akun SSH telah dibuat:\n\n{log_content}")
        else:
            update.message.reply_text("Terjadi kesalahan saat membuat akun SSH. Coba lagi.")
    except subprocess.CalledProcessError as e:
        update.message.reply_text(f"Terjadi kesalahan dalam eksekusi script: {e}")
    
    return ConversationHandler.END

# Cancel the process
def cancel(update: Update, context: CallbackContext) -> int:
    update.message.reply_text("Proses telah dibatalkan.")
    return ConversationHandler.END

# Main function to start the bot
def main():
    # Replace 'YOUR_API_KEY' with your actual bot API key
    updater = Updater("YOUR_API_KEY", use_context=True)

    dispatcher = updater.dispatcher

    # ConversationHandler to manage the user input process
    conv_handler = ConversationHandler(
        entry_points=[CommandHandler('start', start), CommandHandler('saldo', check_balance), CommandHandler('topup', top_up)],
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

    # Start polling updates
    updater.start_polling()
    updater.idle()

if __name__ == '__main__':
    main()
