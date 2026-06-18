-- ======================================================
-- Nom du projet  : DW_GestionUniversitaire
-- Description    : Data Warehouse — schéma en étoile
--                  
-- Auteur         : Japhet Allah-N'diguim
-- ======================================================

-- Création de la base de données
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'DW_GestionUniversitaire')
BEGIN
    CREATE DATABASE DW_GestionUniversitaire
    COLLATE French_CI_AS;
END
GO

USE DW_GestionUniversitaire;
GO

-- ======================================================
-- DIMENSION 1 : DIM_DATE
-- Clé naturelle : YYYYMMDD (ex: 20240915)
-- Couvre 2020-01-01 → 2027-12-31
-- ======================================================
IF OBJECT_ID('DIM_DATE', 'U') IS NOT NULL DROP TABLE DIM_DATE;
GO

CREATE TABLE DIM_DATE (
    ID_DATE                INT           NOT NULL,
    date_complete          DATE          NOT NULL,
    jour                   TINYINT       NOT NULL,       -- 1..31
    jour_semaine           TINYINT       NOT NULL,       -- 1=Lundi .. 7=Dimanche
    semaine_universitaire  TINYINT       NULL,           -- Semaine dans le calendrier universitaire
    mois                   TINYINT       NOT NULL,       -- 1..12
    trimestre              TINYINT       NOT NULL,       -- 1..4
    semestre_univ          VARCHAR(15)   NOT NULL,       -- S1, S2, Hors-semestre
    annee                  SMALLINT      NOT NULL,
    annee_universitaire    VARCHAR(20)   NULL,           -- Ex: 2024-2025
    est_weekend            TINYINT       NOT NULL DEFAULT 0,
    est_ferie              TINYINT       NOT NULL DEFAULT 0,
    est_periode_exam       TINYINT       NOT NULL DEFAULT 0,
    --
    CONSTRAINT PK_DIM_DATE PRIMARY KEY (ID_DATE)
);
GO


-- ======================================================
-- DIMENSION 2 : DIM_FILIERE  (SCD Type 2)
-- ======================================================
IF OBJECT_ID('DIM_FILIERE', 'U') IS NOT NULL DROP TABLE DIM_FILIERE;
GO

CREATE TABLE DIM_FILIERE (
    id_filiere_dim           INT           NOT NULL IDENTITY(1,1),
    id_filiere_source        INT           NOT NULL,
    code_filiere             VARCHAR(20)   NOT NULL,
    nom_filiere              VARCHAR(100)  NOT NULL,
    id_departement           INT           NOT NULL,
    nom_departement          VARCHAR(100)  NOT NULL,
    responsable_departement  VARCHAR(100)  NOT NULL,
    -- Colonnes SCD Type 2
    date_validite_debut      DATE          NOT NULL,
    date_validite_fin        DATE          NULL,
    est_actif                TINYINT       NOT NULL DEFAULT 1,
    --
    CONSTRAINT PK_DIM_FILIERE PRIMARY KEY (id_filiere_dim)
);
GO


-- ======================================================
-- DIMENSION 3 : DIM_ETUDIANT  (SCD Type 1)
-- Note: SQL Server ne supporte pas GENERATED ALWAYS AS pour
-- colonnes VARCHAR calculées en dehors des colonnes calculées.
-- On utilise une colonne calculée (COMPUTED COLUMN).
-- ======================================================
IF OBJECT_ID('DIM_ETUDIANT', 'U') IS NOT NULL DROP TABLE DIM_ETUDIANT;
GO

CREATE TABLE DIM_ETUDIANT (
    id_etudiant_dim    INT           NOT NULL IDENTITY(1,1),
    id_etudiant_source INT           NOT NULL,
    nom                VARCHAR(50)   NOT NULL,
    prenom             VARCHAR(50)   NOT NULL,
    nom_complet        AS (nom + ' ' + prenom) PERSISTED,  -- Colonne calculée
    date_naissance     DATE          NOT NULL,
    age                INT           NULL,
    tranche_age        VARCHAR(30)   NULL,
    email              VARCHAR(100)  NULL,
    telephone          VARCHAR(20)   NULL,
    adresse            NVARCHAR(MAX) NULL,
    statut             VARCHAR(30)   NULL,
    date_inscription   DATE          NULL,
    --
    CONSTRAINT PK_DIM_ETUDIANT PRIMARY KEY (id_etudiant_dim)
);
GO


-- ======================================================
-- DIMENSION 4 : DIM_NIVEAU
-- ======================================================
IF OBJECT_ID('DIM_NIVEAU', 'U') IS NOT NULL DROP TABLE DIM_NIVEAU;
GO

CREATE TABLE DIM_NIVEAU (
    id_niveau_dim       INT          NOT NULL IDENTITY(1,1),
    id_niveau_source    INT          NOT NULL,
    nom_niveau          VARCHAR(50)  NOT NULL,
    annee_universitaire VARCHAR(20)  NOT NULL,
    --
    CONSTRAINT PK_DIM_NIVEAU PRIMARY KEY (id_niveau_dim)
);
GO


-- ======================================================
-- DIMENSION 5 : DIM_ENSEIGNANT  (SCD Type 2)
-- ======================================================
IF OBJECT_ID('DIM_ENSEIGNANT', 'U') IS NOT NULL DROP TABLE DIM_ENSEIGNANT;
GO

CREATE TABLE DIM_ENSEIGNANT (
    id_enseignant_dim    INT           NOT NULL IDENTITY(1,1),
    id_enseignant_source INT           NOT NULL,
    nom                  VARCHAR(50)   NOT NULL,
    prenom               VARCHAR(50)   NOT NULL,
    nom_complet          AS (nom + ' ' + prenom) PERSISTED,  -- Colonne calculée
    email                VARCHAR(100)  NULL,
    grade                VARCHAR(50)   NULL,
    date_embauche        DATE          NULL,
    anciennete_annees    INT           NULL,
    -- Colonnes SCD Type 2
    date_validite_debut  DATE          NOT NULL,
    date_validite_fin    DATE          NULL,
    est_actif            TINYINT       NOT NULL DEFAULT 1,
    --
    CONSTRAINT PK_DIM_ENSEIGNANT PRIMARY KEY (id_enseignant_dim)
);
GO


-- ======================================================
-- DIMENSION 6 : DIM_MATIERE  (SCD Type 1)
-- ======================================================
IF OBJECT_ID('DIM_MATIERE', 'U') IS NOT NULL DROP TABLE DIM_MATIERE;
GO

CREATE TABLE DIM_MATIERE (
    id_matiere_dim    INT           NOT NULL IDENTITY(1,1),
    id_matiere_source INT           NOT NULL,
    code_matiere      VARCHAR(20)   NOT NULL,
    libelle           VARCHAR(100)  NOT NULL,
    semestre          VARCHAR(10)   NOT NULL,   -- S1 | S2 | S3...
    coefficient       DECIMAL(3,2)  NULL,
    volume_horaire    INT           NULL,        -- Heures totales du cours
    --
    CONSTRAINT PK_DIM_MATIERE PRIMARY KEY (id_matiere_dim)
);
GO


-- ======================================================
-- DIMENSION 7 : DIM_SESSION
-- ======================================================
IF OBJECT_ID('DIM_SESSION', 'U') IS NOT NULL DROP TABLE DIM_SESSION;
GO

CREATE TABLE DIM_SESSION (
    id_session_dim  INT          NOT NULL IDENTITY(1,1),
    code_session    VARCHAR(20)  NOT NULL,   -- NORMALE | RATTRAPAGE
    --
    CONSTRAINT PK_DIM_SESSION PRIMARY KEY (id_session_dim)
);
GO


-- ======================================================
-- TABLE DE FAITS : FAIT_NOTE
-- Grain : 1 ligne = 1 étudiant × 1 matière × 1 session × 1 date
-- Note: SQL Server utilise des colonnes calculées (AS ... PERSISTED)
--       à la place de GENERATED ALWAYS AS de MySQL.
-- ======================================================
IF OBJECT_ID('FAIT_NOTE', 'U') IS NOT NULL DROP TABLE FAIT_NOTE;
GO

CREATE TABLE FAIT_NOTE (
    id_fait_note         INT           NOT NULL IDENTITY(1,1),

    -- Clés étrangères (Surrogate Keys)
    id_etudiant_dim      INT           NOT NULL,
    id_filiere_dim       INT           NOT NULL,
    id_niveau_dim        INT           NOT NULL,
    id_enseignant_dim    INT           NOT NULL,
    id_matiere_dim       INT           NOT NULL,
    id_session_dim       INT           NOT NULL,
    ID_DATE              INT           NOT NULL,

    -- Mesures factuelles
    note_obtenue         DECIMAL(4,2)  NOT NULL,
    note_pourcentage     AS (note_obtenue * 5.00) PERSISTED,   -- (note/20)*100
    coefficient_applique DECIMAL(3,2)  NOT NULL,
    note_ponderee        AS (note_obtenue * coefficient_applique) PERSISTED,

    -- Métadonnées ETL
    commentaire          NVARCHAR(MAX) NULL,
    date_chargement      DATETIME2     NOT NULL DEFAULT GETDATE(),

    -- Clé primaire
    CONSTRAINT PK_FAIT_NOTE PRIMARY KEY (id_fait_note),

    -- Contraintes d'intégrité référentielle
    CONSTRAINT FK_FN_ETUDIANT   FOREIGN KEY (id_etudiant_dim)   REFERENCES DIM_ETUDIANT  (id_etudiant_dim),
    CONSTRAINT FK_FN_FILIERE    FOREIGN KEY (id_filiere_dim)    REFERENCES DIM_FILIERE   (id_filiere_dim),
    CONSTRAINT FK_FN_NIVEAU     FOREIGN KEY (id_niveau_dim)     REFERENCES DIM_NIVEAU    (id_niveau_dim),
    CONSTRAINT FK_FN_ENSEIGNANT FOREIGN KEY (id_enseignant_dim) REFERENCES DIM_ENSEIGNANT(id_enseignant_dim),
    CONSTRAINT FK_FN_MATIERE    FOREIGN KEY (id_matiere_dim)    REFERENCES DIM_MATIERE   (id_matiere_dim),
    CONSTRAINT FK_FN_SESSION    FOREIGN KEY (id_session_dim)    REFERENCES DIM_SESSION   (id_session_dim),
    CONSTRAINT FK_FN_DATE       FOREIGN KEY (ID_DATE)           REFERENCES DIM_DATE      (ID_DATE)
);
GO


-- ======================================================
-- VÉRIFICATION : Lister toutes les tables créées
-- ======================================================
SELECT 
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_CATALOG = 'DW_GestionUniversitaire'
ORDER BY TABLE_NAME;
GO


select * from FAIT_NOTE ;

