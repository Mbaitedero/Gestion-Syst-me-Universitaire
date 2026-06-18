USE GestionUniversitaire ;

SELECT 
    CONCAT('ETU_', e.id_etudiant) AS etu_id,
    e.nom,
    e.prenom,
    e.email,
    e.date_naissance,
    e.telephone,
    e.adresse,
    e.statut,
    e.date_inscription,
    e.id_filiere,
    e.id_niveau,
    f.nom_filiere,
    f.code_filiere,
    n.nom_niveau,
    n.annee_universitaire,
    c.id_matiere,
    c.session,
    c.ann_univ,
    c.valeur_note,
    c.date_evaluation,
    c.commentaire,
    m.code_matiere,
    m.libelle AS libelle_matiere,
    m.coefficient,
    m.semestre
FROM ETUDIANT e
JOIN FILIERE f ON e.id_filiere = f.id_filiere
JOIN NIVEAU n ON e.id_niveau = n.id_niveau
LEFT JOIN COMPOSITION c ON e.id_etudiant = c.id_etudiant
LEFT JOIN MATIERE m ON c.id_matiere = m.id_matiere
ORDER BY e.id_etudiant, c.ann_univ, c.session, c.id_matiere;
-- 1. Liste des étudiants inscrits avec leur filière et leur niveau
-- Objectif :
 -- Obtenir une vue globale de l'effectif étudiant de l'année en cours.

SELECT 
    E.id_etudiant,
    E.nom,
    E.prenom,
    F.nom_filiere,
    N.nom_niveau,
    N.annee_universitaire
FROM ETUDIANT E
JOIN FILIERE F ON E.id_filiere = F.id_filiere
JOIN NIVEAU N ON E.id_niveau = N.id_niveau
WHERE E.statut = 'Actif';

-- 2. Nombre d'étudiants par département
-- Objectif :
--    Statistiques descriptives simples pour analyser la répartition des effectifs.

SELECT 
    D.nom_dept AS Departement,
    COUNT(E.id_etudiant) AS Nombre_Etudiants
FROM DEPARTEMENT D
JOIN FILIERE F ON D.id_departement = F.id_departement
JOIN ETUDIANT E ON F.id_filiere = E.id_filiere
GROUP BY D.id_departement, D.nom_dept
ORDER BY Nombre_Etudiants DESC;

-- 3. Liste des matières enseignées par un enseignant spécifique

-- Objectif :
 -- Retrouver la charge pédagogique d'un enseignant (remplace `'Nom_Enseignant'` par la valeur voulue).

SELECT DISTINCT
    ENS.nom,
    ENS.prenom,
    M.code_matiere,
    M.libelle AS Matiere,
    F.nom_filiere,
    N.nom_niveau
FROM ENSEIGNEMENT EM
JOIN ENSEIGNANT ENS ON EM.id_enseignant = ENS.id_enseignant
JOIN MATIERE M ON EM.id_matiere = M.id_matiere
JOIN FILIERE F ON EM.id_filiere = F.id_filiere
JOIN NIVEAU N ON EM.id_niveau = N.id_niveau
WHERE ENS.nom = 'Rolland';



-- 4. Les notes d'un étudiant particulier pour une année universitaire donnée

-- Objectif :
--  Relevé de notes individuel brut pour un étudiant via son ID.

SELECT 
    M.code_matiere,
    M.libelle AS Matiere,
    C.session,
    C.valeur_note AS Note,
    C.commentaire
FROM COMPOSITION C
JOIN MATIERE M ON C.id_matiere = M.id_matiere
WHERE C.id_etudiant = 1 AND C.ann_univ = '2025-2026'
ORDER BY M.semestre, M.code_matiere;

-- 5. Calcul de la moyenne pondérée d'un étudiant
-- Objectif :
 -- Appliquer les coefficients des matières pour calculer la moyenne exacte d'une session.

SELECT 
    C.id_etudiant,
    C.ann_univ,
    C.session,
    ROUND(SUM(C.valeur_note * M.coefficient) / SUM(M.coefficient),2) AS Moyenne_Ponderee
FROM COMPOSITION C
JOIN MATIERE M ON C.id_matiere = M.id_matiere
WHERE C.id_etudiant = 1 AND C.ann_univ = '2025-2026' AND C.session = 'Normale'
GROUP BY C.id_etudiant, C.ann_univ, C.session;

--  6. Liste des étudiants qui doivent passer le rattrapage (Note < 10)

-- Objectif 
 -- Identifier rapidement les élèves en situation d'échec sur la session normale.

SELECT 
    E.id_etudiant,
    E.nom,
    E.prenom,
    M.libelle AS Matiere_A_Rattraper,
    C.valeur_note AS Note_Initiale
FROM COMPOSITION C
JOIN ETUDIANT E ON C.id_etudiant = E.id_etudiant
JOIN MATIERE M ON C.id_matiere = M.id_matiere
WHERE C.session = 'Normale' AND C.valeur_note < 10.00 AND C.ann_univ = '2025-2026';

-- 7. Moyenne générale, note maximale et note minimale par matière
-- Objectif :
 -- Analyser la difficulté des évaluations selon les matières.


SELECT 
    M.code_matiere,
    M.libelle AS Matiere,
    ROUND(AVG(C.valeur_note), 2) AS Moyenne_Classe,
    MAX(C.valeur_note) AS Note_Max,
    MIN(C.valeur_note) AS Note_Min,
    COUNT(C.id_etudiant) AS Nombre_Participants
FROM COMPOSITION C
JOIN MATIERE M ON C.id_matiere = M.id_matiere
WHERE C.session = 'Normale' AND C.ann_univ = '2025-2026'
GROUP BY M.id_matiere, M.code_matiere, M.libelle;


-- 8. Le "Major de promotion" (Meilleure moyenne) pour chaque filière

-- Objectif :
-- Extraire l'étudiant ayant la plus haute moyenne pondérée par filière (Requête avancée utilisant une sous-requête).

SELECT 
    Filiere,
    Nom_Etudiant,
    Prenom_Etudiant,
    MAX(Moyenne) AS Meilleure_Moyenne
FROM (
    SELECT 
        F.nom_filiere AS Filiere,
        E.nom AS Nom_Etudiant,
        E.prenom AS Prenom_Etudiant,
        ROUND(SUM(C.valeur_note * M.coefficient) / SUM(M.coefficient),2) AS Moyenne
    FROM COMPOSITION C
    JOIN ETUDIANT E ON C.id_etudiant = E.id_etudiant
    JOIN FILIERE F ON E.id_filiere = F.id_filiere
    JOIN MATIERE M ON C.id_matiere = M.id_matiere
    WHERE C.session = 'Normale' AND C.ann_univ = '2025-2026'
    GROUP BY Filiere, Nom_Etudiant,Prenom_Etudiant
) AS Classement
GROUP BY Filiere, Nom_Etudiant,Prenom_Etudiant;


 
-- 9. Volume horaire total dispensé par filière et par niveau
-- Objectif :
--   Calculer la charge horaire totale globale reçue par les étudiants d'un parcours donné

SELECT 
    F.nom_filiere,
    N.nom_niveau,
    SUM(M.volume_horaire) AS Volume_Horaire_Total_Heures
FROM ENSEIGNEMENT EM
JOIN FILIERE F ON EM.id_filiere = F.id_filiere
JOIN NIVEAU N ON EM.id_niveau = N.id_niveau
JOIN MATIERE M ON EM.id_matiere = M.id_matiere
GROUP BY  F.nom_filiere,
    N.nom_niveau;

-- 10. Les enseignants qui n'ont aucune heure d'enseignement attribuée
-- Objectif :
--  Contrôle d'intégrité de la base ou gestion des ressources humaines (détection d'enseignants non assignés via un `LEFT JOIN`).

SELECT 
    ENS.id_enseignant,
    ENS.nom,
    ENS.prenom,
    ENS.email
FROM ENSEIGNANT ENS
LEFT JOIN ENSEIGNEMENT EM ON ENS.id_enseignant = EM.id_enseignant
WHERE EM.id_enseignant IS NULL;


    
