import requests

# === CONFIGURATION ===
GITHUB_TOKEN = "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"
REPO_OWNER = "andemion"
REPO_NAME = "PlanAndBill"

headers = {
    "Authorization": f"Bearer {GITHUB_TOKEN}",
    "Accept": "application/vnd.github+json"
}

issues = [
    {"title": "Définir les champs dynamiques personnalisables", "body": "Identifier les champs à rendre modifiables dans la création de RDV"},
    {"title": "Mise en place de l'agenda Flutter", "body": "Développer l’interface de planification des RDV"},
    {"title": "Intégration Firebase Auth (Google)", "body": "Mettre en place une authentification via compte Google"},
    {"title": "Création des modèles de données Firestore", "body": "Structurer les données : RDV, factures, devis"},
    {"title": "Système de rappels (notifications)", "body": "Configurer Firebase Cloud Messaging pour notifications"},
    {"title": "Génération automatique de devis/factures PDF", "body": "Créer des documents à partir des données de RDV"},
    {"title": "Intégration API Google Drive", "body": "Envoyer automatiquement les PDF dans Drive"},
    {"title": "Tableau de bord (historique et documents)", "body": "Afficher les documents et RDV passés"},
    {"title": "Tests unitaires et fonctionnels", "body": "Couvrir les fonctionnalités critiques"},
    {"title": "UI/UX simplifié responsive", "body": "Maquettage et intégration d'une interface fluide"},
    {"title": "Envoi de rapports par email", "body": "Permettre l'envoi automatique de rapports périodiques (PDF ou texte) à la thérapeute"},
    {"title": "Chiffrement des données sensibles", "body": "Mettre en place un chiffrement pour les données médicales et confidentielles"},
    {"title": "Protection des données médicales (RGPD)", "body": "Garantir que toutes les données sont traitées selon le RGPD (consentement, anonymisation, droit à l’effacement)"}
]

# === Création des issues ===
#for issue in issues:
#    response = requests.post(
#        f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/issues",
#        headers=headers,
#        json={"title": issue["title"], "body": issue["body"]}
#    )
#    if response.status_code == 201:
#        print(f"Issue créée : {issue['title']}")
#    else:
#        print(f"Erreur ({response.status_code}) : {response.json()}")

new_issues = [
    {"title": "Mise à jour automatique des fichiers dans Google Drive", "body": "Intégrer l’API Google Drive pour que les factures et devis soient automatiquement mis à jour (modifiés ou remplacés) dans le dossier partagé avec la cliente."}
    ]

# === Vérifie les issues déjà existantes ===
print("Récupération des issues existantes…")
existing_titles = set()
page = 1
while True:
    res = requests.get(
        f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/issues?state=all&per_page=100&page={page}",
        headers=headers
    )
    data = res.json()
    if not data or res.status_code != 200:
        break
    existing_titles.update([issue["title"] for issue in data])
    page += 1

# === Création des nouvelles issues ===
for issue in new_issues:
    if issue["title"] not in existing_titles:
        response = requests.post(
            f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/issues",
            headers=headers,
            json={"title": issue["title"], "body": issue["body"]}
        )
        if response.status_code == 201:
            print(f"Issue créée : {issue['title']}")
        else:
            print(f"Erreur ({response.status_code}) : {response.json()}")
    else:
        print(f"Issue déjà existante : {issue['title']}")