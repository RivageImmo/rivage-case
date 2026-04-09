# Cas pratique — Développeur Fullstack

## La page de suivi des propriétaires

**Durée : 1h à 1h30 (travail) + 30 min (restitution orale)**

---

## 1. Introduction à Rivage

Rivage est un logiciel de gestion locative axé sur la comptabilité, destiné aux agences immobilières. Notre plateforme permet aux gestionnaires et comptables de gérer l'intégralité du cycle de vie d'un bien en location : de l'entrée du locataire jusqu'à la restitution de son dépôt de garantie, en passant par l'encaissement des loyers, le paiement des charges et la rémunération des propriétaires.

Nos clients sont des agences immobilières de tailles variées (de 50 à 2 000 lots gérés) qui utilisent Rivage au quotidien pour automatiser et fiabiliser leurs opérations financières. Leurs utilisateurs principaux sont les gestionnaires locatifs, les comptables d'agence et les directeurs d'agence.

---

## 2. Contexte et problématique

### Le cycle financier d'une agence

Pour comprendre le problème, il est essentiel de comprendre le flux financier mensuel d'une agence de gestion locative :

**Étape 1 — Encaissement des loyers.** Chaque mois, l'agence encaisse les loyers des locataires. L'encaissement peut se faire par prélèvement SEPA, par virement bancaire, ou par chèque. Certains locataires bénéficient d'aides (CAF, Action Logement) versées directement à l'agence.

**Étape 2 — Déductions et retenues.** Avant de reverser quoi que ce soit au propriétaire, l'agence déduit : les honoraires de gestion (5% à 10% HT du loyer), les factures fournisseurs en attente (plombier, travaux, syndic), les restitutions de dépôts de garantie, et les éventuelles provisions.

**Étape 3 — Versement au propriétaire.** Le solde restant après déductions est versé au propriétaire. La date et la logique de versement varient : date fixe agence (ex : le 10 du mois), date préférée du propriétaire, ou versement rapide (J+1).

### Le problème aujourd'hui

Les gestionnaires et comptables n'ont pas de vision claire de la situation financière de chaque propriétaire. Concrètement :

- **Manque de visibilité globale.** Il est difficile de voir en un coup d'œil quels propriétaires posent problème : impayés, solde négatif, lot vacant, bail qui expire, versement bloqué.

- **Difficulté à expliquer une situation.** Quand un propriétaire appelle pour comprendre pourquoi il a reçu moins que prévu (ou rien du tout), le gestionnaire doit reconstituer manuellement la situation en naviguant entre plusieurs écrans. C'est lent, source d'erreurs, et frustrant.

- **Risque d'erreurs et d'oublis.** Sans vision consolidée, l'agence risque d'oublier un versement, de ne pas détecter un impayé à temps, ou de ne pas anticiper un départ de locataire.

- **Gestion des cas particuliers.** Certains propriétaires ont des situations complexes : SCI avec plusieurs biens, versements temporairement désactivés, factures supérieures aux loyers (propriétaire débiteur), baux commerciaux, co-locations. Ces cas sont mal gérés et génèrent des oublis.

### Messages internes

Avant de commencer, voici trois messages reçus cette semaine à propos de ce projet :

**Message de Claire — Gestionnaire locative**

> *Ce qui me manque le plus c'est de voir en un coup d'œil quels propriétaires posent problème. J'en gère 40, chacun avec un ou plusieurs biens. Quand M. Bernard de la SCI Les Oliviers m'appelle, je dois naviguer entre 5 écrans pour reconstituer sa situation : ses 3 biens, le lot vacant, le bail commercial, les loyers encaissés. J'aimerais voir tout ça sur un seul écran.*

**Message de Thomas — Directeur de l'agence**

> *Je veux pouvoir scanner la liste de nos propriétaires et voir immédiatement lesquels ont un problème : un impayé, un lot vacant depuis trop longtemps, un bail qui expire sans qu'on ait préparé la suite, un versement bloqué. Aujourd'hui on découvre les problèmes quand le propriétaire appelle pour se plaindre. C'est trop tard.*

**Message de Nathalie — Comptable mandant**

> *Pour moi l'important c'est de distinguer vite les cas simples des cas compliqués. 80% de mes propriétaires, tout va bien : le locataire a payé, je déduis mes honoraires, je reverse. Mais les 20% restants me prennent 80% du temps : les propriétaires débiteurs à cause de grosses factures, les impayés partiels avec la CAF qui paie mais pas le locataire, les versements que j'ai bloqués en attendant la fin de travaux.*

---

## 3. Ta mission

Tu disposes d'une application Rails fonctionnelle avec des données réalistes et un design system prêt à l'emploi.

**Construis la page qui permettra aux équipes de l'agence de connaître facilement la situation de chaque propriétaire, d'avoir une vision globale de l'ensemble des propriétaires, et d'identifier rapidement les situations qui nécessitent une action.**

Plus précisément, la solution doit permettre de :

### 3.1 Vision globale des propriétaires

Offrir une vue d'ensemble de tous les propriétaires gérés par l'agence, permettant de comprendre immédiatement :
- Quels propriétaires présentent une alerte ou une anomalie
- Quels propriétaires ont des impayés sur leurs biens
- Quels propriétaires ont des lots vacants
- Quels propriétaires ont des baux qui arrivent à échéance

### 3.2 Situation détaillée d'un propriétaire

Permettre à un gestionnaire de zoomer sur un propriétaire spécifique et de comprendre instantanément :
- Ses biens : combien, lesquels sont occupés, lesquels sont vacants
- Ses baux : type (résidentiel, commercial), locataires, loyers, statut des paiements
- Son solde : les encaissements, les déductions (honoraires, factures), le montant net
- Les alertes : impayés, baux expirants, factures importantes, versement bloqué
- Ses préférences : date de versement, taux d'honoraires, statut du versement

**L'enjeu clé : un gestionnaire doit pouvoir expliquer la situation à un propriétaire qui appelle, en quelques secondes.**

### 3.3 Paramètres à prendre en compte

Les propriétaires et l'agence disposent de paramètres qui influencent la situation :

**Au niveau de l'agence (règle par défaut)** : date de versement par défaut (le 10), taux d'honoraires par défaut (7%).

**Au niveau du propriétaire (exception)** : date de versement préférée, taux d'honoraires négocié, versement actif ou désactivé (avec motif).

---

## 4. Ce qui est déjà en place

### Application

- Application Rails + React avec PostgreSQL, dockerisée
- Design system complet (classes CSS utilitaires, composants SCSS)
- Composants React partagés (DataTable, Badge, CurrencyAmount, Button, Tabs, Icons)
- Hook `useApi` pour appeler les endpoints API
- Sidebar avec navigation, page vide à compléter
- Base de données seedée avec des données réalistes (8 propriétaires, 12 biens, 12 baux)

### Fichier à modifier

```
app/frontend/react/dashboard/App.tsx
```

Ce fichier contient un composant React vide avec la documentation de tous les outils à ta disposition.

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
| Construction | 45-60 min | Code ta solution dans `App.tsx` |
| **Restitution** | **30 min** | **Présente tes choix et ton travail à l'équipe** |

### Restitution (30 min)

Tu présenteras ton travail en direct. Nous attendons :
- **Ta compréhension du problème** : comment tu as analysé le sujet, quels problèmes tu as identifiés comme prioritaires
- **Tes choix de priorisation** : pourquoi tu as choisi de traiter certains aspects plutôt que d'autres
- **Ton prototype** : ce que tu as construit, comment ça marche
- **Les limites et évolutions** : ce que tu n'as pas eu le temps de faire, ce que tu aurais fait avec plus de temps

---

## 6. Contraintes

1. L'interface est desktop uniquement
2. Le design system et les composants sont fournis — utilise-les
3. Tu peux ajouter de nouveaux endpoints API si nécessaire (dans `app/controllers/api/`)
4. Tu peux créer de nouveaux composants React si nécessaire
5. Pas d'appel à des APIs externes
6. Le sujet est volontairement large. On n'attend pas que tu traites chaque détail. On évaluera ta capacité à prioriser les problèmes et structurer ton approche.

---

## 7. Lancement

```bash
docker compose up
```

L'application est accessible sur `http://localhost:3000`.

Les API sont accessibles directement dans le navigateur (ex : `http://localhost:3000/api/landlords`).

Le hot-reload est actif : les modifications dans `App.tsx` sont reflétées immédiatement.

---

Bon courage !
