# 🎓 Gestion Universitaire — Système d'Analyse et de Pilotage des Études

> Système **Business Intelligence** complet couvrant le stockage transactionnel (SQL), documentaire (NoSQL) et l'analyse décisionnelle multidimensionnelle (Data Warehouse).

![MySQL](https://img.shields.io/badge/MySQL-8.x-4479A1?style=flat&logo=mysql&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-7.x-47A248?style=flat&logo=mongodb&logoColor=white)
![SQL Server](https://img.shields.io/badge/SQL_Server-2022-CC2927?style=flat&logo=microsoftsqlserver&logoColor=white)
![Talend](https://img.shields.io/badge/Talend-8.x-FF6D70?style=flat&logo=talend&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=flat)

---

## 📋 Table des matières

1. [Présentation](#-présentation)
2. [Architecture globale](#-architecture-globale)
3. [Partie 1 — SQL (MySQL)](#-partie-1--base-de-données-relationnelle-mysql)
4. [Partie 2 — NoSQL (MongoDB)](#-partie-2--base-de-données-documentaire-mongodb)
5. [Partie 3 — Data Warehouse & BI](#-partie-3--data-warehouse--bi-sql-server)
6. [Données de test](#-données-de-test)
7. [Prérequis](#-prérequis-techniques)
8. [Installation](#-installation--déploiement)
9. [Auteur](#-auteur)

---

## 🎯 Présentation

**Gestion Universitaire** est un projet BI end-to-end conçu pour gérer et analyser les performances académiques d'une université, à travers trois paradigmes de stockage complémentaires :

| Paradigme | Technologie | Rôle |
|-----------|-------------|------|
| **Relationnel** | MySQL 8.x | Opérations transactionnelles, intégrité référentielle |
| **Documentaire** | MongoDB 7.x | Dénormalisation flexible, pipelines d'agrégation |
| **Décisionnel** | SQL Server 2022 | Schéma en étoile, OLAP, rapports paginés |

Le pipeline ETL (Talend) alimente le Data Warehouse depuis les sources SQL/CSV, puis expose les données via des vues OLAP, des requêtes MDX, un cube SSAS et des rapports SSRS.

---

## 🏗️ Architecture globale

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Gestion Universitaire                           │
├─────────────────────┬──────────────────────┬────────────────────────────┤
│    SQL (MySQL)       │   NoSQL (MongoDB)    │  Data Warehouse            │
│    Base normative    │   Base documentaire  │  (SQL Server)              │
│                      │                      │                            │
│   8 tables           │   4 collections      │  7 dimensions + 1 fait     │
│   normalisées        │   dénormalisées      │  (Star Schema)             │
│                      │                      │                            │
│   DDL / DML SQL      │   Pipelines $group   │  ETL Talend → OLAP         │
│   Jointures          │   $lookup / $unwind  │  MDX / SSAS / SSRS         │
└─────────────────────┴──────────────────────┴────────────────────────────┘
```

---

## 🗄️ Partie 1 — Base de données relationnelle (MySQL)

### Modèle Conceptuel (MCD)

![Modèle Conceptuel](SQL/images/ModelisationConceptuelle.png)

### Modèle Logique (MLD)

![Modèle Logique](SQL/images/ConceptionLogique.png)

### Structure des tables (8 tables)

| Table | Rôle | Clé primaire |
|-------|------|-------------|
| `DEPARTEMENT` | Départements académiques | `id_departement` |
| `FILIERE` | Filières / spécialités | `id_filiere` |
| `NIVEAU` | Niveaux d'études (L1, L2, …) | `id_niveau` |
| `FILIERE_NIVEAU` | Association Filière ↔ Niveau | `(id_filiere, id_niveau)` |
| `ETUDIANT` | Étudiants inscrits | `id_etudiant` |
| `ENSEIGNANT` | Enseignants | `id_enseignant` |
| `MATIERE` | Matières enseignées | `id_matiere` |
| `ENSEIGNEMENT` | Relation ternaire Enseignant → Matière → Filière | `(id_enseignant, id_filiere, id_matiere, id_niveau)` |
| `COMPOSITION` | Notes des étudiants | `(id_etudiant, id_matiere, session, ann_univ)` |

### Fichiers sources

```
SQL/
├── GestionUniversitaireCreationTable.sql   # DDL — création des tables
├── GestionUniversitaire_dataset.sql        # DML — insertion des données
├── RequetesGestionUniversitaire.sql        # Requêtes d'analyse SQL
└── data/                                   # Fichiers CSV de test
```

---

## 🍃 Partie 2 — Base de données documentaire (MongoDB)

### Approche de dénormalisation

Les entités relationnelles sont **aplaties** en documents enrichis. Chaque document `etudiant` embarque directement sa filière, son niveau, ses notes et ses matières — éliminant les jointures au profit de la performance en lecture.

### Collections (4)

| Collection | Fichier CSV source | Description |
|------------|--------------------|-------------|
| `etudiants` | `NoSql/data/etudiants.csv` | Étudiants + notes (dénormalisé) |
| `enseignants` | `NoSql/data/enseignants.csv` | Enseignants + affectations |
| `departements` | `NoSql/data/departements.csv` | Départements + filières |
| `matieres` | `NoSql/data/matiers.csv` | Matières + coefficients |

### Exemple de document `etudiants`

```json
{
  "etu_id": "ETU_1",
  "nom": "Konaté",
  "prenom": "Aminata",
  "nom_filiere": "Génie Logiciel",
  "nom_niveau": "Licence 1",
  "annee_universitaire": "2025-2026",
  "valeur_note": 14.5,
  "libelle_matiere": "Algorithmique et Structures de Données",
  "coefficient": 3,
  "semestre": "S1",
  "session": "Normale"
}
```

### Pipelines d'agrégation (10 analyses)

> Fichier : `NoSql/Requettes.mongodb.js`

| # | Analyse | Opérateurs clés |
|---|---------|-----------------|
| 1 | Étudiants avec moyenne > 17 | `$group`, `$match`, `$sort` |
| 2 | Enseignants par département / filière | `$lookup`, `$group`, `$addToSet` |
| 3 | Évolution des inscriptions par année / filière | `$year`, `$group`, `$sort` |
| 4 | Performance temporelle par année / filière | `$avg`, `$round`, `$project` |
| 5 | Meilleur étudiant par filière / année | `$max`, `$filter`, `$arrayElemAt` |
| 6 | Répartition des étudiants par filière | `$group`, `$sum`, `$sort` |
| 7 | Taux de réussite par filière (≥ 10/20) | `$cond`, `$divide`, `$multiply` |
| 8 | Top 10 étudiants toutes filières confondues | `$sort`, `$limit` |
| 9 | Performance par matière et semestre | `$group`, `$avg`, `$project` |
| 10 | Charge d'enseignement par enseignant | `$addToSet`, `$size`, `$project` |

### Résultats des requêtes

**Étudiants avec moyenne supérieure à 17**

![Étudiants moyenne > 17](NoSql/images/Etudiants_moyenne_supérieur_17.png)

**Évolution du nombre d'étudiants par année**

![Évolution par année](NoSql/images/Evolution_nbrStudentParAnnee.png)

**Répartition par département et filière**

![Répartition département/filière](NoSql/images/Nbr_Etudiants_Par_depart_filiere.png)

---

## 🏢 Partie 3 — Data Warehouse & BI (SQL Server)

### Schéma en étoile

```
                     ┌─────────────┐
                     │  DIM_DATE   │
                     └──────┬──────┘
                             │
┌──────────────┐   ┌─────────┴──────────┐   ┌─────────────┐
│ DIM_ETUDIANT │   │                    │   │ DIM_SESSION  │
│  (SCD Type1) ├───┤     FAIT_NOTE      ├───┤              │
└──────────────┘   │                    │   └─────────────┘
                    │  note_obtenue      │
┌──────────────┐   │  coefficient       │   ┌─────────────┐
│ DIM_FILIERE  │   │  note_pondérée     │   │  DIM_NIVEAU  │
│  (SCD Type2) ├───┤  note_pourcentage  ├───┤              │
└──────────────┘   └─────────┬──────────┘   └─────────────┘
                             │
┌──────────────┐             │              ┌─────────────┐
│DIM_ENSEIGNANT│             │              │ DIM_MATIERE  │
│  (SCD Type2) ├─────────────┴──────────────┤  (SCD Type1) │
└──────────────┘                            └─────────────┘
```

**Grain :** 1 ligne = 1 étudiant × 1 matière × 1 session × 1 date d'évaluation

### Dimensions

| Dimension | SCD | Attributs notables |
|-----------|-----|--------------------|
| `DIM_DATE` | — | jour, mois, trimestre, semestre_univ, est_weekend, est_periode_exam |
| `DIM_ETUDIANT` | Type 1 | nom_complet (calculé), age, tranche_age |
| `DIM_FILIERE` | Type 2 | code/nom filière, département, responsable, date_validité |
| `DIM_NIVEAU` | — | nom_niveau, annee_universitaire |
| `DIM_ENSEIGNANT` | Type 2 | nom_complet, grade, ancienneté_années |
| `DIM_MATIERE` | Type 1 | code, libelle, semestre, coefficient, volume_horaire |
| `DIM_SESSION` | — | code_session (Normale / Rattrapage) |

### ETL Talend — Jobs de chargement

> Exécuter dans l'ordre : **dimensions d'abord, table de faits en dernier**

| Ordre | Job | Destination | Aperçu |
|-------|-----|-------------|--------|
| 1 | `JobDimDAte` | `DIM_DATE` | ![JobDimDAte](DW/OLAP/images/Job_Talend/JobDimDAte.png) |
| 2 | `JobDim_Etudiant` | `DIM_ETUDIANT` | ![JobDimEtudiant](DW/OLAP/images/Job_Talend/JobDim_Etudiant.png) |
| 3 | `jobDIMFiliere` | `DIM_FILIERE` | ![JobDimFiliere](DW/OLAP/images/Job_Talend/jobDIMFiliere.png) |
| 4 | `JobDimNiveau` | `DIM_NIVEAU` | ![JobDimNiveau](DW/OLAP/images/Job_Talend/JobDimNiveau.png) |
| 5 | `JobDimENseignant` | `DIM_ENSEIGNANT` | ![JobDimEnseignant](DW/OLAP/images/Job_Talend/JobDimENseignant.png) |
| 6 | `Jobdimmatiere` | `DIM_MATIERE` | ![JobDimMatiere](DW/OLAP/images/Job_Talend/Jobdimmatiere.png) |
| 7 | `JOBFAITENOTE` | `FAIT_NOTE` | ![JobFaitNote](DW/OLAP/images/Job_Talend/JOBFAITENOTE.png) |

### Vérification des dimensions chargées

| Dimension | Aperçu |
|-----------|--------|
| `DIM_DATE` | ![Dim_date](DW/OLAP/images/Verification_Dimensions/Dim_date.png) |
| `DIM_ETUDIANT` | ![Dim_Etudiant](DW/OLAP/images/Verification_Dimensions/Dim_Etudiant.png) |
| `DIM_FILIERE` | ![Dim_Filiere](DW/OLAP/images/Verification_Dimensions/Dim_Filire.png) |
| `DIM_NIVEAU` | ![Dim_niveau](DW/OLAP/images/Verification_Dimensions/Dim_niveau.png) |
| `DIM_ENSEIGNANT` | ![Dim_enseignant](DW/OLAP/images/Verification_Dimensions/Dim_enseignant.png) |
| `DIM_MATIERE` | ![Dim_Matiere](DW/OLAP/images/Verification_Dimensions/Dim_Matiere.png) |
| `DIM_SESSION` | ![Dim_Session](DW/OLAP/images/Verification_Dimensions/Dim_Session.png) |
| `FAIT_NOTE` | ![Table_Fait](DW/OLAP/images/Verification_Dimensions/Table_Fait.png) |

### Vues OLAP (6 vues analytiques)

> Fichier : `DW/OLAP/VUE_SQL_SERVER.sql`

| Vue | Objet d'analyse | Métriques clés |
|-----|-----------------|----------------|
| `VW_PERFORMANCE_ETUDIANT` | Performance individuelle | moyenne, mention, nb matières validées/échouées |
| `VW_PERFORMANCE_FILIERE` | Analyse par filière | nb étudiants, taux de réussite, moyenne pondérée |
| `VW_PERFORMANCE_MATIERE` | Analyse par matière | moyenne, écart-type, distribution des mentions |
| `VW_PERFORMANCE_ENSEIGNANT` | Analyse par enseignant | moyenne classe, taux de réussite |
| `VW_ANALYSE_TEMPORELLE` | Évolution temporelle | tendances par année, semestre, mois |
| `VW_COMPARAISON_SESSIONS` | Session normale vs rattrapage | progression/régression par étudiant et matière |

### Requêtes MDX (5 analyses)

> Fichier : `DW/MDX/GU_REQUTE.mdx`

| # | Analyse | Dimensions croisées |
|---|---------|---------------------|
| 1 | Moyenne des notes par filière | Mesures × Filière |
| 2 | Performance des étudiants par session | Session × Étudiant |
| 3 | Taux de réussite matière × filière | Filière × Matière |
| 4 | Performance enseignant × matière | Enseignant × Matière |
| 5 | Évolution par niveau et année | Niveau × Date × Session |

### Résultats MDX

**Moyenne des notes par filière**

![Moyenne par filière](DW/MDX/images/Moyenne_Des_Notes_Par_Filière.png)

**Performance par enseignant et matière**

![Performance enseignant/matière](DW/MDX/images/Performance_Par_enseignant_et_Matiere.png)

### Cube SSAS

![Cube SSAS](DW/SSAS/images/Cube.png)

| Vue des données | Vue parcourue |
|-----------------|---------------|
| ![Vue données](DW/SSAS/images/Vue%20des%20%20données.png) | ![Vue parcourue](DW/SSAS/images/Vue%20parcourue.png) |

### Rapports SSRS

| Configuration | Rapport déployé | Rapport local |
|---------------|-----------------|---------------|
| ![Config SSRS](DW/SSRS/images/Gestionnaire_de_configuration_SSRS.png) | ![Déployé](DW/SSRS/images/RapportDeplouer_dans_RepportServer.png) | ![Non déployé](DW/SSRS/images/RapportNondeployer.png) |

---

## 📊 Données de test

### SQL — 9 fichiers CSV (`SQL/data/`)

| Fichier | Contenu |
|---------|---------|
| `departement.csv` | Départements |
| `filiere.csv` | Filières (GL, DSB, …) |
| `niveau.csv` | Niveaux (L1, L2, …) |
| `etudiant.csv` | Étudiants avec inscriptions |
| `enseignant.csv` | Enseignants |
| `matiere.csv` | Matières avec coefficients |
| `enseignement.csv` | Affectations enseignant → matière → filière |
| `composition.csv` | Notes d'évaluation |
| `fait_note.csv` | Données pré-chargées pour le DW |

### NoSQL — 4 fichiers CSV (`NoSql/data/`)

| Fichier | Contenu |
|---------|---------|
| `departements.csv` | Départements avec filières |
| `enseignants.csv` | Enseignants avec affectations |
| `etudiants.csv` | Étudiants avec notes (dénormalisé) |
| `matiers.csv` | Matières |

---

## 🛠️ Prérequis techniques

| Technologie | Version | Usage |
|-------------|---------|-------|
| MySQL | 8.x | Base transactionnelle |
| MongoDB | 7.x | Base documentaire |
| SQL Server | 2022+ | Data Warehouse |
| Talend Open Studio | 8.x | Pipelines ETL |
| SSAS | — | Cube OLAP multidimensionnel |
| SSRS | — | Rapports paginés |
| MySQL Workbench | — | Modélisation & administration MySQL |
| MongoDB Compass / mongosh | — | Visualisation & requêtage MongoDB |
| SSMS | — | Administration SQL Server |

---

## 🚀 Installation & Déploiement

### 1. Base SQL (MySQL)

```bash
mysql -u root -p < SQL/GestionUniversitaireCreationTable.sql
mysql -u root -p < SQL/GestionUniversitaire_dataset.sql
```

### 2. Base NoSQL (MongoDB)

```bash
mongosh GestionUniversitaire < NoSql/Requettes.mongodb.js
```

### 3. Data Warehouse (SQL Server)

```sql
:r DW/OLAP/DW_GU_SQLSERVER.sql
GO
:r DW/OLAP/VUE_SQL_SERVER.sql
GO
```

### 4. ETL Talend

```
1. Ouvrir Talend Open Studio for Data Integration
2. Importer le projet depuis DW/OLAP/
3. Configurer les connexions :
   - Source  : MySQL (host, port, db, user, password)
   - Cible   : SQL Server (host, port, DW_GestionUniversitaire)
4. Exécuter les jobs dans l'ordre :
   JobDimDAte → JobDim_Etudiant → jobDIMFiliere → JobDimNiveau
   → JobDimENseignant → Jobdimmatiere → JOBFAITENOTE
```

### 5. Cube SSAS

```
1. Ouvrir DW/SSAS/SSAS_GestionUniversitaire/SSAS_GestionUniversitaire.slnx dans Visual Studio
2. Vérifier la connexion à DW_GestionUniversitaire
3. Build → Deploy sur le serveur SSAS
```

### 6. Rapports SSRS

```
1. Ouvrir DW/SSRS/SSRS_GestionUniversitaire/SSRS_GestionUniversitaire.slnx dans Visual Studio
2. Configurer TargetServerURL dans les propriétés du projet
3. Build → Deploy les fichiers .rdl
```

---

## 👤 Auteur

**Japhet Allah-N'diguim**

Projet réalisé dans le cadre d'un cursus en **Business Intelligence** et **Systèmes d'Information Décisionnels**.

---

## 🔖 Tags

`#BusinessIntelligence` `#DataWarehouse` `#ETL` `#Talend` `#MySQL` `#MongoDB` `#SQLServer` `#SSAS` `#SSRS` `#MDX` `#OLAP` `#StarSchema` `#DataEngineering` `#NoSQL` `#DataAnalytics`
