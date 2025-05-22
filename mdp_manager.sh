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

while true; do 
        echo "===Gestionnaire Password===="
        echo "1. Ajouter un mot de passe"
        echo "2. Consulter mode de passe"
	echo "3. Modification d'un/des mot(s) de passe"
        echo "4. Delete mot de passe"
        echo "5. Quitter"
        read -p "choix : " choice

	case "$choice" in
	1)
		echo "=== Ajouter un nouveau mot de passe ==="
            	read -p "Adresse mail / nom utilisateur : " id
           	read -s -p "Mot de passe : " pwd
            	echo
            	gpg -d "$PASSWORD_FILE" > temp.txt 2>/dev/null
            	echo "$id -> $pwd" >> temp.txt
            	gpg --symmetric --cipher-algo AES256 -o "$PASSWORD_FILE" temp.txt
            	rm temp.txt
            	echo "[✅] Mot de passe ajouté."
            	;;

	5)
		 read -p "[❓] Êtes-vous sûr de vouloir quitter ? (o/n) : " confirm
    			if [[ "$confirm" =~ ^[oO]$ ]]; then
       				echo "[👋] Au revoir !"
        			exit 0
    			else
        			echo "[🔄] Retour au menu."
    			fi
   		 ;;
	esac
done

