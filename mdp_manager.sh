#!/bin/bash

FICHIER_ENC="password_manager.txt.enc"

# Fichier temporaire déchiffré (pour pouvoir le modifié/consulter)
TMPFILE=$(mktemp)


force_password() {
    local password=$1
    
    if [ ${#password} -lt 8 ] ; then  # Espace ajouté après le crochet [
        echo "Mot de passe de 8 caractères minimum"
        return 1
    fi
    
    return 0
}



# Vérifie si le fichier est crée
if [ ! -f "$FICHIER_ENC" ]; then
    echo "Aucun fichier chiffré trouvé."
    echo "Création initiale du fichier 'password_manager.txt'."

    echo -n "Crée ton mot de passe maître : "
    read -s MDP1
    
    if ! force_password "$MDP1"; then
    exit 1
    fi
    
    echo
    echo -n "Confirme ton mot de passe : "
    read -s MDP2
    echo

    if [ "$MDP1" != "$MDP2" ]; then
        echo "Mots de passe différents"
        exit 1
    fi
    
    

    nano "$TMPFILE"
    openssl enc -aes-256-cbc -salt -in "$TMPFILE" -out "$FICHIER_ENC" -pass pass:"$MDP1"
    shred -u "$TMPFILE"
    echo "Fichier chiffré créé avec succès : $FICHIER_ENC"
    exit 0
fi

# === UTILISATION NORMALE ===

# Demande le mot de passe maître
echo -n "Mot de passe maître : "
read -s MDP
echo

# Déchiffrer le fichier
openssl enc -d -aes-256-cbc -salt -in "$FICHIER_ENC" -out "$TMPFILE" -pass pass:"$MDP" 2>/dev/null

# Vérifie si le déchiffrement a réussi
if [ $? -ne 0 ]; then
    echo "Mot de passe incorrect"
    rm -f "$TMPFILE"
    exit 1
fi

##################################################################################################################
nano "$TMPFILE"

###################################################################################################################

# rechiffrer le fichier 
openssl enc -aes-256-cbc -salt -in "$TMPFILE" -out "$FICHIER_ENC" -pass pass:"$MDP"
shred -u "$TMPFILE"

echo "Fichier mis à jour et rechiffré avec succès."

