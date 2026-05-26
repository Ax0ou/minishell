# Tests interactifs — nécessitent un humain

> Quand on ne peut pas piper la commande dans minishell (parce que ça nécessite une vraie interactivité).
> Lancer `./minishell` puis dérouler.

## A. Historique readline
- [ ] Taper `echo a` + Entrée, puis `echo b` + Entrée
- [ ] Appuyer **flèche haut** : doit afficher `echo b`
- [ ] Encore flèche haut : `echo a`
- [ ] Flèche bas : revient à `echo b`
- [ ] Édition en place (gauche/droite, backspace) marche

## B. Édition de ligne
- [ ] Taper `echo hello`, Ctrl-A va au début, Ctrl-E à la fin (raccourcis readline natifs)
- [ ] Backspace efface bien
- [ ] Pas de caractère bizarre à l'écran

## C. Prompt
- [ ] Le prompt s'affiche dès le démarrage
- [ ] Le prompt se ré-affiche après chaque commande
- [ ] Le prompt ne disparaît pas après Ctrl-C
