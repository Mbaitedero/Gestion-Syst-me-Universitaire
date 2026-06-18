-- ======================================================
-- Nom du projet : GestionUniversitaire
-- Description : Système complet de gestion des études
-- Auteur  : Japhet Allah-N'diguim
-- ======================================================

CREATE DATABASE IF NOT EXISTS GestionUniversitaire;
USE GestionUniversitaire;

CREATE TABLE IF NOT EXISTS DEPARTEMENT (
    id_departement INT PRIMARY KEY AUTO_INCREMENT,
    nom_dept       VARCHAR(100) NOT NULL,
    responsable    VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS FILIERE (
    id_filiere     INT PRIMARY KEY AUTO_INCREMENT,
    nom_filiere    VARCHAR(100) NOT NULL,
    code_filiere   VARCHAR(20)  NOT NULL UNIQUE,
    id_departement INT NOT NULL,
    FOREIGN KEY (id_departement) REFERENCES DEPARTEMENT(id_departement)
);

CREATE TABLE IF NOT EXISTS NIVEAU (
    id_niveau           INT PRIMARY KEY AUTO_INCREMENT,
    nom_niveau          VARCHAR(50) NOT NULL,
    annee_universitaire VARCHAR(20) NOT NULL
   );
   
CREATE TABLE IF NOT exists  FILIERE_NIVEAU(
    id_filiere    INT,  
    id_niveau  INT ,
    primary key(id_filiere,  id_niveau),
    foreign key(id_filiere)  references FILIERE(id_filiere),
    foreign key(id_niveau)  references NIVEAU(id_niveau)
    );
    

CREATE TABLE IF NOT EXISTS ETUDIANT (
    id_etudiant      INT PRIMARY KEY AUTO_INCREMENT,
    nom              VARCHAR(50)  NOT NULL,
    prenom           VARCHAR(50)  NOT NULL,
    date_naissance   DATE         NOT NULL,
    email            VARCHAR(100) UNIQUE NOT NULL,
    telephone        VARCHAR(20),
    adresse          TEXT,
    statut           VARCHAR(30)  DEFAULT 'Actif',
    date_inscription DATE         DEFAULT (CURRENT_DATE),
    id_filiere       INT NOT NULL,  
    id_niveau       INT NOT NULL, 
    FOREIGN KEY (id_filiere) REFERENCES FILIERE(id_filiere),
    FOREIGN KEY (id_niveau) REFERENCES NIVEAU(id_niveau)
);

CREATE TABLE IF NOT EXISTS ENSEIGNANT (
    id_enseignant INT PRIMARY KEY AUTO_INCREMENT,
    nom           VARCHAR(50)  NOT NULL,
    prenom        VARCHAR(50)  NOT NULL,
    email         VARCHAR(100) UNIQUE NOT NULL,
    grade         VARCHAR(50),
    date_embauche DATE
);

CREATE TABLE IF NOT EXISTS MATIERE (
    id_matiere     INT PRIMARY KEY AUTO_INCREMENT,
    code_matiere   VARCHAR(20)  UNIQUE NOT NULL,
    libelle        VARCHAR(100) NOT NULL,
    semestre       VARCHAR(10)  NOT NULL,
    coefficient    DECIMAL(3,2) DEFAULT 1.00,
    volume_horaire INT          NOT NULL
);

-- Relation ternaire ENSEIGNER : ENSEIGNANT enseigne Une   MATIERE dans Une  FILIERE
CREATE TABLE IF NOT EXISTS ENSEIGNEMENT (
    id_enseignant INT NOT NULL,
    id_filiere    INT NOT NULL,
    id_matiere    INT NOT NULL,
    id_niveau    INT NOT NULL,
    PRIMARY KEY (id_enseignant, id_filiere, id_matiere, id_niveau),
    FOREIGN KEY (id_enseignant) REFERENCES ENSEIGNANT(id_enseignant) ON DELETE CASCADE,
    FOREIGN KEY (id_filiere)    REFERENCES FILIERE(id_filiere)       ON DELETE RESTRICT,
    FOREIGN KEY (id_matiere)    REFERENCES MATIERE(id_matiere)       ON DELETE RESTRICT,
    FOREIGN KEY (id_niveau) REFERENCES NIVEAU(id_niveau) ON DELETE RESTRICT
);

-- Relation COMPOSER : ETUDIANT passe des évaluations sur des MATIERES
CREATE TABLE IF NOT EXISTS COMPOSITION (
    id_etudiant     INT          NOT NULL,
    id_matiere      INT          NOT NULL,
    session         VARCHAR(20)  NOT NULL,
    ann_univ        VARCHAR(20)  NOT NULL,
    valeur_note     DECIMAL(4,2) CHECK (valeur_note BETWEEN 0 AND 20),
    date_evaluation DATE         DEFAULT (CURRENT_DATE),
    commentaire     TEXT,
    PRIMARY KEY (id_etudiant, id_matiere, session, ann_univ),
    FOREIGN KEY (id_etudiant) REFERENCES ETUDIANT(id_etudiant) ON DELETE CASCADE,
    FOREIGN KEY (id_matiere)  REFERENCES MATIERE(id_matiere)   ON DELETE RESTRICT
);