
# Encrypted Google Drive backup
<img src="https://github.com/user-attachments/assets/610c7259-1049-42ec-8e21-8a43335d7fe9" alt="gdrive_laptop" width="400" />

Automatic encryption and backup of laptop directory files to Google Drive
Because Google is known for its respect for privacy and ... I burned my entire Raid.

Using [Rclone](https://rclone.org/drive/) to backup
Using [Dumb fish method](YouReReallyDumb) to encrypt

# Requirements
## Cronie, a crontab friend
```
sudo pacman -S cronie
sudo systemctl start cronie
sudo systemctl enable cronie
```

# Backup automation
## Script creation
We store our automation script in ~/script/
```
mkdir -p ~/scripts && echo -e '#!/bin/bash\nrclone copy ~/Documents/gdrive/ remote:backup' > ~/scripts/backup.sh && chmod +x ~/scripts/backup.sh
```
## Backup of the night
Then we add this script to our cron task to backup every night at 2
```
(crontab -l ; echo "0 2 * * * ~/scripts/backup.sh") | crontab -
```
## Backup on shutdown
We should use systemd to backup on shutdown
Move `backup-before-shutdown.service` under `/etc/systemd/system/`
Edit the service to switch the user, group & directory to your match

Enable and start the service
```
sudo systemctl enable backup-before-shutdown.service
sudo systemctl start backup-before-shutdown.service
```

