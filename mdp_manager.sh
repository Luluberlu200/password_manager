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
mot_passe_random() {
    < /dev/urandom tr -dc 'A-Za-z0-9_@#%' | head -c 12
    
    return 0
}

# Vérifie si le fichier est crée
if [ ! -f "$FICHIER_ENC" ]; then
    echo -e "\n[ℹ️] Aucun fichier chiffré trouvé."
    echo -e "[🔐] Création initiale du fichier : \e[1mpassword_manager.txt\e[0m\n" #met en gras le fichier
    
    echo -e "Veuillez choisir une option pour créer votre mot de passe maître :"
    echo -e "  1️⃣  Choisir un mot de passe personnalisé"
    echo -e "  2️⃣  Générer un mot de passe aléatoire\n"
    1
    read -p "[👉] Entrez 1 ou 2 : " choix
    
    if [[ "$choix" == "1" ]]; then
    
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
	    
    elif [[ "$choix" == "2" ]]; then
    	 MDP1=$(mot_passe_random)
    	 echo "Mot de passe généré : $MDP1"
    	 
    	 read -p "Voulez-vous valider ce mot de passe (Yes/No) ? " validation

         if [[ "$validation" == "Yes" || "$validation" == "yes" ]]; then
         	echo "[✅]Mot de passe validé."
	 elif [[ "$validation" == "No" || "$validation" == "no" ]]; then 
		exit 1
	    fi
    	 
    else
    	 echo "Choix invalide. Veuillez entrer 1 ou 2."
         exit 1
    fi
    	
    
    

    #nano "$TMPFILE"
    openssl enc -aes-256-cbc -pbkdf2 -salt -in "$TMPFILE" -out "$FICHIER_ENC" -pass pass:"$MDP1"
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
openssl enc -d -aes-256-cbc -pbkdf2 -salt -in "$FICHIER_ENC" -out "$TMPFILE" -pass pass:"$MDP" 2>/dev/null

# Vérifie si le déchiffrement a réussi
if [ $? -ne 0 ]; then
    echo "[❌]Mot de passe incorrect"
    rm -f "$TMPFILE"
    exit 1
fi



# rechiffrer le fichier 
openssl enc -aes-256-cbc -pbkdf2 -salt -in "$TMPFILE" -out "$FICHIER_ENC" -pass pass:"$MDP"
shred -u "$TMPFILE"

echo "Fichier mis à jour et rechiffré avec succès."

# === MENU ===
# Affiche le menu principal
while true; do 
        echo "===Gestionnaire Password===="
        echo "1. Ajouter un mot de passe"
        echo "2. Consulter mot de passe"
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

        # Déchiffrer temporairement le fichier pour ajouter le mot de passe ainsi que l'ID
        openssl enc -d -aes-256-cbc -pbkdf2 -salt -in "$FICHIER_ENC" -out "$TMPFILE" -pass pass:"$MDP" 2>/dev/null
        # Vérifie si le déchiffrement a réussi
        if [ $? -ne 0 ]; then
            echo "[❌] Erreur : Impossible de déchiffrer le fichier. Mot de passe maître incorrect ou fichier corrompu."
            exit 1
        fi

        # Ajouter les nouvelles données au fichier dédié
        echo "$id -> $pwd" >> "$TMPFILE"

        # Permet de rechiffrer le fichier après avoir ajouté les données
        openssl enc -aes-256-cbc -salt -in "$TMPFILE" -out "$FICHIER_ENC" -pass pass:"$MDP"

        # Supprimer le fichier temporaire pour des raisons de sécurité
        shred -u "$TMPFILE"
        
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

