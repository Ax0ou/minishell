# Plan de rendu, 21 jours

> Écrit le 08/09/2026. Deadline dure (blackhole) : 29/09/2026.
> Budget Axel : 3 à 4h/jour, soit ~70h. Budget Davi : faible, traité comme capacité d'appoint.
> Ce document remplace `docs/PLAN.md` (calibré 4 semaines, 2 personnes à plein temps).

---

## 0. Constat chiffré

| Mesure | Valeur |
|---|---|
| Premier commit | 26/05/2026 |
| Dernier commit | 28/07/2026 |
| Jours sans commit | 41 |
| Lignes de code dans `src/` | 623 |
| Fichiers `.c` vides sur 52 | 40 |
| Docs rédigées | 9 |
| Issues créées | 55 |
| Commandes exécutées par le binaire à ce jour | 0 |

Le projet a produit environ 6 lignes de C par jour calendaire depuis son démarrage, et 9 documents de process pour un binaire qui n'a jamais lancé `ls`.

Volume restant estimé : 1800 à 2200 lignes de C dans `src/`, soit ~95 lignes/jour sur 21 jours. C'est atteignable à 3-4h/jour, mais uniquement à zéro rework et zéro process superflu.

---

## 1. Les trois décisions prises dans ce plan

### 1.1 Le process passe en mode dégradé

L'infrastructure actuelle (1 issue = 1 branche = 1 PR = 1 review par Davi) a été conçue pour deux personnes à plein temps sur 4 semaines. Avec un binôme peu disponible et une deadline dure, chaque PR en attente de review devient un blocage.

Nouvelles règles, à partir d'aujourd'hui :

| Avant | Maintenant |
|---|---|
| 1 issue = 1 branche = 1 PR = 1 review | Push direct sur `dev`, PR uniquement `dev` vers `main` le dimanche |
| Board à 55 issues | Board filtré sur la semaine en cours, le reste en backlog fermé |
| 4 niveaux de tests, objectif 250 cas | 1 script : `tests/run_all.sh` qui compare minishell à bash |
| Review croisée obligatoire | Lecture croisée uniquement le dimanche, 45 min |

Ce qu'on garde : les commits conventionnels, `Closes #N`, le tag hebdomadaire.

### 1.2 Le chemin critique est 100% sur Axel

Davi ne reçoit que des blocs isolables, sans dépendance vers le reste : `cd`, `export`, `unset`. Ces trois builtins ne dépendent que du module `env/`, qui est terminé. S'il ne les livre pas, tu les écris au jour 13 en 3h et le plan tient quand même.

Aucune tâche du chemin critique (parser, executor, expander, pipes, heredoc, signaux) ne lui est assignée.

### 1.3 Zéro bonus

`&&`, `||`, parenthèses, wildcards : abandonnés. Les issues #53, #54, #55 sont fermées aujourd'hui. Un mandatory propre vaut mieux qu'un bonus qui fait tomber le mandatory.

---

## 2. Dette bloquante à traiter AUJOURD'HUI

Deux problèmes dans le lexer. Ils coûtent 2 à 3h maintenant, ou une réécriture complète du lexer et de l'expander en semaine 2.

### 2.1 Trois variables globales dans `lex_quotes.c`

```c
static t_lex_state  g_state;
static int          g_token_active;
static int          g_has_quotes;
```

Le sujet minishell autorise **une seule** variable globale, et elle ne doit contenir qu'un numéro de signal. Trois statics au scope fichier, préfixées `g_`, seront relevées en soutenance. C'est un motif d'échec, pas une remarque de style.

Correctif : regrouper les trois dans une struct `t_lex` déclarée dans `lex_tokenize()` et passée en paramètre à toutes les fonctions du lexer.

### 2.2 Les quotes sont détruites, l'information de contexte est perdue

Aujourd'hui `lex_handle_quote_char()` retire les quotes du buffer et pose un simple `has_quotes = 1` sur le token.

Prends la ligne suivante :

```
echo abc"$HOME"'$HOME'
```

Le token produit est `abc$HOME$HOME` avec `has_quotes = 1`. L'expander ne peut plus savoir que le premier `$HOME` était en guillemets doubles (à expanser) et le second en guillemets simples (à ne pas expanser). Un booléen sur le token entier ne peut pas porter une information qui varie caractère par caractère.

Correctif : le lexer **conserve les quotes dans la valeur du token**. L'expander les reparcourt en machine à états, expanse hors quotes simples, puis un `strip_quotes` final les retire. C'est l'approche standard à 42 et elle débloque toute la semaine 2.

```
lexer   : echo | abc"$HOME"'$HOME'      (quotes conservées)
expander: echo | abc"/Users/alvrd"'$HOME'
strip   : echo | abc/Users/alvrd$HOME
```

### 2.3 Notes mineures (à traiter en semaine 3, pas maintenant)

- `char buffer[4096]` dans `lex_tokenize()` : débordement silencieux sur ligne longue. Ajouter un garde-fou dans `append_char()`.
- `t_pipeline` n'enveloppe qu'un `t_cmd *`. Wrapper inutile, mais le supprimer maintenant ferait du bruit. À laisser.

---

## 3. Semaine 1 (08 au 14/09) : le shell doit tourner de bout en bout

**Critère de sortie, non négociable :** `ls -la | grep .c > out.txt` fonctionne le 14/09 au soir.

Tant que le binaire n'exécute pas une commande, l'avancement est fictif. Toute la semaine 1 sert à obtenir une tranche verticale qui marche, même incomplète.

| Jour | Date | Bloc | Livrable vérifiable |
|---|---|---|---|
| J1 | lun 08 | Dette lexer (§2.1 + §2.2) | `echo "a b"` produit 2 tokens, quotes conservées, 0 static |
| J2 | mar 09 | Parser : tokens vers `t_cmd` + redirs + validation syntaxique | `ls -la > out` produit 1 cmd, argv à 2, 1 redir OUT |
| J3 | mer 10 | Executor mono-commande : `exec_path`, fork, execve, wait | `ls` s'exécute, `$?` vaut 0, `nawak` renvoie 127 |
| J4 | jeu 11 | Redirections `<` `>` `>>` : open, dup2, restauration | `cat < Makefile > copie` fonctionne |
| J5 | ven 12 | Builtins `echo -n`, `pwd`, `exit` + dispatch builtin/externe | les 4 builtins simples passent, `exit 42` renvoie 42 |
| J6 | sam 13 | Pipes N commandes (`exec_pipeline`) | `ls \| grep c \| wc -l` fonctionne, aucun fd qui traîne |
| J7 | dim 14 | Rattrapage + tests d'intégration + tag `v0.1-e2e` | critère de sortie vert |

**Davi, semaine 1 :** `cd` (avec `PWD`/`OLDPWD`), `export` (avec et sans args, tri alphabétique), `unset`.

### Points de vigilance semaine 1

- **J3 :** `execve` échoue avec `EACCES` (126) et `ENOENT` (127). Ces deux codes tombent en soutenance à chaque fois.
- **J4 :** restaure les fds dans le parent après un builtin redirigé, sinon le prompt suivant écrit dans le fichier.
- **J6 :** ferme les deux extrémités du pipe dans le parent AVANT `wait`, sinon `wc -l` ne reçoit jamais l'EOF et le shell gèle. C'est le bug numéro un de ce projet.

---

## 4. Semaine 2 (15 au 21/09) : expansion, heredoc, signaux

**Critère de sortie :** `cat << EOF | grep "$USER" >> log.txt` fonctionne, Ctrl-C se comporte comme bash.

| Jour | Date | Bloc | Livrable vérifiable |
|---|---|---|---|
| J8 | lun 15 | Expander `$VAR` et `$?` | `echo $HOME`, `echo $?`, `echo $INEXISTANT` (vide) |
| J9 | mar 16 | Expansion selon le type de quote + `strip_quotes` | `echo "$USER"` expanse, `echo '$USER'` non |
| J10 | mer 17 | Intégration expander dans la pipeline complète | `export A=ls && $A` (décider du word splitting, voir plus bas) |
| J11 | jeu 18 | Heredoc `<<` | `cat << EOF`, expansion active sauf si délimiteur quoté |
| J12 | ven 19 | Signaux : `g_signal` unique, `sigaction`, SIGINT, SIGQUIT | Ctrl-C au prompt, dans un enfant, dans un heredoc |
| J13 | sam 20 | Codes de sortie exhaustifs + messages d'erreur bash-like sur stderr | `minishell: cmd: command not found` |
| J14 | dim 21 | Rattrapage + tag `v0.2-complete` | critère de sortie vert |

### Décisions de scope à prendre au J10

- **Word splitting après expansion** (`export A="ls -la"` puis `$A` doit-il donner 2 arguments ?) : le sujet ne l'exige pas explicitement. Coût : environ 3h. **Décision : on ne le fait pas.** Si tu es en avance au J17, tu l'ajoutes.
- **`$` seul, `$?$?`, `$1`** : cas de test fréquents en soutenance. Coût : 30 min. **Décision : on le fait**, au J9.

### Points de vigilance semaine 2

- **J11 :** le heredoc doit être lu AVANT le fork de la commande, sinon Ctrl-C dans le heredoc tue le mauvais processus.
- **J12 :** une seule globale, de type `sig_atomic_t` ou `int`, contenant uniquement le numéro du signal. Aucune structure. C'est vérifié.
- **J12 :** au prompt, SIGINT affiche une nouvelle ligne, réaffiche le prompt et met `$?` à 130. SIGQUIT est ignoré. Dans un enfant, les deux ont leur comportement par défaut.

---

## 5. Semaine 3 (22 au 28/09) : durcissement et soutenance

Aucune fonctionnalité nouvelle. Cette semaine ne sert qu'à rendre le projet défendable.

| Jour | Date | Bloc |
|---|---|---|
| J15 | lun 22 | Valgrind sur 30 scénarios (avec `tests/readline.supp`), zéro leak hors readline |
| J16 | mar 23 | Chasse aux fds ouverts, edge cases : `""`, `\|` en début, quote non fermée, `exit abc`, `exit 1 2` |
| J17 | mer 24 | Norminette zéro erreur sur `src/` et `includes/` |
| J18 | jeu 25 | Script comparatif : 100 lignes passées à minishell et à bash, diff des sorties et des codes retour |
| J19 | ven 26 | README (chapitre V du sujet) + relecture croisée du code avec Davi |
| J20 | sam 27 | Répétition de soutenance : Davi explique ton code, tu expliques le sien |
| J21 | dim 28 | Marge. Aucune tâche planifiée. |

Rendu le 29/09.

### La règle du J20

À l'évaluation, chacun doit pouvoir expliquer la totalité du code, y compris ce qu'il n'a pas écrit. Le J20 n'est pas optionnel : c'est le jour où on découvre ce que personne ne sait défendre.

---

## 6. Ce qui fait échouer ce plan

Par ordre de probabilité décroissante.

1. **La dette du §2 n'est pas traitée le 08/09.** Conséquence : réécriture du lexer et de l'expander au J9, sous pression, avec 12 jours restants. Probabilité élevée si tu commences par autre chose.
2. **Le binaire n'exécute toujours pas de commande au 11/09.** C'est le signal d'alarme. Si au J4 `ls` ne tourne pas, arrête tout et fais uniquement tourner `ls`.
3. **Retour au mode process.** Rouvrir le board, réécrire des docs, rédiger des templates. Le projet a déjà 9 documents et 0 exécution. Le ratio doit s'inverser cette semaine.
4. **Attendre Davi.** Chaque jour d'attente d'une review est un jour perdu. Le plan est calibré pour tenir sans lui.
5. **Tenter les bonus.** Déjà tranché : non.

---

## 7. Suivi quotidien

Trois lignes par jour, en fin de session, dans une issue épinglée :

```
J<N> : <ce qui tourne maintenant qui ne tournait pas hier>
Bloqué sur : <ou "rien">
Demain : <le bloc du plan>
```

Si la première ligne est vide deux jours de suite, le plan a décroché et il faut recouper le scope, pas rattraper.

---

## 8. Version courte

Trois semaines, une seule question : **est-ce que le binaire exécute plus de choses aujourd'hui qu'hier ?**

Semaine 1, il tourne. Semaine 2, il devient un vrai shell. Semaine 3, il devient défendable. Le process, les docs et les bonus ne sont plus au programme.

---

## 9. Affectation des 44 issues ouvertes

### 9.1 Nettoyage préalable (30 min, aujourd'hui)

**Fermer 3 issues bonus** : #53 (`&&` / `||`), #54 (wildcards), #55 (tests bonus).
Commentaire de fermeture : `Hors scope, deadline 29/09. Réouvrable après le rendu.`

**Fermer 7 issues de tests, absorbées par #49** : #11, #18, #22, #28, #35, #40, #50.
Commentaire : `Regroupée dans #49 (script comparatif minishell vs bash).`
Raison : la stratégie à 4 niveaux et 250 cas coûte plus cher que le seul test qui a du ROI ici, à savoir la comparaison directe avec bash. On garde #46 (tests manuels signals), qui ne peut pas être scripté.

**Reste : 34 issues sur 21 jours, soit 1,6 par jour.**

### 9.2 Semaine 1, 15 issues (08 au 14/09)

| Jour | Issues | Volume |
|---|---|---|
| J1 lun 08 | **#6** lexer quotes (redéfinie : sortir les 3 statics + conserver les quotes dans le token) | 1 |
| J2 mar 09 | **#19** token list vers `t_cmd`, **#20** attachement des redirections | 2 |
| J3 mer 10 | **#21** validation syntaxique, **#23** résolution PATH | 2 |
| J4 jeu 11 | **#24** fork + execve + wait, **#29** chaîner `main.c`, **#30** premier end-to-end | 3 |
| J5 ven 12 | **#25** redirections IO, **#27** dispatch builtin vs externe | 2 |
| J6 sam 13 | **#36** pipelines multi-commandes | 1 |
| J7 dim 14 | **#8** echo, **#9** pwd, **#10** exit, **#17** cleanup | 4 |

**J4 est le jalon de survie du projet.** Le soir du 11/09, `./minishell` doit lancer `ls`. Si ce n'est pas le cas, tout le reste du plan est caduc et il faut recouper le scope immédiatement.

**Davi, semaine 1** : #26 (cd), #38 (export), #39 (unset). Trois blocs qui ne dépendent que de `env/`, terminé. Aucune interaction avec ton chemin critique.

### 9.3 Semaine 2, 13 issues (15 au 21/09)

| Jour | Issues | Volume |
|---|---|---|
| J8 lun 15 | **#31** `$VAR`, **#32** `$?` | 2 |
| J9 mar 16 | **#33** expansion selon le type de quote, **#34** strip des quotes | 2 |
| J10 mer 17 | **#41** intégration de l'expander dans la pipeline | 1 |
| J11 jeu 18 | **#37** heredoc | 1 |
| J12 ven 19 | **#45** `g_signal`, **#44** setup sigaction, **#43** handlers SIGINT/SIGQUIT | 3 |
| J13 sam 20 | **#26** cd, **#38** export, **#39** unset (reprise si Davi n'a pas livré) | 3 |
| J14 dim 21 | **#42** edge cases export+expansion et heredoc+pipe | 1 |

**J13 est ta variable d'ajustement.** Si Davi a livré ses trois builtins, ce jour devient du rattrapage libre. C'est la seule marge de la semaine 2, ne la consomme pas avant.

### 9.4 Semaine 3, 6 issues (22 au 28/09)

| Jour | Issue |
|---|---|
| J15 lun 22 | **#47** chasse aux leaks (valgrind + `readline.supp`) |
| J16 mar 23 | **#49** script comparatif vs bash (absorbe les 7 issues de tests fermées) |
| J17 mer 24 | **#48** norminette zéro erreur |
| J18 jeu 25 | **#46** tests manuels signaux |
| J19 ven 26 | **#51** README chapitre V |
| J20 sam 27 | **#52** démo croisée binôme |
| J21 dim 28 | Marge, aucune issue |

### 9.5 Comment les issues se ferment maintenant

Attention, piège technique avec le nouveau process : GitHub ne ferme automatiquement une issue via `Closes #N` que si le commit atterrit sur la **branche par défaut** (`main`). En poussant directement sur `dev`, tes `Closes #N` ne déclencheront rien.

Procédure : tu écris quand même `Closes #N` dans tes messages de commit sur `dev` (traçabilité), puis le dimanche, dans la PR `dev` vers `main`, tu listes toutes les issues de la semaine dans la description :

```
Closes #19
Closes #20
Closes #21
Closes #23
...
```

Au merge, les 15 issues se ferment d'un coup et le board se met à jour tout seul. Une seule PR par semaine, une seule opération de board.

### 9.6 Le compteur qui compte vraiment

Fermer 34 issues n'est pas l'objectif, c'est le sous-produit. Une issue fermée sans code qui tourne est un mensonge sur le board, et c'est exactement ce qui a produit la situation actuelle : 55 issues créées, 0 commande exécutée.

Le seul indicateur qui vaut : le nombre de lignes de commande que ton shell exécute correctement. Tiens-le dans une issue épinglée.

| Date | Ce que le shell sait faire |
|---|---|
| 08/09 | rien |
| 11/09 | `ls`, `cat Makefile`, `$?` correct |
| 12/09 | `ls > out`, `cat < in`, echo, pwd, exit |
| 13/09 | `ls \| grep c \| wc -l` |
| 17/09 | `echo "$USER"`, `echo '$USER'` |
| 19/09 | `cat << EOF \| grep x`, Ctrl-C propre |
