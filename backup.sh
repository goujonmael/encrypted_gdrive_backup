#!/bin/bash

# Répertoires source et destination
SOURCE_DIR=~/Documents/gdrive
ENCRYPTED_DIR=~/Documents/gdrive-encrypted
REMOTE_DIR=remote:backup

# Vérifier la connectivité Internet avant de commencer
if ! ping -c 1 google.com &>/dev/null; then
    echo "Pas de connexion Internet. Annulation du script."
    exit 1
fi

# Fonction pour vérifier la connectivité Internet pendant l'exécution
check_internet() {
    if ! ping -c 1 google.com &>/dev/null; then
        echo "Connexion Internet perdue. Annulation du script."
        exit 1
    fi
}

echo "Début de la sauvegarde..."

# Créer le répertoire de destination s'il n'existe pas
mkdir -p $ENCRYPTED_DIR

# Lister les fichiers sur Google Drive avec leurs tailles et dates de modification
REMOTE_FILES=$(rclone lsl $REMOTE_DIR)

# Chiffrer et copier les fichiers absents ou modifiés
find $SOURCE_DIR -type f | while read FILE; do
    # Vérifier périodiquement la connectivité Internet
    echo "Vérification de la connexion Internet..."
    check_internet

    # Chemin relatif du fichier
    REL_PATH=$(realpath --relative-to=$SOURCE_DIR $FILE)
    # Chemin du fichier chiffré
    ENCRYPTED_FILE=$ENCRYPTED_DIR/$REL_PATH.gpg

    # Créer les répertoires nécessaires dans le répertoire de destination
    mkdir -p $(dirname $ENCRYPTED_FILE)

    # Vérifier si le fichier existe déjà sur Google Drive
    REMOTE_ENTRY=$(echo "$REMOTE_FILES" | grep -m 1 "$REL_PATH.gpg")

    if [ -z "$REMOTE_ENTRY" ]; then
        # Chiffrer et copier le fichier s'il est absent
        gpg --batch --yes --output $ENCRYPTED_FILE --symmetric $FILE
        rclone copy $ENCRYPTED_FILE $REMOTE_DIR/$(dirname $REL_PATH)
    else
        # Extraire la taille et la date de modification du fichier distant
        REMOTE_SIZE=$(echo "$REMOTE_ENTRY" | awk '{print $1}')
        REMOTE_DATE=$(echo "$REMOTE_ENTRY" | awk '{print $2 " " $3}')

        # Obtenir la taille et la date de modification du fichier local
        LOCAL_SIZE=$(stat -c%s "$FILE")
        LOCAL_DATE=$(stat -c%y "$FILE" | cut -d' ' -f1-2)

        # Convertir les dates en timestamps Unix pour comparaison
        REMOTE_TIMESTAMP=$(date -d "$REMOTE_DATE" +%s)
        LOCAL_TIMESTAMP=$(date -d "$LOCAL_DATE" +%s)

        # Comparer les tailles et les dates de modification
        if [ "$LOCAL_SIZE" -ne "$REMOTE_SIZE" ] || [ "$LOCAL_TIMESTAMP" -ne "$REMOTE_TIMESTAMP" ]; then
            # Chiffrer et copier le fichier s'il est modifié
            echo "Remplacement du fichier chiffré: $ENCRYPTED_FILE"
            gpg --batch --yes --output $ENCRYPTED_FILE --symmetric $FILE
            rclone copy $ENCRYPTED_FILE $REMOTE_DIR/$(dirname $REL_PATH)
        fi

        # Si le fichier distant est plus récent
        if [ "$REMOTE_TIMESTAMP" -gt "$LOCAL_TIMESTAMP" ]; then
            # Copier le fichier du serveur vers le local s'il est plus récent
            echo "Remplacement du fichier local: $FILE"
            rclone copy $REMOTE_DIR/$REL_PATH.gpg $ENCRYPTED_FILE
            gpg --batch --yes --output $FILE --decrypt $ENCRYPTED_FILE
        fi
    fi
    echo "Sauvegarde terminée."
done