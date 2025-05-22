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
    echo "Aucun fichier chiffré trouvé."
    echo "Création initiale du fichier 'password_manager.txt'."
    echo -n

    echo "Souhaitez-vous choisir votre mot de passe ?"
    echo "1. Mot de passe personnalisé"
    echo "2. Générer un mot de passe aléatoire"
    read -p "Entrez 1 ou 2 : " choix
    echo

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
         	echo "Mot de passe validé."
	 elif [[ "$validation" == "No" || "$validation" == "no" ]]; then 
		exit 1
	    fi
    	 
    else
    	 echo "Choix invalide. Veuillez entrer 1 ou 2."
         exit 1
    fi
    	
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


# rechiffrer le fichier 
openssl enc -aes-256-cbc -salt -in "$TMPFILE" -out "$FICHIER_ENC" -pass pass:"$MDP"
shred -u "$TMPFILE"

echo "Fichier mis à jour et rechiffré avec succès."

# === MENU ===
# Affiche le menu principal
while true; do 
        echo
        echo -e "\e[1m=== [🔑] Gestionnaire de mot de passe ===\e[0m"
        echo
        echo "1. [➕] Ajouter un mot de passe"
        echo
        echo "2. [📖] Consulter mot de passe"
        echo
        echo "3. [✏️] Modification d'un/des mot(s) de passe"
        echo
        echo "4. [🗑️] Delete mot de passe"
        echo
        echo "5. [🚪] Quitter"
        echo
        read -p "📋 Entrez votre choix : " choice
        echo

	case "$choice" in
	1)
		echo "\e[1m=== [➕] Ajouter un nouveau mot de passe ===\e[0m"
        read -p "💻 Outil/logiciel/site : " id_logiciel
        read -p "📧 Adresse mail / nom utilisateur : " id
        read -s -p "🔒 Mot de passe : " pwd
        echo

        # Déchiffrer temporairement le fichier pour ajouter le mot de passe ainsi que l'ID
        openssl enc -d -aes-256-cbc -salt -in "$FICHIER_ENC" -out "$TMPFILE" -pass pass:"$MDP" 2>/dev/null
        # Vérifie si le déchiffrement a réussi
        if [ $? -ne 0 ]; then
            echo "[❌] Erreur : Impossible de déchiffrer le fichier. Mot de passe maître incorrect ou fichier corrompu."
            exit 1
        fi

        # Ajouter les nouvelles données au fichier dédié
        echo "$id_logiciel : $id -> $pwd" >> "$TMPFILE"

        # Permet de rechiffrer le fichier après avoir ajouté les données
        openssl enc -aes-256-cbc -salt -in "$TMPFILE" -out "$FICHIER_ENC" -pass pass:"$MDP"

        # Supprimer le fichier temporaire pour des raisons de sécurité
        shred -u "$TMPFILE"
        
        echo "[✅] Mot de passe ajouté."
        ;;
    2)
    echo -e "\e[1m=== [📖] Consulter un mot de passe ===\e[0m"
    echo
        # Déchiffrer temporairement le fichier pour consulter le mot de passe
        openssl enc -d -aes-256-cbc -salt -in "$FICHIER_ENC" -out "$TMPFILE" -pass pass:"$MDP" 2>/dev/null
        # Vérifie si le déchiffrement a réussi
        if [ $? -ne 0 ]; then
            echo "[❌] Erreur : Impossible de déchiffrer le fichier. Mot de passe maître incorrect ou fichier corrompu."
            exit 1
        fi

        # Afficher le contenu du fichier temporaire
        cat "$TMPFILE"

        # Supprimer le fichier temporaire pour des raisons de sécurité
        shred -u "$TMPFILE"
        
        ;;
	5)
            read -p "\e[1m[❓] Êtes-vous sûr de vouloir quitter ? (o/n) :\e[0m" confirm    			
            if [[ "$confirm" =~ ^[oO]$ ]]; then
       				echo "[👋] Au revoir !"
        			exit 0
    			else
        			echo "[🔄] Retour au menu."
    			fi
   		 ;;
	esac
done

