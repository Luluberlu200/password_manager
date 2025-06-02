#!/bin/bash

FICHIER_ENC="password_manager.txt.enc"

# Fichier temporaire déchiffré (pour pouvoir le modifier/consulter)
TMPFILE=$(mktemp)

# Vérifie si le mot de passe respecte les critères (minimum 8 caractères)
force_password() {
    local password=$1
    
    if [ ${#password} -lt 8 ]; then
        echo "Mot de passe de 8 caractères minimum"
        return 1
    fi
    
    return 0
}

# Génère un mot de passe aléatoire de 12 caractères
mot_passe_random() {
    < /dev/urandom tr -dc 'A-Za-z0-9_@#%' | head -c 12
    return 0
}

# Vérifie si le fichier chiffré existe
if [ ! -f "$FICHIER_ENC" ]; then
    echo "Aucun fichier chiffré trouvé."
    echo "Création initiale du fichier 'password_manager.txt'."
    echo -n

    # Demande à l'utilisateur de choisir un mot de passe maître
    echo "Souhaitez-vous choisir votre mot de passe ?"
    echo "1. Mot de passe personnalisé"
    echo "2. Générer un mot de passe aléatoire"
    read -p "Entrez 1 ou 2 : " choix
    echo

    if [[ "$choix" == "1" ]]; then
        # Mot de passe personnalisé
        echo -n "Crée ton mot de passe maître : "
        read -s MDP1
        
        # Vérifie si le mot de passe respecte les critères
        if ! force_password "$MDP1"; then
            exit 1
        fi
        
        echo
        echo -n "Confirme ton mot de passe : "
        read -s MDP2
        echo

        # Vérifie si les deux mots de passe correspondent
        if [ "$MDP1" != "$MDP2" ]; then
            echo "Mots de passe différents"
            exit 1
        fi
        
    elif [[ "$choix" == "2" ]]; then
        # Génère un mot de passe aléatoire
        MDP1=$(mot_passe_random)
        echo "Mot de passe généré : $MDP1"
        
        # Demande confirmation pour valider le mot de passe généré
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
    
    # Crée le fichier chiffré avec le mot de passe maître
    openssl enc -aes-256-cbc -pbkdf2 -salt -in "$TMPFILE" -out "$FICHIER_ENC" -pass pass:"$MDP1"
    shred -u "$TMPFILE"  # Supprime le fichier temporaire de manière sécurisée
    echo "Fichier chiffré créé avec succès : $FICHIER_ENC"
    exit 0
fi

# === UTILISATION NORMALE ===

# Demande le mot de passe maître pour déchiffrer le fichier
echo -n "Mot de passe maître : "
read -s MDP
echo

# Déchiffre le fichier chiffré dans un fichier temporaire
openssl enc -d -aes-256-cbc -pbkdf2 -salt -in "$FICHIER_ENC" -out "$TMPFILE" -pass pass:"$MDP" 2>/dev/null

# Vérifie si le déchiffrement a réussi
if [ $? -ne 0 ]; then
    echo "Mot de passe incorrect"
    rm -f "$TMPFILE"
    exit 1
fi

# Rechiffre immédiatement le fichier pour éviter les modifications non autorisées
openssl enc -aes-256-cbc -pbkdf2 -salt -in "$TMPFILE" -out "$FICHIER_ENC" -pass pass:"$MDP"
shred -u "$TMPFILE"  # Supprime le fichier temporaire de manière sécurisée

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
    echo

    case "$choice" in
    1)
        # Ajouter un nouveau mot de passe
        echo -e "\e[1m=== [➕] Ajouter un nouveau mot de passe ===\e[0m"        
        read -p "💻 Outil/logiciel/site : " id_logiciel
        read -p "📧 Adresse mail / nom utilisateur : " id
        read -s -p "🔒 Mot de passe : " pwd
        echo

        # Déchiffrer temporairement le fichier pour ajouter le mot de passe
        openssl enc -d -aes-256-cbc -pbkdf2 -salt -in "$FICHIER_ENC" -out "$TMPFILE" -pass pass:"$MDP" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "[❌] Erreur : Impossible de déchiffrer le fichier. Mot de passe maître incorrect ou fichier corrompu."
            exit 1
        fi

        # Ajouter les nouvelles données au fichier temporaire
        echo "$id_logiciel : $id -> $pwd" >> "$TMPFILE"

        # Rechiffrer le fichier après modification
        openssl enc -aes-256-cbc -pbkdf2 -salt -in "$TMPFILE" -out "$FICHIER_ENC" -pass pass:"$MDP"

        # Supprimer le fichier temporaire pour des raisons de sécurité
        shred -u "$TMPFILE"
        
        echo
        echo "[✅] Mot de passe ajouté."
        ;;
    2)
        # Consulter les mots de passe
        echo -e "\e[1m=== [📖] Consulter un mot de passe ===\e[0m"
        echo
        openssl enc -d -aes-256-cbc -pbkdf2 -salt -in "$FICHIER_ENC" -out "$TMPFILE" -pass pass:"$MDP" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "[❌] Erreur : Impossible de déchiffrer le fichier. Mot de passe maître incorrect ou fichier corrompu."
            exit 1
        fi

        if [ -s "$TMPFILE" ]; then
            cat "$TMPFILE"  # Affiche le contenu du fichier temporaire
        else
            echo "[ℹ️] Aucun mot de passe enregistré."
        fi

        openssl enc -aes-256-cbc -pbkdf2 -salt -in "$TMPFILE" -out "$FICHIER_ENC" -pass pass:"$MDP"

        # Supprimer le fichier temporaire pour des raisons de sécurité
        shred -u "$TMPFILE"

        
        ;;
    3)
        echo -e "\e[1m=== [✏️] Modifier un mot de passe ===\e[0m"
        echo
        # Déchiffrer temporairement le fichier pour modification
        openssl enc -d -aes-256-cbc -pbkdf2 -salt -in "$FICHIER_ENC" -out "$TMPFILE" -pass pass:"$MDP" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "[❌] Erreur : Impossible de déchiffrer le fichier. Mot de passe maître incorrect ou fichier corrompu."
            exit 1
        fi

        # Afficher les entrées existantes
        echo "=== [📖] Liste des mots de passe ==="
        cat -n "$TMPFILE"
        echo

        # Demander à l'utilisateur quelle ligne modifier
        read -p "Entrez le numéro de la ligne à modifier : " line_number
        if ! [[ "$line_number" =~ ^[0-9]+$ ]]; then
            echo "[❌] Entrée invalide. Veuillez entrer un numéro de ligne valide."
            shred -u "$TMPFILE"
            exit 1
        fi

        # Modifier la ligne spécifiée
        sed -i "${line_number}s/.*/$new_id_logiciel : $new_id -> $new_pwd/" "$TMPFILE"

        # Rechiffrer le fichier après modification
        openssl enc -aes-256-cbc -pbkdf2 -salt -in "$TMPFILE" -out "$FICHIER_ENC" -pass pass:"$MDP"

        # Supprimer le fichier temporaire pour des raisons de sécurité
        shred -u "$TMPFILE"

        echo
        echo "[✅] Mot de passe modifié avec succès."
        ;;

    4)
        echo -e "\e[1m=== [🗑️] Supprimer un mot de passe ===\e[0m"
        echo

        openssl enc -d -aes-256-cbc -pbkdf2 -salt -in "$FICHIER_ENC" -out "$TMPFILE" -pass pass:"$MDP" 2>/dev/null

        if [ $? -ne 0 ]; then
            echo "[❌] Erreur : Impossible de déchiffrer le fichier."
            exit 1
        fi

        # Affiche le contenu avec numéro de ligne
        echo "[📄] Liste des entrées enregistrées :"
        nl -w2 -s". " "$TMPFILE"

        echo
        read -p "[❓] Entrez le numéro de la ligne à supprimer : " ligne

        # Vérifie que le numéro est bien un entier positif
        if ! [[ "$ligne" =~ ^[0-9]+$ ]]; then
            echo "[⚠️] Numéro invalide."
            shred -u "$TMPFILE"
            continue
        fi

        # Supprime la ligne choisie
        sed -i "${ligne}d" "$TMPFILE"

        # Rechiffre
        openssl enc -aes-256-cbc -pbkdf2 -salt -in "$TMPFILE" -out "$FICHIER_ENC" -pass pass:"$MDP"
        shred -u "$TMPFILE"

        echo "[✅] Entrée supprimée avec succès."
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