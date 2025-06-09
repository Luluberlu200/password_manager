#!/bin/bash

# Fichier chiffré contenant les mots de passe, il sera créé s'il n'existe pas
FICHIER_ENC="password_manager.txt.enc"

# Fichier temporaire déchiffré (pour pouvoir le modifier/consulter)
TMPFILE=$(mktemp)

# Fonction pour forcer les utilisateurs et utilisatrices à choisir un mot de passe d'au moins 8 caractères
force_password() {
    local password=$1 # Vérifie si le mot de passe est passé en argument
    if [ ${#password} -lt 8 ]; then # vérifie la longueur du mot de passe
        echo "Mot de passe de 8 caractères minimum"
        return 1
    fi
    return 0
}

# Fonction pour générer un mot de passe aléatoire
mot_passe_random() {
    < /dev/urandom tr -dc 'A-Za-z0-9_@#%' | head -c 12 # Génère un mot de passe aléatoire de 12 caractères
    return 0
}

# Vérifie si le fichier est créé
if [ ! -f "$FICHIER_ENC" ]; then # Vérifie si le fichier chiffré n'existe pas
    echo "Aucun fichier chiffré trouvé."
    echo "Création initiale du fichier 'password_manager.txt'."
    echo -n
    echo "Souhaitez-vous choisir votre mot de passe ?"
    echo "1. Mot de passe personnalisé"
    echo "2. Générer un mot de passe aléatoire"
    read -p "Entrez 1 ou 2 : " choix
    echo

    if [[ "$choix" == "1" ]]; then # Vérifie si l'utilisateur a choisi de créer un mot de passe personnalisé
        echo -n "Crée ton mot de passe maître : "
        read -s MDP1
        if ! force_password "$MDP1"; then # Vérifie si le mot de passe est valide en le passant en paramètre de la fonction force_password
            exit 1
        fi

        echo
        echo -n "Confirme ton mot de passe : "
        read -s MDP2
        echo
        if [ "$MDP1" != "$MDP2" ]; then # Vérifie si les mots de passe sont différents
            echo "Mots de passe différents"
            exit 1
        fi

    elif [[ "$choix" == "2" ]]; then # Vérifie si l'utilisateur a choisi de générer un mot de passe aléatoire
    
        MDP1=$(mot_passe_random) # Appelle la fonction pour générer un mot de passe aléatoire
        echo "Mot de passe généré : $MDP1"
        read -p "Voulez-vous valider ce mot de passe (Yes/No) ? " validation
        if [[ "$validation" == "Yes" || "$validation" == "yes" ]]; then # Vérifie si l'utilisateur a validé le mot de passe
            echo "Mot de passe validé."
        elif [[ "$validation" == "No" || "$validation" == "no" ]]; then # Vérifie si l'utilisateur a refusé le mot de passe
            exit 1
        fi

    else
        echo "Choix invalide. Veuillez entrer 1 ou 2."
        exit 1

    fi
    openssl enc -aes-256-cbc -pbkdf2 -salt -in "$TMPFILE" -out "$FICHIER_ENC" -pass pass:"$MDP1" # Chiffre le fichier temporaire avec le mot de passe maître créé précédemment
    shred -u "$TMPFILE" # Supprime le fichier temporaire
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
if [ $? -ne 0 ]; then # Vérifie avec l'opérateur -ne si les mots de passe sont différents
    echo "Mot de passe incorrect"
    rm -f "$TMPFILE"
    exit 1
fi

# Rechiffrer le fichier
openssl enc -aes-256-cbc -pbkdf2 -salt -in "$TMPFILE" -out "$FICHIER_ENC" -pass pass:"$MDP" # Rechiffre le fichier temporaire avec le mot de passe maître
shred -u "$TMPFILE" # Supprime le fichier temporaire
echo "Fichier mis à jour et rechiffré avec succès."

# === MENU ===
while true; do
    echo
    echo -e "\e[1m=== [🔑] Gestionnaire de mot de passe ===\e[0m"
    echo
    echo "1. [➕] Ajouter un mot de passe"
    echo "2. [📖] Consulter mot de passe"
    echo "3. [✏️] Modification d'un/des mot(s) de passe"
    echo "4. [🗑️] Delete mot de passe"
    echo "5. [🚪] Quitter"
    echo
    read -p "📋 Entrez votre choix : " choice
    echo

    case "$choice" in
    1)
        echo -e "\e[1m=== [➕] Ajouter un nouveau mot de passe ===\e[0m"
        read -p "💻 Outil/logiciel/site : " id_logiciel
        read -p "📧 Adresse mail / nom utilisateur : " id
    
        echo "Souhaitez-vous :"
        echo "1) Saisir mot de passe "
        echo "2) Générer mot de passe aléatoire "
        read -p  "Entrez votre choix : " choix_mdp


        if [ "$choix_mdp" == "1" ]; then
            read -s -p "✍️ Entrez le mot de passe : " pwd # -s permet de ne pas afficher le mot de passe lors de la saisie, -p permet d'afficher le suivant qui suit
            echo
        elif [ "$choix_mdp" == "2" ]; then
            pwd=$(mot_passe_random) # Appelle la fonction pour générer un mot de passe aléatoire
            echo "Mot de passe :$pwd"
        else
            echo "Choix invalide"
            exit 1
        fi

        # Déchiffrer temporairement le fichier pour ajouter le mot de passe ainsi que l'ID
        openssl enc -d -aes-256-cbc -pbkdf2 -salt -in "$FICHIER_ENC" -out "$TMPFILE" -pass pass:"$MDP" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "[❌] Erreur : Impossible de déchiffrer le fichier. Mot de passe maître incorrect ou fichier corrompu."
            exit 1
        fi

        # Ajouter les nouvelles données au fichier dédié
        echo "$id_logiciel : $id -> $pwd" >> "$TMPFILE"

        # Permet de rechiffrer le fichier après avoir ajouté les données
        openssl enc -aes-256-cbc -pbkdf2 -salt -in "$TMPFILE" -out "$FICHIER_ENC" -pass pass:"$MDP"
        shred -u "$TMPFILE"
        echo "[✅] Mot de passe ajouté."
        ;;
    2)
        echo -e "\e[1m=== [📖] Consulter un mot de passe ===\e[0m"
        echo

        # Déchiffrer temporairement le fichier pour consulter les mots de passe
        openssl enc -d -aes-256-cbc -pbkdf2 -salt -in "$FICHIER_ENC" -out "$TMPFILE" -pass pass:"$MDP" 2>/dev/null 
        if [ $? -ne 0 ]; then
            echo "[❌] Erreur : Impossible de déchiffrer le fichier"
            exit 1
        fi

        if [ -s "$TMPFILE" ]; then # Vérifie si le fichier temporaire n'est pas vide grâce à l'option -s
            echo "Liste des outils/Sites  :"
            awk -F':' '{print NR ". " $1}' "$TMPFILE" # Affiche la liste des outils/sites avec leur numéro de ligne
            echo
            read -p "Quelle mot de passe voulez vous consulter (numéro ligne): " numero

            line=$(sed -n "${numero}p" "$TMPFILE") # Récupère la ligne correspondant au numéro entré par l'utilisateur
            # -n permet de n'afficher aucune ligne sauf celles demandées par l'option p
            if [ -z "$line" ]; then # Vérifie si la ligne est vide grâce à l'option -z
                echo "[❌] Numéro invalide."
                shred -u "$TMPFILE"
                exit 1
            fi


            # PS : xargs permet de supprimer les espaces inutiles en début et fin de ligne
            logiciel=$(echo "$line" | cut -d':' -f1 | xargs) # Récupère le nom du logiciel/site en coupant la ligne à partir du caractère ':'
            identifiant=$(echo "$line" | cut -d':' -f2 | cut -d'>' -f1 | xargs) # Récupère l'identifiant en coupant la ligne à partir du caractère ':' puis '>'
            motdepasse=$(echo "$line" | cut -d'>' -f2 | xargs) # Récupère le mot de passe en coupant la ligne à partir du caractère '>'

            echo
            echo "Outil/Site    : $logiciel"
            echo "Identifiant : $identifiant"
            echo "Mot de passe : $motdepasse"

            # Ici on utilise xclip pour copier le mot de passe dans le presse-papiers
            echo "$motdepasse" | xclip -selection clipboard # Copie le mot de passe dans le presse-papiers
            echo "[✅] Mot de passe copié "
        else
            echo "pas de mot de passe"
        fi
        shred -u "$TMPFILE"
        ;;
    3)
        echo -e "\e[1m=== [✏️] Modifier un mot de passe ===\e[0m"
        echo
        # On déchiffre encore une fois le fichier pour pouvoir modifier les mots de passe
        openssl enc -d -aes-256-cbc -pbkdf2 -salt -in "$FICHIER_ENC" -out "$TMPFILE" -pass pass:"$MDP" 2>/dev/null 
        if [ $? -ne 0 ]; then
            echo "[❌] Erreur : Impossible de déchiffrer le fichier. Mot de passe maître incorrect ou fichier corrompu."
            exit 1
        fi
        echo "=== [📖] Liste des mots de passe ==="
        cat -n "$TMPFILE"
        echo
        read -p "Entrez le numéro de la ligne à modifier : " line_number
        if ! [[ "$line_number" =~ ^[0-9]+$ ]]; then # Vérifie si l'entrée est un nombre entier grâce à l'expression régulière ^[0-9]+$
            echo "[❌] Entrée invalide. Veuillez entrer un numéro de ligne valide."
            shred -u "$TMPFILE"
            exit 1
        fi
        total_lines=$(wc -l < "$TMPFILE") # Compte le nombre de lignes dans le fichier temporaire grâce à la commande wc -l
        if [ "$line_number" -lt 1 ] || [ "$line_number" -gt "$total_lines" ]; then
            echo "[❌] Numéro de ligne invalide."
            shred -u "$TMPFILE"
            exit 1
        fi

        selected_line=$(sed -n "${line_number}p" "$TMPFILE") # Récupère la ligne sélectionnée par l'utilisateur
        echo "Ligne sélectionnée : $selected_line"
        echo
        echo "Que souhaitez-vous modifier ?"
        echo "1. 💻 Outil/logiciel/site"
        echo "2. 📧 Adresse mail / nom utilisateur"
        echo "3. 🔒 Mot de passe"
        echo "4. Modifier tout"
        read -p "Entrez votre choix (1-4) : " modify_choice

        new_id_logiciel=$(echo "$selected_line" | cut -d':' -f1 | xargs) 
        new_id=$(echo "$selected_line" | cut -d'>' -f1 | cut -d':' -f2 | xargs)
        new_pwd=$(echo "$selected_line" | cut -d'>' -f2 | xargs)

        case "$modify_choice" in
            1) read -p "💻 Nouveau outil/logiciel/site : " new_id_logiciel ;;
            2) read -p "📧 Nouvelle adresse mail / nom utilisateur : " new_id ;;
            3) read -s -p "🔒 Nouveau mot de passe : " new_pwd; echo ;;
            4)
                read -p "💻 Nouveau outil/logiciel/site : " new_id_logiciel
                read -p "📧 Nouvelle adresse mail / nom utilisateur : " new_id
                read -s -p "🔒 Nouveau mot de passe : " new_pwd
                echo
                ;;
            *)
                echo "[❌] Choix invalide."
                shred -u "$TMPFILE"
                exit 1
                ;;
        esac
        

        sed -i "${line_number}s/.*/$new_id_logiciel : $new_id -> $new_pwd/" "$TMPFILE" # Modifie la ligne sélectionnée avec les nouvelles informations saisies dans le fichier temporaire
        openssl enc -aes-256-cbc -pbkdf2 -salt -in "$TMPFILE" -out "$FICHIER_ENC" -pass pass:"$MDP" # Rechiffre le fichier une fois les modifications effectuées
        shred -u "$TMPFILE"
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

        echo "[📄] Liste des entrées enregistrées :"
        nl -w2 -s". " "$TMPFILE"
        echo
        read -p "[❓] Entrez le numéro de la ligne à supprimer : " ligne

        sed -i "${ligne}d" "$TMPFILE" # Supprime la ligne sélectionnée par l'utilisateur dans le fichier temporaire

        openssl enc -aes-256-cbc -pbkdf2 -salt -in "$TMPFILE" -out "$FICHIER_ENC" -pass pass:"$MDP"
        shred -u "$TMPFILE"

        echo "[✅] Supprimée."
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
    *)
        echo "[❌] Choix invalide. Veuillez réessayer."
        ;;
    esac
done