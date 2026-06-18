-- ======================================================
-- Nom du projet  : DW_GestionUniversitaire
-- Description    : Vues OLAP pour analyse multidimensionnelle
-- Auteur         : Japhet Allah-N'diguim
-- ======================================================

USE DW_GestionUniversitaire;
GO

-- ======================================================
-- VUE 1 : VW_PERFORMANCE_ETUDIANT
-- Performance globale de chaque étudiant
-- ======================================================
CREATE OR ALTER VIEW VW_PERFORMANCE_ETUDIANT AS
SELECT
    e.id_etudiant_source,
    e.nom_complet,
    e.statut,
    e.tranche_age,
    f.nom_filiere,
    f.nom_departement,
    n.nom_niveau,
    n.annee_universitaire,
    s.code_session,
    COUNT(fn.id_fait_note)                          AS nb_matieres,
    AVG(fn.note_obtenue)                            AS moyenne_generale,
    MIN(fn.note_obtenue)                            AS note_min,
    MAX(fn.note_obtenue)                            AS note_max,
    SUM(fn.note_ponderee)                           AS total_points_ponderes,
    SUM(fn.coefficient_applique)                    AS total_coefficients,
    SUM(fn.note_ponderee) / SUM(fn.coefficient_applique) AS moyenne_ponderee,
    COUNT(CASE WHEN fn.note_obtenue >= 10 THEN 1 END) AS nb_matieres_validees,
    COUNT(CASE WHEN fn.note_obtenue < 10  THEN 1 END) AS nb_matieres_echouees,
    CASE 
        WHEN SUM(fn.note_ponderee)/SUM(fn.coefficient_applique) >= 16 THEN 'Très Bien'
        WHEN SUM(fn.note_ponderee)/SUM(fn.coefficient_applique) >= 14 THEN 'Bien'
        WHEN SUM(fn.note_ponderee)/SUM(fn.coefficient_applique) >= 12 THEN 'Assez Bien'
        WHEN SUM(fn.note_ponderee)/SUM(fn.coefficient_applique) >= 10 THEN 'Passable'
        ELSE 'Insuffisant'
    END AS mention
FROM FAIT_NOTE fn
JOIN DIM_ETUDIANT   e ON fn.id_etudiant_dim  = e.id_etudiant_dim
JOIN DIM_FILIERE    f ON fn.id_filiere_dim   = f.id_filiere_dim
JOIN DIM_NIVEAU     n ON fn.id_niveau_dim    = n.id_niveau_dim
JOIN DIM_SESSION    s ON fn.id_session_dim   = s.id_session_dim
GROUP BY
    e.id_etudiant_source, e.nom_complet, e.statut, e.tranche_age,
    f.nom_filiere, f.nom_departement,
    n.nom_niveau, n.annee_universitaire,
    s.code_session;
GO

-- ======================================================
-- VUE 2 : VW_PERFORMANCE_FILIERE
-- Analyse des performances par filière
-- ======================================================
CREATE OR ALTER VIEW VW_PERFORMANCE_FILIERE AS
SELECT
    f.nom_filiere,
    f.nom_departement,
    f.responsable_departement,
    n.nom_niveau,
    n.annee_universitaire,
    s.code_session,
    COUNT(DISTINCT fn.id_etudiant_dim)              AS nb_etudiants,
    COUNT(fn.id_fait_note)                          AS nb_evaluations,
    AVG(fn.note_obtenue)                            AS moyenne_filiere,
    MIN(fn.note_obtenue)                            AS note_min,
    MAX(fn.note_obtenue)                            AS note_max,
    SUM(fn.note_ponderee)/SUM(fn.coefficient_applique) AS moyenne_ponderee,
    COUNT(CASE WHEN fn.note_obtenue >= 10 THEN 1 END) AS nb_reussites,
    COUNT(CASE WHEN fn.note_obtenue <  10 THEN 1 END) AS nb_echecs,
    CAST(COUNT(CASE WHEN fn.note_obtenue >= 10 THEN 1 END) * 100.0 
         / COUNT(fn.id_fait_note) AS DECIMAL(5,2))  AS taux_reussite
FROM FAIT_NOTE fn
JOIN DIM_FILIERE  f ON fn.id_filiere_dim = f.id_filiere_dim
JOIN DIM_NIVEAU   n ON fn.id_niveau_dim  = n.id_niveau_dim
JOIN DIM_SESSION  s ON fn.id_session_dim = s.id_session_dim
GROUP BY
    f.nom_filiere, f.nom_departement, f.responsable_departement,
    n.nom_niveau, n.annee_universitaire, s.code_session;
GO

-- ======================================================
-- VUE 3 : VW_PERFORMANCE_MATIERE
-- Analyse des performances par matière
-- ======================================================
CREATE OR ALTER VIEW VW_PERFORMANCE_MATIERE AS
SELECT
    m.code_matiere,
    m.libelle                                       AS matiere,
    m.semestre,
    m.coefficient,
    m.volume_horaire,
    en.nom_complet                                  AS enseignant,
    en.grade,
    f.nom_filiere,
    n.nom_niveau,
    s.code_session,
    COUNT(DISTINCT fn.id_etudiant_dim)              AS nb_etudiants,
    AVG(fn.note_obtenue)                            AS moyenne_matiere,
    MIN(fn.note_obtenue)                            AS note_min,
    MAX(fn.note_obtenue)                            AS note_max,
    STDEV(fn.note_obtenue)                          AS ecart_type,
    COUNT(CASE WHEN fn.note_obtenue >= 16 THEN 1 END) AS nb_tres_bien,
    COUNT(CASE WHEN fn.note_obtenue >= 14 
               AND fn.note_obtenue < 16 THEN 1 END) AS nb_bien,
    COUNT(CASE WHEN fn.note_obtenue >= 12 
               AND fn.note_obtenue < 14 THEN 1 END) AS nb_assez_bien,
    COUNT(CASE WHEN fn.note_obtenue >= 10 
               AND fn.note_obtenue < 12 THEN 1 END) AS nb_passable,
    COUNT(CASE WHEN fn.note_obtenue < 10  THEN 1 END) AS nb_echecs,
    CAST(COUNT(CASE WHEN fn.note_obtenue >= 10 THEN 1 END) * 100.0
         / COUNT(fn.id_fait_note) AS DECIMAL(5,2))  AS taux_reussite
FROM FAIT_NOTE fn
JOIN DIM_MATIERE    m  ON fn.id_matiere_dim   = m.id_matiere_dim
JOIN DIM_ENSEIGNANT en ON fn.id_enseignant_dim = en.id_enseignant_dim
JOIN DIM_FILIERE    f  ON fn.id_filiere_dim    = f.id_filiere_dim
JOIN DIM_NIVEAU     n  ON fn.id_niveau_dim     = n.id_niveau_dim
JOIN DIM_SESSION    s  ON fn.id_session_dim    = s.id_session_dim
GROUP BY
    m.code_matiere, m.libelle, m.semestre, m.coefficient, m.volume_horaire,
    en.nom_complet, en.grade,
    f.nom_filiere, n.nom_niveau, s.code_session;
GO

-- ======================================================
-- VUE 4 : VW_PERFORMANCE_ENSEIGNANT
-- Analyse des performances par enseignant
-- ======================================================
CREATE OR ALTER VIEW VW_PERFORMANCE_ENSEIGNANT AS
SELECT
    en.nom_complet                                  AS enseignant,
    en.grade,
    en.anciennete_annees,
    m.libelle                                       AS matiere,
    f.nom_filiere,
    n.nom_niveau,
    s.code_session,
    COUNT(DISTINCT fn.id_etudiant_dim)              AS nb_etudiants,
    AVG(fn.note_obtenue)                            AS moyenne_classe,
    CAST(COUNT(CASE WHEN fn.note_obtenue >= 10 THEN 1 END) * 100.0
         / COUNT(fn.id_fait_note) AS DECIMAL(5,2))  AS taux_reussite,
    MIN(fn.note_obtenue)                            AS note_min,
    MAX(fn.note_obtenue)                            AS note_max
FROM FAIT_NOTE fn
JOIN DIM_ENSEIGNANT en ON fn.id_enseignant_dim = en.id_enseignant_dim
JOIN DIM_MATIERE    m  ON fn.id_matiere_dim    = m.id_matiere_dim
JOIN DIM_FILIERE    f  ON fn.id_filiere_dim    = f.id_filiere_dim
JOIN DIM_NIVEAU     n  ON fn.id_niveau_dim     = n.id_niveau_dim
JOIN DIM_SESSION    s  ON fn.id_session_dim    = s.id_session_dim
GROUP BY
    en.nom_complet, en.grade, en.anciennete_annees,
    m.libelle, f.nom_filiere, n.nom_niveau, s.code_session;
GO

-- ======================================================
-- VUE 5 : VW_ANALYSE_TEMPORELLE
-- Évolution des performances dans le temps
-- ======================================================
CREATE OR ALTER VIEW VW_ANALYSE_TEMPORELLE AS
SELECT
    d.annee_universitaire,
    d.semestre_univ,
    d.mois,
    d.trimestre,
    f.nom_filiere,
    n.nom_niveau,
    s.code_session,
    COUNT(DISTINCT fn.id_etudiant_dim)              AS nb_etudiants,
    COUNT(fn.id_fait_note)                          AS nb_evaluations,
    AVG(fn.note_obtenue)                            AS moyenne_periode,
    CAST(COUNT(CASE WHEN fn.note_obtenue >= 10 THEN 1 END) * 100.0
         / COUNT(fn.id_fait_note) AS DECIMAL(5,2))  AS taux_reussite
FROM FAIT_NOTE fn
JOIN DIM_DATE    d ON fn.ID_DATE         = d.ID_DATE
JOIN DIM_FILIERE f ON fn.id_filiere_dim  = f.id_filiere_dim
JOIN DIM_NIVEAU  n ON fn.id_niveau_dim   = n.id_niveau_dim
JOIN DIM_SESSION s ON fn.id_session_dim  = s.id_session_dim
GROUP BY
    d.annee_universitaire, d.semestre_univ, d.mois, d.trimestre,
    f.nom_filiere, n.nom_niveau, s.code_session;
GO

-- ======================================================
-- VUE 6 : VW_COMPARAISON_SESSIONS
-- Comparaison Normale vs Rattrapage
-- ======================================================
CREATE OR ALTER VIEW VW_COMPARAISON_SESSIONS AS
SELECT
    e.nom_complet                                   AS etudiant,
    m.libelle                                       AS matiere,
    f.nom_filiere,
    n.nom_niveau,
    MAX(CASE WHEN s.code_session = 'Normale'    THEN fn.note_obtenue END) AS note_normale,
    MAX(CASE WHEN s.code_session = 'Rattrapage' THEN fn.note_obtenue END) AS note_rattrapage,
    MAX(CASE WHEN s.code_session = 'Rattrapage' THEN fn.note_obtenue END) -
    MAX(CASE WHEN s.code_session = 'Normale'    THEN fn.note_obtenue END) AS progression,
    CASE
        WHEN MAX(CASE WHEN s.code_session = 'Rattrapage' THEN fn.note_obtenue END) IS NULL
        THEN 'Pas de rattrapage'
        WHEN MAX(CASE WHEN s.code_session = 'Rattrapage' THEN fn.note_obtenue END) >=
             MAX(CASE WHEN s.code_session = 'Normale'    THEN fn.note_obtenue END)
        THEN 'Progression'
        ELSE 'Régression'
    END AS statut_rattrapage
FROM FAIT_NOTE fn
JOIN DIM_ETUDIANT e ON fn.id_etudiant_dim = e.id_etudiant_dim
JOIN DIM_MATIERE  m ON fn.id_matiere_dim  = m.id_matiere_dim
JOIN DIM_FILIERE  f ON fn.id_filiere_dim  = f.id_filiere_dim
JOIN DIM_NIVEAU   n ON fn.id_niveau_dim   = n.id_niveau_dim
JOIN DIM_SESSION  s ON fn.id_session_dim  = s.id_session_dim
GROUP BY
    e.nom_complet, m.libelle, f.nom_filiere, n.nom_niveau;
GO

-- ======================================================
-- TEST DES VUES
-- ======================================================
SELECT TOP 5 * FROM VW_PERFORMANCE_ETUDIANT   ORDER BY moyenne_ponderee DESC;
SELECT TOP 5 * FROM VW_PERFORMANCE_FILIERE    ORDER BY taux_reussite DESC;
SELECT TOP 5 * FROM VW_PERFORMANCE_MATIERE    ORDER BY moyenne_matiere DESC;
SELECT TOP 5 * FROM VW_PERFORMANCE_ENSEIGNANT ORDER BY taux_reussite DESC;
SELECT  * FROM VW_ANALYSE_TEMPORELLE;
SELECT  * FROM VW_COMPARAISON_SESSIONS   WHERE note_rattrapage IS NOT NULL;
GO