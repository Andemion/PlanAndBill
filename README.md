# 🗓️ Application de Prise de Rendez-vous – Art-Thérapeute

Ce projet est une application **cross-platform** développée en **Flutter** pour permettre à une **art-thérapeute indépendante** de gérer ses rendez-vous, documents administratifs et sa relation client de manière simple, fluide et professionnelle.

---

## 🚀 Fonctionnalités principales

- 📅 **Agenda personnalisable** : création, modification, suppression de rendez-vous
- 🧩 **Champs dynamiques** : adaptables aux besoins de la thérapeute
- 🔔 **Rappels automatiques** des rendez-vous (via notification)
- 🧾 **Génération automatique de devis et factures**
- ☁️ **Mise à jour automatique des documents dans Google Drive**
- 📊 **Tableau de bord de suivi** (historique des rendez-vous et documents)
- 📧 **Envoi automatique de rapports par email**
- 🔐 **Chiffrement des données sensibles**
- 🛡️ **Conformité RGPD pour la protection des données médicales**

---

## 🧱 Stack Technique

| Technologie | Description |
|-------------|-------------|
| **Flutter** | Framework principal (mobile/web) |
| **Firebase** | Authentification Google, Firestore, Cloud Functions, Cloud Messaging |
| **Google Drive API** | Stockage synchronisé des documents (factures, devis) |
| **GitHub Projects** | Suivi des tâches avec Kanban |
| **WhatsApp** | Canal de communication direct pour le projet |

---

## 🛠️ Structure du projet

/lib
/models
/screens
/services
/widgets
/test

---

## 📌 Suivi de projet

- 📋 **Kanban GitHub Project** : suivi des tâches par colonne (`À faire`, `En cours`, `Test`, `Terminé`)
- ✅ Les tâches sont créées automatiquement via script Python dans les issues
- 📁 Partage de documents via Google Drive partagé

---

## 🧪 Lancer le projet localement


### Prérequis

- Flutter SDK installé : https://flutter.dev/docs/get-started/install
- Un compte Firebase
- Un projet Google Cloud avec Drive API activée

### Étapes

```bash
git clone https://github.com/Andemion/PlanAndBill.git
cd <repo>
flutter pub get
flutter run
```

### 💡 Configuration Firebase

Configurez votre fichier `.env` ou `firebase_options.dart` selon les paramètres de votre projet Firebase (clé API, ID de projet, etc.).

---

## 🔐 Sécurité & RGPD

- 🔒 **Chiffrement natif** des données via Firebase
- 🔐 **Authentification sécurisée** via compte Google
- 🛡️ **Respect du RGPD** :
    - Consentement des utilisateurs
    - Droit à l’effacement des données
    - Journalisation des accès sensibles

---

## 🤝 Collaboration

- 💬 Communication fluide via **WhatsApp**
- 📁 Partage de documents et exports via **Google Drive partagé**
- ⚙️ Gestion de projet **agile** : MVP initial suivi de sprints d’amélioration

---

## 📧 Contact

- 👨‍💻 **Développeur** : Arnaud Roussel
- 📩 **Email** : arnaud.roussel@my-digital-school.org
- 📱 **Support direct via WhatsApp** avec la cliente pour échanges et validation continue
