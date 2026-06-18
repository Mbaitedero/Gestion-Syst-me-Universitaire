//Connexion à la base de données "GestionUniversitaire"
db = db.getSiblingDB("GestionUniversitaire");
//1. Les étudiants qui ont une moyenne supérieure à 17 triés par ordre décroissant de leur moyenne.
db = db.getSiblingDB("GestionUniversitaire");
const result = db.etudiants.aggregate([
  { $group: {
      _id: "$etu_id",
      nom:    { $first: "$nom" },
      prenom: { $first: "$prenom" },
      filiere:{ $first: "$nom_filiere" },
      moyenne:{ $avg:   "$valeur_note" }
  }},
  { $match:  { moyenne: { $gt: 17 } } },
  { $sort:   { moyenne: -1 } },
  { $project: {
      _id: 0,
      Matricule: "$_id",
      Nom:       "$nom",
      Prenom:    "$prenom",
      Filiere:   "$filiere",
      Moyenne:   { $round: ["$moyenne", 2] }
  }}
]).toArray();

// Affichage tableau dans mongosh
print("\nMatricule   | Nom              | Prénom                 | Filière                             | Moyenne");
print("------------|------------------|------------------------|-------------------------------------|--------");
result.forEach(r => {
  print(
    r.Matricule.padEnd(12) + "| " +
    r.Nom.padEnd(17) + "| " +
    r.Prenom.padEnd(20) + "| " +
    r.Filiere.padEnd(38) + "| " +
    r.Moyenne
  );
});

//2. Performance des enseignants par Departement et Filiere
const result2 = db.enseignants.aggregate([
  {
    $lookup: {
      from: "departements",
      localField: "id_filiere",
      foreignField: "id_filiere",
      as: "departement"
    }
  },
  {
    $unwind: "$departement"
  },
  {
    $group: {
      _id: {
        departement: "$departement.nom_dept",
        filiere: "$nom_filiere"
      },
      nb_enseignants: {
        $sum: 1
      }
    }
  },
  {
    $project: {
      _id: 0,
      Departement: "$_id.departement",
      Filiere: "$_id.filiere",
      Nombre_Enseignants: "$nb_enseignants"
    }
  }
]).toArray();

console.table(result2);

//3. Evolution du nombre d'étudiants par année et par filière
const result3 = db.etudiants.aggregate([
  {
    $group: {
      _id: {
        annee: {
          $year: "$date_inscription"
        },
        filiere: "$nom_filiere"
      },
      nombre_etudiants: {
        $addToSet: "$etu_id"
      }
    }
  },
  {
    $project: {
      _id: 0,
      Annee: "$_id.annee",
      Filiere: "$_id.filiere",
      NombreEtudiants: {
        $size: "$nombre_etudiants"
      }
    }
  },
  {
    $sort: {
      Annee: 1,
      Filiere: 1
    }
  }
]).toArray();

console.table(result3);

//4. Performance temporelle des étudiants  par année et par filière
const result4 = db.etudiants.aggregate([
  {
    $group: {
      _id: {
        annee: {
          $year: "$date_evaluation"
        },
        filiere: "$nom_filiere"
      },
      moyenne_generale: {
        $avg: "$valeur_note"
      }
    }
  },
  {
    $project: {
      _id: 0,
      Annee: "$_id.annee",
      Filiere: "$_id.filiere",
      Moyenne: {
        $round: ["$moyenne_generale", 2]
      }
    }
  },
  {
    $sort: {
      Annee: 1,
      Moyenne: -1
    }
  }
]).toArray();

console.table(result4);

//5. Meilleurs étudiants par filière et par année
const result5 = db.etudiants.aggregate([
  {
    $group: {
      _id: {
        etu_id: "$etu_id",
        annee: {
          $year: "$date_evaluation"
        },
        filiere: "$nom_filiere"
      },
      nom: {
        $first: "$nom"
      },
      prenom: {
        $first: "$prenom"
      },
      moyenne: {
        $avg: "$valeur_note"
      }
    }
  },
  {
    $sort: {
      "_id.filiere": 1,
      "_id.annee": 1,
      moyenne: -1
    }
  },
  {
    $group: {
      _id: {
        annee: "$_id.annee",
        filiere: "$_id.filiere"
      },
      meilleurEtudiant: {
        $first: "$nom"
      },
      prenom: {
        $first: "$prenom"
      },
      moyenne: {
        $first: "$moyenne"
      }
    }
  },
  {
    $project: {
      _id: 0,
      Annee: "$_id.annee",
      Filiere: "$_id.filiere",
      Nom: "$meilleurEtudiant",
      Prenom: "$prenom",
      Moyenne: {
        $round: ["$moyenne", 2]
      }
    }
  }
]).toArray();

console.table(result5);

//6. Répartition des étudiants par filière
db = db.getSiblingDB("GestionUniversitaire");

const repartition = db.etudiants.aggregate([
  {
    $group: {
      _id: "$nom_filiere",
      nombre_etudiants: { $addToSet: "$etu_id" }
    }
  },
  {
    $project: {
      _id: 0,
      Filiere: "$_id",
      Nombre_Etudiants: { $size: "$nombre_etudiants" }
    }
  },
  {
    $sort: { Nombre_Etudiants: -1 }
  }
]).toArray();

console.table(repartition);


//7. Taux de réussite par filière

db = db.getSiblingDB("GestionUniversitaire");

const taux = db.etudiants.aggregate([
  // 1. Calcul de la moyenne par étudiant
  {
    $group: {
      _id: {
        etu_id: "$etu_id",
        filiere: "$nom_filiere"
      },
      moyenne: { $avg: "$valeur_note" }
    }
  },

  // 2. Création d'un indicateur de réussite
  {
    $project: {
      filiere: "$_id.filiere",
      est_reussi: {
        $cond: [{ $gte: ["$moyenne", 10] }, 1, 0]
      }
    }
  },

  // 3. Agrégation par filière
  {
    $group: {
      _id: "$filiere",
      total_etudiants: { $sum: 1 },
      total_reussis: { $sum: "$est_reussi" }
    }
  },

  // 4. Calcul du taux
  {
    $project: {
      _id: 0,
      Filiere: "$_id",
      Total_Etudiants: "$total_etudiants",
      Total_Reussis: "$total_reussis",
      Taux_Reussite: {
        $round: [
          {
            $multiply: [
              { $divide: ["$total_reussis", "$total_etudiants"] },
              100
            ]
          },
          2
        ]
      }
    }
  },

  // 5. Tri
  {
    $sort: { Taux_Reussite: -1 }
  }
]).toArray();

console.table(taux);

//8. Top 10 des meilleurs étudiants toutes filières confondues

db = db.getSiblingDB("GestionUniversitaire");

const top10 = db.etudiants.aggregate([
  // 1. Calcul de la moyenne par étudiant
  {
    $group: {
      _id: "$etu_id",
      nom: { $first: "$nom" },
      prenom: { $first: "$prenom" },
      filiere: { $first: "$nom_filiere" },
      moyenne: { $avg: "$valeur_note" }
    }
  },

  // 2. Tri par moyenne décroissante
  {
    $sort: {
      moyenne: -1
    }
  },

  // 3. Limiter au top 10
  {
    $limit: 10
  },

  // 4. Formatage propre
  {
    $project: {
      _id: 0,
      Matricule: "$_id",
      Nom: "$nom",
      Prenom: "$prenom",
      Filiere: "$filiere",
      Moyenne: { $round: ["$moyenne", 2] }
    }
  }
]).toArray();

console.table(top10);


//9. Performance par matière et par semestre

db = db.getSiblingDB("GestionUniversitaire");

const perf = db.etudiants.aggregate([
  // 1. Regroupement par matière et semestre
  {
    $group: {
      _id: {
        matiere: "$libelle_matiere",
        code_matiere: "$code_matiere",
        semestre: "$semestre"
      },
      moyenne: { $avg: "$valeur_note" },
      nombre_notes: { $sum: 1 }
    }
  },

  // 2. Formatage
  {
    $project: {
      _id: 0,
      Matiere: "$_id.matiere",
      Code_Matiere: "$_id.code_matiere",
      Semestre: "$_id.semestre",
      Moyenne: { $round: ["$moyenne", 2] },
      Nombre_Notes: "$nombre_notes"
    }
  },

  // 3. Tri par semestre puis performance
  {
    $sort: {
      Semestre: 1,
      Moyenne: -1
    }
  }
]).toArray();

console.table(perf);

//10. Charge d’enseignement par enseignant

db = db.getSiblingDB("GestionUniversitaire");

const charge = db.enseignants.aggregate([
  // 1. Regrouper par enseignant
  {
    $group: {
      _id: {
        ens_id: "$ens_id",
        nom: "$nom",
        prenom: "$prenom"
      },

      // compter les combinaisons uniques enseignées
      matieres: { $addToSet: "$code_matiere" },
      filieres: { $addToSet: "$nom_filiere" },
      niveaux: { $addToSet: "$nom_niveau" }
    }
  },

  // 2. Calcul des charges
  {
    $project: {
      _id: 0,
      Enseignant: {
        $concat: ["$_id.prenom", " ", "$_id.nom"]
      },
      Nombre_Matieres: { $size: "$matieres" },
      Nombre_Filieres: { $size: "$filieres" },
      Nombre_Niveaux: { $size: "$niveaux" },
      Charge_Totale: {
        $add: [
          { $size: "$matieres" },
          { $size: "$filieres" },
          { $size: "$niveaux" }
        ]
      }
    }
  },

  // 3. Tri par charge décroissante
  {
    $sort: { Charge_Totale: -1 }
  }
]).toArray();

console.table(charge);