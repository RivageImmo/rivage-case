# Cas pratique — Développeur Fullstack

## Le tableau de bord de suivi du portefeuille locatif

**Durée : 1h30 (travail) + 30 min (restitution orale)**

---

## 1. Introduction

Rivage est un logiciel de gestion locative axé sur la comptabilité, destiné aux agences immobilières. Notre plateforme permet aux gestionnaires et comptables de gérer l'intégralité du cycle de vie d'un bien en location : de l'entrée du locataire jusqu'à la restitution de son dépôt de garantie, en passant par l'encaissement des loyers, le paiement des charges et la rémunération des propriétaires.

Nos clients sont des agences immobilières de tailles variées (de 50 à 2 000 lots gérés). Leurs utilisateurs principaux sont les gestionnaires locatifs, les comptables d'agence et les directeurs d'agence.

---

## 2. Contexte et problématique

Aujourd'hui, les gestionnaires locatifs n'ont aucune vue consolidée de l'état de leur portefeuille. Quand ils arrivent le matin, ils doivent naviguer bail par bail pour comprendre ce qui se passe : qui a payé, qui n'a pas payé, quel bail arrive à échéance, quel propriétaire a un problème. Ce travail de triage prend 15 à 30 minutes chaque jour et est source d'oublis.

Les propriétaires appellent régulièrement pour connaître la situation de leurs biens. Le gestionnaire doit alors reconstituer manuellement les informations en naviguant entre plusieurs écrans — c'est lent, source d'erreurs, et frustrant pour tout le monde.

### Messages internes

Avant de commencer, voici trois messages reçus cette semaine à propos de ce projet :

**Message de Claire — Gestionnaire locative**

> *Ce qui me manque le plus c'est de voir en un coup d'œil quels baux posent problème. Le matin j'arrive, j'ai 180 baux à gérer. Je voudrais savoir tout de suite : qui n'a pas payé, quel bail se termine bientôt, quel propriétaire attend son versement. Aujourd'hui je navigue bail par bail et ça prend une heure juste pour comprendre où j'en suis.*

**Message de Thomas — Directeur de l'agence**

> *Les gestionnaires perdent trop de temps sur le suivi. Mais ce qui m'inquiète surtout c'est les oublis : un bail qui expire sans qu'on ait préparé la sortie, un impayé qu'on ne relance pas à temps, un propriétaire qu'on oublie de payer. Je veux un système qui remonte les alertes automatiquement. Et je veux pouvoir voir le portefeuille global pour savoir comment se porte l'agence.*

**Message de Nathalie — Comptable mandant**

> *Pour moi l'important c'est les chiffres. Je veux savoir : combien on a encaissé ce mois-ci, combien reste à encaisser, quel est le montant total des versements à faire, et est-ce qu'on a la trésorerie pour. Les gestionnaires veulent des tableaux de bord visuels, moi je veux des chiffres justes et fiables.*

---

## 3. Ta mission

Tu disposes d'une application Rails fonctionnelle avec des données réalistes et un design system prêt à l'emploi.

**Construis le tableau de bord qui permettra aux équipes de l'agence de piloter leur portefeuille locatif au quotidien.**

Le sujet est volontairement large. Claire, Thomas et Nathalie n'ont pas les mêmes besoins. Les données contiennent des cas simples et des cas complexes. Tu ne pourras pas tout traiter.

On attend de toi que tu :
1. **Comprennes le domaine** en parcourant la documentation dans `resources/`
2. **Fasses des choix** sur ce qui est prioritaire à afficher et pour qui
3. **Construises un prototype fonctionnel** qui illustre tes choix

---

## 4. Ce qui est déjà en place

### Application

- Application Rails + React avec PostgreSQL, dockerisée
- Design system complet (classes CSS utilitaires, composants SCSS)
- Composants React partagés (DataTable, Badge, CurrencyAmount, Button, Tabs, Icons)
- Hook `useApi` pour appeler les endpoints API
- Sidebar avec navigation, page "Tableau de bord" vide à compléter
- Base de données seedée avec des données réalistes

### Fichier à modifier

```
app/frontend/react/dashboard/App.tsx
```

Ce fichier contient un composant React vide avec la documentation de tous les outils à ta disposition (composants, classes CSS, endpoints API).

### Endpoints API disponibles

```
GET /api/stats           — KPIs globaux (taux d'occupation, impayés, factures, etc.)
GET /api/landlords       — Liste des propriétaires avec stats agrégées
GET /api/landlords/:id   — Détail d'un propriétaire (biens, baux, paiements, factures)
GET /api/leases          — Liste de tous les baux avec statut et balance
GET /api/leases/:id      — Détail d'un bail avec historique de paiements
GET /api/properties      — Liste des biens avec info d'occupation
GET /api/invoices        — Liste des factures fournisseurs
```

### Documentation

Le dossier `resources/` contient 10 documents sur le métier de la gestion locative. **Tu n'es pas obligé de tout lire.** À toi de déterminer ce qui est utile pour ton travail.

---

## 5. Déroulement

| Phase | Durée suggérée | Description |
|-------|---------------|-------------|
| Découverte | 15-20 min | Parcours la documentation, explore les API (dans le navigateur ou via `curl`), comprends les données |
| Construction | 45-60 min | Code ton tableau de bord dans `App.tsx` |
| **Restitution** | **30 min** | **Présente tes choix et ton travail à l'équipe** |

### Restitution (30 min)

Tu présenteras ton travail en direct. Nous attendons :
- **Ta compréhension du problème** : comment tu as analysé le sujet, quels besoins tu as identifiés
- **Tes choix de priorisation** : à quel utilisateur tu t'es adressé, pourquoi tu as choisi de montrer certaines informations plutôt que d'autres
- **Ton prototype** : ce que tu as construit, comment ça marche
- **Les limites et évolutions** : ce que tu n'as pas eu le temps de faire, ce que tu aurais fait avec plus de temps

---

## 6. Contraintes

1. L'interface est desktop uniquement
2. Le design system et les composants sont fournis — utilise-les
3. Tu peux ajouter de nouveaux endpoints API si nécessaire (dans `app/controllers/api/`)
4. Tu peux créer de nouveaux composants React si nécessaire
5. Pas d'appel à des APIs externes

---

## 7. Lancement

```bash
docker compose up
```

L'application est accessible sur `http://localhost:3000`.

Les API sont accessibles directement dans le navigateur (ex : `http://localhost:3000/api/stats`).

Le hot-reload est actif : les modifications dans `App.tsx` sont reflétées immédiatement.

---

Bon courage !
