#!/bin/bash

# MySQL credentials
MYSQL_USER="root"
MYSQL_PASSWORD="YourPassword"
MYSQL_HOST="localhost"
BACKUP_DIR="/opt/Website-DB-Backup"

# Website backup directory
WEB_BACKUP_DIR="/opt/Website-Backup"
SOURCE_BASE="/var/www/html"

# Ensure backup directories exist
mkdir -p "$BACKUP_DIR"
mkdir -p "$WEB_BACKUP_DIR"

# Log actions
log_action() {
  log_entry="$1"
  echo "$(date +%F_%T) - $log_entry" >> mysql_script.log
}

# List all databases (quick list without sizes)
list_databases() {
  echo "Listing all databases:"
  mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -e "SHOW DATABASES;"
  log_action "Listed all databases"
}

# List databases with sizes
list_database_sizes() {
  echo "Fetching and listing all databases with their sizes:"
  mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -e "
    SELECT table_schema AS Database, 
           ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS Size_MB 
    FROM information_schema.TABLES 
    GROUP BY table_schema;"
  log_action "Listed all databases with sizes"
}

# Restore database from backup
restore_database() {
  read -p "Enter the database name to restore: " db_name
  read -p "Enter the path to the backup file (e.g., /path/to/backup.sql): " backup_path
  db_exists=$(mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -e "SHOW DATABASES LIKE '$db_name';")

  if [[ -z $db_exists ]]; then
    mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -e "CREATE DATABASE $db_name;"
  fi

  mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" "$db_name" < "$backup_path"
  log_action "Database $db_name restored from $backup_path"
}

# Restore from the latest backup
restore_latest_backup() {
  read -p "Enter the database name to restore from the latest backup: " db_name
  latest_backup=$(ls -t "$BACKUP_DIR"/${db_name}_*.sql.gz 2>/dev/null | head -n 1)

  if [[ -z "$latest_backup" ]]; then
    echo "No backup files found for $db_name."
    return
  fi

  gunzip < "$latest_backup" | mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" "$db_name"
  log_action "Database $db_name restored from latest backup $latest_backup"
}

# Delete/Drop a database
delete_database() {
  read -p "Enter the database name to delete: " db_name
  mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -e "DROP DATABASE IF EXISTS $db_name;"
  log_action "Database $db_name deleted"
}

# Create a new database
create_database() {
  read -p "Enter the name of the database to create: " db_name
  mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -e "CREATE DATABASE $db_name;"
  log_action "Database $db_name created"
}

# Manage MySQL users
manage_users() {
  echo "User management options:"
  echo "1) Show all current users"
  echo "2) Create a new user"
  echo "3) Delete an existing user"
  echo "4) Grant privileges to a user"
  read -p "Select an option: " user_option

  case $user_option in
    1)
      mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -e "SELECT user, host FROM mysql.user;"
      log_action "Listed all users"
      ;;
    2)
      read -p "Enter new username: " new_user
      read -p "Enter password for new user: " new_password
      mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -e "CREATE USER '$new_user'@'%' IDENTIFIED BY '$new_password';"
      log_action "User $new_user created"
      ;;
    3)
      read -p "Enter username to delete: " del_user
      mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -e "DROP USER '$del_user'@'%';"
      log_action "User $del_user deleted"
      ;;
    4)
      read -p "Enter username to grant privileges to: " grant_user
      read -p "Enter database name to grant access: " grant_db
      mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -e "GRANT ALL PRIVILEGES ON $grant_db.* TO '$grant_user'@'%'; FLUSH PRIVILEGES;"
      log_action "Privileges granted to $grant_user on $grant_db"
      ;;
    *)
      echo "Invalid option."
      ;;
  esac
}

# Schedule database backups using cron
schedule_backup() {
  read -p "Enter the database name to backup: " db_name
  read -p "Enter the frequency (daily/weekly/monthly): " frequency
  backup_command="mysqldump -u'$MYSQL_USER' -p'$MYSQL_PASSWORD' -h '$MYSQL_HOST' '$db_name' | gzip > '$BACKUP_DIR/${db_name}_\$(date +\%d%b%Y-%H-%M-%S).sql.gz'"

  case $frequency in
    daily) cron_schedule="0 2 * * * $backup_command" ;;
    weekly) cron_schedule="0 2 * * 0 $backup_command" ;;
    monthly) cron_schedule="0 2 1 * * $backup_command" ;;
    *) echo "Invalid frequency." && return ;;
  esac

  (crontab -l; echo "$cron_schedule") | crontab -
  log_action "Backup scheduled for $db_name with frequency $frequency"
}

# Dynamically generated backup menu for website directories
backup_web_directory_menu() {
  # List available directories in /var/www/html/
  PROJECTS=($(ls -d "$SOURCE_BASE"/*/ | xargs -n 1 basename)) # Array of directory names
  
  # Display the list of directories with numbering
  echo "Select a directory to back up:"
  echo "0) Backup all directories"
  for i in "${!PROJECTS[@]}"; do
      echo "$((i+1))) ${PROJECTS[$i]}"
  done

  # Prompt user for selection
  read -p "Enter your choice (0 for all, 1-${#PROJECTS[@]} for specific): " choice

  # Function to back up a specific directory
  backup_directory() {
      local DIR_NAME=$1
      local BACKUP_FILE="$WEB_BACKUP_DIR/${DIR_NAME}-$(date +"%d%b%Y-%H-%M-%S")-Backup.tar.gz"
      
      sudo tar --warning=no-file-changed -czvf "$BACKUP_FILE" -C "$SOURCE_BASE" "$DIR_NAME"
      
      if [ $? -eq 0 ]; then
          echo "Backup successful for $DIR_NAME: $BACKUP_FILE"
          log_action "Website backup successful for $DIR_NAME: $BACKUP_FILE"
      else
          echo "Backup failed for $DIR_NAME!"
          log_action "Website backup failed for $DIR_NAME"
      fi
  }

  # Perform the backup based on user choice
  if [[ "$choice" == "0" ]]; then
      # Backup all directories in /var/www/html/
      for DIR_NAME in "${PROJECTS[@]}"; do
          backup_directory "$DIR_NAME"
      done
  elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#PROJECTS[@]} )); then
      # Backup a specific directory
      DIR_NAME="${PROJECTS[$choice-1]}"
      backup_directory "$DIR_NAME"
  else
      echo "Invalid choice. Exiting."
      exit 1
  fi

  # Delete backups older than 7 days
  sudo find "$WEB_BACKUP_DIR" -type f -name "*.tar.gz" -mtime +7 -exec rm {} \;
}

# Backup a single database
backup_database() {
  local DB_NAME=$1
  BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_$(date +%d%b%Y-%H-%M-%S).sql.gz"
  mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD "$DB_NAME" | gzip > "$BACKUP_FILE"
  log_action "Backup successful for $DB_NAME at $BACKUP_FILE"
}

# Main menu
main_menu() {
  echo "Select an option:"
  echo "1) List all databases"
  echo "2) List all databases with sizes"
  echo "3) Restore a database from a backup file"
  echo "4) Restore a database from the latest backup"
  echo "5) Delete / Drop a database"
  echo "6) Create a database"
  echo "7) Manage MySQL users"
  echo "8) Schedule database backups"
  echo "9) Backup databases (new backup menu)"
  echo "10) Backup website directories"
  echo "11) Exit"

  read -p "Enter your choice: " choice

  case $choice in
    1) list_databases ;;
    2) list_database_sizes ;;
    3) restore_database ;;
    4) restore_latest_backup ;;
    5) delete_database ;;
    6) create_database ;;
    7) manage_users ;;
    8) schedule_backup ;;
    9) backup_menu ;;
    10) backup_web_directory_menu ;;
    11) exit 0 ;;
    *) echo "Invalid choice. Please select again." ;;
  esac
}

# Main loop
while true; do
  main_menu
done
