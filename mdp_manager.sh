#!/bin/bash
#  Création du mot de passe maître et sauvegarde de celui-ci

read -s -p "Créer un mot de passe maître : " master
echo
echo -n "$master" | sha256sum | awk '{print $1}' > ~/.passmaster
chmod 600 ~/.passmaster
echo "Mot de passe maître enregistré."

# Vérifie si le fichier contenant le hash existe
if [ ! -f ~/.passmaster ]; then
    echo "Erreur : fichier de mot de passe maître introuvable."
    exit 1
fi

echo "Le fichier existe"

# Demande du mot de passe maître
read -s -p "Entrez le mot de passe maître : " entered
echo

# Hachage et comparaison du mot de passe mâitre
entered_hash=$(echo -n "$entered" | sha256sum | awk '{print $1}')
stored_hash=$(cat ~/.passmaster)

if [ "$entered_hash" != "$stored_hash" ]; then
    echo "Mot de passe incorrect. Accès refusé."
    exit 1
fi

echo "✅ Accès autorisé."


while true; do 
        echo "===Gestionnaire Password===="
        echo "1. Ajouter un mot de passe"
        echo "2. Consulter mode de passe"
        echo "3. Delete mot de passe"
        echo "4. Quitter"
        read -p "choix : " choice
        
done

