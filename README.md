# Encrypted Google Drive backup
Automatic encryption and backup of laptop directory files to Google Drive
Because Google is known for its respect for privacy and ... I burned my entire Raid.

Using [Rclone](https://rclone.org/drive/) to backup
Using [Dumb fish method](YouReReallyDumb) to encrypt

# Backup automation
We store our automation script in ~/script/
```
mkdir -p ~/scripts && echo -e '#!/bin/bash\nrclone copy ~/Documents/gdrive/ remote:backup' > ~/scripts/backup.sh && chmod +x ~/scripts/backup.sh
```

To be done :
- encryption
- cron task
