# MySQL and Website Backup Automation Script

Welcome to the MySQL and Website Backup Automation Script repository. This script automates various tasks for MySQL database and website directory backups, including dynamic database management, user management, backup scheduling, and web directory backups for a customizable web environment.

## Repository URL

[https://github.com/Lalatenduswain/MySQL-and-Website-Backup-Automation-Script](https://github.com/Lalatenduswain/MySQL-and-Website-Backup-Automation-Script)

Please clone the repository:

```bash
git clone https://github.com/Lalatenduswain/MySQL-and-Website-Backup-Automation-Script
```

## Features

1. **MySQL Database Management**:
   - List databases with and without sizes.
   - Create and delete databases.
   - Restore databases from specified or latest backups.
   - Manage MySQL users, including creating, deleting, and granting privileges.
   
2. **Database Backup Scheduling**:
   - Schedule automated backups for any MySQL database at daily, weekly, or monthly intervals.
   - Store compressed backups and delete older backups beyond a specified time.

3. **Website Directory Backup**:
   - Dynamically fetch and back up directories within `/var/www/html`.
   - Option to back up all directories or specific directories with dynamic menu generation.
   - Automated cleanup of older backups beyond a specified retention period.

## Prerequisites

To ensure the script works as expected, install the following packages and configure permissions:

- **MySQL/MariaDB CLI Tools**: Required for MySQL database management.
- **GNU tar**: Used for creating compressed backups of website directories.
- **cron**: Required for scheduling database backups.
- **sudo Permissions**: Ensure that the script has `sudo` permissions for creating backups in protected directories.

### Installation of Prerequisites

```bash
# Update package list
sudo apt update

# Install MySQL CLI tools
sudo apt install mysql-client -y

# Install tar for directory backup compression
sudo apt install tar -y

# (Optional) Install cron if you want automated backup scheduling
sudo apt install cron -y
```

### MySQL Setup

Ensure that your MySQL user has adequate privileges for creating databases, managing users, and performing backups. You may need to create a new MySQL user with the necessary privileges.

### Directory Permissions

- Make sure the user running this script has write permissions for the backup directories.
- Adjust file paths to suit your environment, or run the script with `sudo` if necessary for creating backups.

## Script Usage

This script provides an interactive menu for managing MySQL databases and website backups.

### Running the Script

To execute the script:

```bash
bash mysql_website_backup_script.sh
```

Upon running, the script presents a menu with the following options:

1. **List all databases**: Quickly lists all MySQL databases.
2. **List all databases with sizes**: Displays all MySQL databases with their sizes.
3. **Restore a database from a backup file**: Allows restoration from a specified backup file.
4. **Restore a database from the latest backup**: Restores a database using the latest backup file.
5. **Delete / Drop a database**: Deletes a specified MySQL database.
6. **Create a database**: Creates a new MySQL database.
7. **Manage MySQL users**:
   - Show all current users.
   - Create a new user.
   - Delete an existing user.
   - Grant privileges to a user on a specified database.
8. **Schedule database backups**: Allows scheduling automated database backups at various intervals.
9. **Backup databases**: Choose a specific database or all databases to back up, with options to exclude system databases.
10. **Backup website directories**:
    - Allows backing up all directories or specific directories within `/var/www/html`.
    - Automates the cleanup of old backups after 7 days.
11. **Exit**: Exits the script.

### Example

1. To schedule a backup of a MySQL database, choose **Option 8** and follow the prompts.
2. To back up website directories, choose **Option 10**, then select the directory you wish to back up or choose to back up all.

## Script Structure

The script consists of various functions dedicated to each operation. Here are the key functions:

- **MySQL Operations**: `list_databases`, `list_database_sizes`, `create_database`, `delete_database`, `restore_database`, `restore_latest_backup`, `manage_users`
- **Backup Operations**:
  - **Database Backup**: `backup_menu`, `backup_database`, `schedule_backup`
  - **Website Directory Backup**: `backup_web_directory_menu`, `backup_directory`

The directory backup function fetches available directories dynamically and presents a menu for user selection. It also performs scheduled deletion of older backups.

## Disclaimer | Running the Script

**Author:** Lalatendu Swain | [GitHub](https://github.com/Lalatenduswain)

This script is provided as-is and may require modifications or updates based on your specific environment and requirements. Use it at your own risk. The authors of the script are not liable for any damages or issues caused by its usage.

## Donations

If you find this script useful and want to show your appreciation, you can donate via [Buy Me a Coffee](https://www.buymeacoffee.com/lalatendu.swain).

## Support or Contact

Encountering issues? Don’t hesitate to submit an issue on our [GitHub page](https://github.com/Lalatenduswain/MySQL-and-Website-Backup-Automation-Script/issues).
