# La Taverne

<p align="center"><img src="https://raw.githubusercontent.com/Oylex/la-taverne/main/branding/lynx_logo.png" alt="Nation du Québec lynx" width="200"></p>

<p align="center"><b>The Nation du Québec's tavern</b> · <b>La taverne de la Nation du Québec</b></p>

**La Taverne joins your guild and its allied guilds as if they were one: shared guild chat, a dungeon group finder, who's available to play, who's online, and where everyone is on the map.**

*Français plus bas.*

---

## English

### At a glance

- **Groups:** post a dungeon group or join one, from your guild and the allied guilds. La Taverne sends the party invites.
- **Availability:** say you're free to play, for which roles and dungeons. Leaders see you and invite you in one click.
- **Shared guild chat:** your guild chat and the allied guilds' are one, with real item and spell links. Members without La Taverne are included too, through the guild relay.
- **Alliance:** who is online with La Taverne in each guild, and what each guild has going on.
- **Professions:** find who in your guild or the allied guilds can make a recipe, and whisper them.
- **World map:** your guildmates and allies as dots on the map, moving as they go.
- **Auto-invite:** members who type `+1` (or your own keywords) in guild chat get a party invite.

Everything works inside your own guild right away. Linking allied guilds is done once by an officer of each guild.

### Getting started

1. Install La Taverne and log in. Everyone who wants to use it needs the addon.
2. Open it with the minimap button (right-click for a quick menu), the game's add-on menu, `/taverne`, or a key binding (Options > Key Bindings > AddOns).
3. The tabs on the side: **Groups**, **Availability**, **Alliance**, **Professions**, **Auto-invite**, then **Setup** (only for players who can edit the Guild Info) and **Options**. A green dot on a tab means something of yours is running there.

### Groups

- **Post a group** in a few clicks: the dungeon, your role and the roles you're looking for, a note, and options like "New players welcome" or "Discord required". Ten-player dungeons are supported.
- **Browse** the open groups of your guild and the allied guilds, filtered by the roles you can play, your level and the dungeons you want. Level ranges use the game's difficulty colors.
- **Ask to join** with every role you can play. The leader accepts you as one of them, and La Taverne sends the party invite. Requests wait while the leader is offline and are sent again when they're back.
- **My group:** invite players by name (with autocomplete), follow requests and members, and change roles. If someone leaves during the run, **Find a replacement** opens the group to requests again.
- **Available players who fit** show where you make your group: a count beside the dungeon when creating it (click to add one to the invitations), and a list with **Invite** buttons under the requests in My group.
- A group in progress is removed on its own when everyone has left (after 5 minutes alone) or after 3 hours, with a warning first. The next time you open La Taverne, the form is filled in to post it again in one click.
- In the group list, groups in progress or full are folded under their own heading.
- **Alerts** in the chat window you choose, with a sound if you want: a new group that fits you, or a group in progress looking for a replacement. **[View]** opens the list on that group and makes it glow for a moment.
- **Invited to a group:** a small card on screen with the same line and a **View** button that does what the chat's **[View]** does, plus its own sound, heard even with sound effects turned down (and once more after 2 minutes without an answer). The card can be dragged, and waits for the end of a fight. Without a mouse, the **Show what's waiting** key binding does View. Both can be turned off (**Options > Alerts**).
- **Announce in chat** sends a La Taverne message about your group ("... is looking for 1 Tank: ...") to the players who run La Taverne, with a link to it. Nothing goes in guild chat. Not in the group's first 5 minutes, then once every 5 minutes; each player can turn these messages off (**Options > Alerts**).
- Passing the party lead hands your group over to the new leader if they run La Taverne.

### Availability

- **I'm available:** your roles, any dungeon at your level or the ones you choose, for how long, and a note.
- Leaders see you right away and can invite you in one click.
- Shortly before it ends, a window offers **+15 min**, **+1 h** or **Stop**.
- The **Availability** tab lists who's free: **Available players** first, with their roles, dungeons and note. With your group open, **Only those who fit my group** keeps the others under **Available, but not for your group**.
- Below, **Players not looking for a group right now**: your guildmates online and the allied players at the tavern (with their guild's tag), one line each with their level, to invite or whisper. Players without La Taverne are marked "Doesn't have La Taverne".

### Shared guild chat

- What you type in guild chat also reaches the allied guilds, and theirs reaches you, in your usual guild chat (same colors, timestamps, clickable names) and in the guild window.
- Allied lines start with the lynx and the guild's tag (each can be turned off, so allied lines can look like your guild's).
- Item, spell and quest links stay real links. A line that arrives late says when it was typed.
- Players on your ignore list stay hidden in the shared chat too.
- Allied players are checked: their own guild confirms they belong to it. A player who isn't confirmed yet is marked, and an impostor's messages are dropped.

### Guild relay (members without La Taverne)

- Members who don't run La Taverne can't share their guild chat themselves. One La Taverne player of their guild passes their lines on to the allied guilds for them: the **relay**, picked on its own among those who help (players in a city first, never in a dungeon or raid). Nothing is written in the real guild chat.
- It also passes on the map positions of members who share them through OpenMap.
- Players passed on by a relay are checked too: a line passed on by a relay you can vouch for confirms its author; from a relay nobody vouches for, they're marked "(not checked yet)", and someone the game shows in another guild is hidden.
- Everyone with La Taverne helps by default; to stop: **Options > Shared guild chat > Help relay for my guild**. Officers can turn the relay off for the whole guild in **Setup**.
- The Alliance tab and the minimap button's tooltip show who relays for each guild.

### Alliance

The **Alliance** tab has one card per guild: who is online with La Taverne (with their version, and a mark for an old one), the players seen in the last two weeks, and how many open groups and available players each guild has right now. Sort the players by name, last heard from or version (to see who needs to update), and show the offline ones or not. Names are in class colors, with each player's level in their tooltip. Each card also shows the guild's relay, and lists (folded) its members without La Taverne heard through it.

The guilds talk over a hidden channel. If the game drops it (a chat server hiccup, a loading screen), La Taverne joins it again on its own, and nothing sent in the first seconds after a login or `/reload` is lost.

### Professions

- Type a recipe's name, or shift-click an item into the box, and pick the recipe.
- **Search:** every La Taverne in your guild and the allied guilds whose character, or one of its alts, knows the recipe answers within a few seconds, with the cooldown if it has one, and their zone when they share it on the map (or the guild roster shows it). Nothing is written in chat.
- **Whisper** opens the chat box on them with the item ready, not sent.
- Your own recipes are shared the same way. Tick **Available to help** to say you're happy to craft for others: you come first in their list. Untick **Share my recipes** to stop answering.

### World map

- Your guildmates and allied players who run La Taverne show as class-colored dots on the world map: a green ring for your guild, a blue ring for allies. Hover a dot for the name, guild, level and place.
- Positions go out every 10 seconds while you move (every minute while you stand still), and the dots glide in between. Your party and raid keep the game's own dots.
- **Sharing is on**, from the first notice in chat. It never shares from inside a dungeon, raid or battleground. To turn it off: **Options > Map**.
- To show or hide your guild's and the allies' dots: the lynx tab on the world map, the minimap button's right-click menu, or **Options > Map**.

### Auto-invite

- Turn it on, and guild members who type a keyword alone in guild chat (`+1`, `inv`...) get a party invite, right away or when you click. Allied guilds and whispers can be listened to as well. The party becomes a raid when it fills up.
- **Keyword sets:** several leaders can invite at once, each with their own words (`+1` for one group, `+2` for another). The queue page shows who else is inviting and warns when someone uses your words.
- Officers choose who may use it: everyone, only some ranks, or nobody.
- It's always off when you log in, and turns itself off after the time you set.

### Setup (officers)

The **Setup** tab only shows for players who can edit the Guild Info. It holds the guild's La Taverne settings, kept in the Guild Info so every member's addon reads them:

- **Auto-invite:** who may use it.
- **Guild Alliance:** the member guilds with a short tag for each, and the shared key.
- **Guild relay:** whether your members without La Taverne have their guild chat and OpenMap positions passed on to the allied guilds.

Linking guilds is done once by an officer of each guild:

1. **Setup** tab: add the allied guilds and a tag for each, create the key, then **Save**. The game doesn't let addons change the Guild Info, so La Taverne shows the new Guild Info text to copy and paste: your current text with a few short lines starting with `LT:` added, the rest left alone.
2. **Export**, and send the text to an officer of each allied guild. They paste it with **Import**, then **Save**.
3. Every member's addon reads the Guild Info and connects on its own. Members who leave the guild lose access by themselves.

### Options

Window size, the chat window for La Taverne's lines, the minimap button and its glow, which new groups to be told about, leaders' group announcements, sounds, **Quiet in dungeons, raids and combat** (no alerts and no sounds there), dungeon names in the other language (English / French) in tooltips, the map, the lynx at the top of the window, the lynx and tag on allied chat lines, and helping relay for your guild. **Error report** is at the bottom.

### Works with

- **OpenMap:** the dots also show on OpenMap's map, at any zoom, and their tooltips look like OpenMap's. Its menu gets La Taverne's two map switches, and its own "Guild members on the map" switch hides La Taverne's guild and allied dots too. A player who already shares through OpenMap doesn't get a second dot.
- **Chattynator:** allied guild chat shows in Chattynator's windows like your own guild's. To choose the tab for La Taverne's own messages, use the tab's settings in Chattynator (Add-ons).
- **GuildUnion:** **Import > From GuildUnion** copies its guilds and tags, and both addons' lines fit side by side in the Guild Info. While both are installed, keep only one of them sharing guild chat (in La Taverne: **Options**), or allied lines show twice.
- **Controller (gamepad) interface:** La Taverne is used with the controller: the d-pad moves between the window's elements, A chooses, Y goes back or closes, LB / RB change section. B and X stay the game's, and in combat the controller goes back to the game. Menus and confirmation windows work without "action blocked" errors. To open La Taverne with a button: game Options, Keybindings, AddOns.
- **BugSack / BugGrabber:** La Taverne's errors also go to its own error report.

### Commands

- `/taverne`: open or close the window
- `/taverne autoinvite`: turn auto-invite on or off
- `/taverne roster`: the guild roster (rank, level, class, online, days offline, notes, and officer notes for ranks that can see them) and the game's roster history, as text to copy into a spreadsheet
- `/taverne errors`: the error report, to send along with a bug report

### Bugs and suggestions

Please open an issue on GitHub, or leave a comment on CurseForge. If La Taverne reported an error, **Options > Error report** has a text you can copy into your message.

### Credits

- World map dots, OpenMap support, the guild relay, the invitation card and `/taverne roster`: FlisherOfatale. Controller interface support: NuCl34R.
- Allied guild chat in the guild window follows GuildUnion's approach (MIT, by Sadance).
- Uses Ace3 (AceComm, AceSerializer, CallbackHandler), ChatThrottleLib, LibStub, LibDataBroker and LibDBIcon.

### License

The code is under the MIT license. The names "La Taverne" and "Nation du Québec" and the logos (the `LaTaverne/media/` and `branding/` folders) are not: they belong to the Nation du Québec guild, all rights reserved. A fork must use its own name and artwork. Details in the LICENSE file.

---

## Français

**La Taverne réunit votre guilde et ses guildes alliées comme une seule : chat de guilde partagé, recherche de groupes de donjon, qui est disponible pour jouer, qui est en ligne, et où chacun se trouve sur la carte.**

### En bref

- **Groupes :** publiez un groupe de donjon ou rejoignez-en un, dans votre guilde et les guildes alliées. La Taverne envoie les invitations de groupe.
- **Disponibilités :** indiquez que vous êtes libre pour jouer, pour quels rôles et quels donjons. Les chefs vous voient et vous invitent en un clic.
- **Chat de guilde partagé :** votre chat de guilde et celui des guildes alliées n'en font qu'un, avec de vrais liens d'objets et de sorts. Les membres sans La Taverne en font partie aussi, grâce au relais de guilde.
- **Alliance :** qui est en ligne avec La Taverne dans chaque guilde, et ce qui se passe dans chacune.
- **Métiers :** trouvez qui, dans votre guilde ou les guildes alliées, peut fabriquer une recette, et chuchotez-lui.
- **Carte du monde :** les membres de votre guilde et les alliés en points sur la carte, qui bougent avec eux.
- **Invitation automatique :** les membres qui tapent `+1` (ou vos propres mots-clés) dans le chat de guilde reçoivent une invitation de groupe.

Tout marche tout de suite dans votre guilde. Le lien avec les guildes alliées se fait une fois, par un officier de chaque guilde.

### Pour commencer

1. Installez La Taverne et connectez-vous. Chaque joueur qui veut l'utiliser a besoin de l'addon.
2. Ouvrez-la avec le bouton de la minicarte (clic droit pour un menu rapide), le menu des addons du jeu, `/taverne`, ou un raccourci clavier (Options > Raccourcis > AddOns).
3. Les onglets sur le côté : **Groupes**, **Disponibilités**, **Alliance**, **Métiers**, **Invitation automatique**, puis **Configuration** (seulement pour qui peut modifier les infos de guilde) et **Options**. Un point vert sur un onglet veut dire que quelque chose à vous y est en cours.

### Groupes

- **Publiez un groupe** en quelques clics : le donjon, votre rôle et les rôles recherchés, une note, et des options comme « Nouveaux joueurs bienvenus » ou « Discord requis ». Les donjons à dix joueurs sont pris en charge.
- **Parcourez** les groupes ouverts de votre guilde et des guildes alliées, filtrés selon les rôles que vous pouvez jouer, votre niveau et les donjons voulus. Les tranches de niveau prennent les couleurs de difficulté du jeu.
- **Demandez à rejoindre** avec tous les rôles que vous pouvez jouer. Le chef vous accepte dans l'un d'eux, et La Taverne envoie l'invitation de groupe. Les demandes attendent si le chef est hors ligne, et repartent à son retour.
- **Mon groupe :** invitez des joueurs par leur nom (avec autocomplétion), suivez demandes et membres, et changez les rôles. Si quelqu'un part en cours de route, **Chercher un remplaçant** rouvre le groupe aux demandes.
- **Les joueurs disponibles qui conviennent** s'affichent là où vous montez votre groupe : un compte à côté du donjon pendant la création (un clic pour en ajouter un aux invitations), et une liste avec des boutons **Inviter** sous les demandes dans Mon groupe.
- Un groupe en cours est retiré de lui-même quand tout le monde est parti (après 5 minutes seul) ou après 3 heures, avec un avertissement avant. À la prochaine ouverture de La Taverne, le formulaire est déjà rempli pour le republier en un clic.
- Dans la liste des groupes, les groupes en cours ou complets sont repliés sous leur propre titre.
- **Alertes** dans la fenêtre de chat de votre choix, avec un son si vous voulez : un nouveau groupe qui vous convient, ou un groupe en cours qui cherche un remplaçant. **[Voir]** ouvre la liste sur ce groupe et le fait briller un instant.
- **Invité dans un groupe :** une petite carte à l'écran avec la même ligne et un bouton **Voir** qui fait comme le **[Voir]** du chat, et un son à elle, entendu même avec les effets sonores baissés (et une autre fois après 2 minutes sans réponse). La carte se déplace, et attend la fin d'un combat. Sans souris, le raccourci **Afficher ce qui vous attend** fait Voir. Les deux se désactivent (**Options > Alertes**).
- **Annoncer dans le chat** envoie un message de La Taverne sur votre groupe (« ... cherche 1 Tank : ... ») aux joueurs qui utilisent La Taverne, avec un lien vers le groupe. Rien ne va dans le chat de guilde. Pas dans les 5 premières minutes du groupe, puis une fois toutes les 5 minutes ; chaque joueur peut désactiver ces messages (**Options > Alertes**).
- En passant le chef du groupe, votre groupe passe au nouveau chef s'il utilise La Taverne.

### Disponibilités

- **Je suis disponible :** vos rôles, n'importe quel donjon à votre niveau ou ceux que vous choisissez, pour combien de temps, et une note.
- Les chefs vous voient tout de suite et peuvent vous inviter en un clic.
- Peu avant la fin, une fenêtre propose **+15 min**, **+1 h** ou **Arrêter**.
- L'onglet **Disponibilités** liste qui est libre : les **Joueurs disponibles** d'abord, avec leurs rôles, leurs donjons et leur note. Avec votre groupe ouvert, **Seulement ceux qui conviennent à mon groupe** range les autres sous **Disponibles, mais pas pour votre groupe**.
- En dessous, **Joueurs ne cherchant pas de groupe pour le moment** : les membres de votre guilde en ligne et les joueurs alliés à la taverne (avec le tag de leur guilde), une ligne chacun avec leur niveau, pour les inviter ou leur chuchoter. Les joueurs sans La Taverne sont marqués « N'a pas La Taverne ».

### Chat de guilde partagé

- Ce que vous écrivez dans le chat de guilde arrive aussi aux guildes alliées, et le leur vous arrive, dans votre chat de guilde habituel (mêmes couleurs, horodatage, noms cliquables) et dans la fenêtre de guilde.
- Les lignes des alliés commencent par le lynx et le tag de leur guilde (chacun peut être retiré, pour que les lignes alliées ressemblent à celles de votre guilde).
- Les liens d'objets, de sorts et de quêtes restent de vrais liens. Une ligne qui arrive en retard indique quand elle a été écrite.
- Les joueurs de votre liste d'ignorés restent cachés dans le chat partagé aussi.
- Les joueurs alliés sont vérifiés : leur propre guilde confirme qu'ils en font partie. Un joueur pas encore confirmé est signalé, et les messages d'un imposteur sont ignorés.

### Relais de guilde (membres sans La Taverne)

- Les membres qui n'utilisent pas La Taverne ne peuvent pas partager leur chat de guilde eux-mêmes. Un joueur de leur guilde qui utilise La Taverne transmet leurs lignes aux guildes alliées pour eux : le **relais**, choisi tout seul parmi ceux qui aident (les joueurs en ville d'abord, jamais en donjon ou en raid). Rien n'est écrit dans le vrai chat de guilde.
- Il transmet aussi la position sur la carte des membres qui la partagent avec OpenMap.
- Les joueurs transmis par un relais sont vérifiés aussi : une ligne transmise par un relais dont vous pouvez vous porter garant confirme son auteur ; d'un relais dont personne ne se porte garant, ils sont marqués « (non vérifié) », et quelqu'un que le jeu montre dans une autre guilde est caché.
- Chaque joueur avec La Taverne aide par défaut ; pour arrêter : **Options > Chat de guilde partagé > Aider à relayer pour ma guilde**. Les officiers peuvent désactiver le relais pour toute la guilde dans **Configuration**.
- L'onglet Alliance et l'infobulle du bouton de la minicarte indiquent qui relaie pour chaque guilde.

### Alliance

L'onglet **Alliance** a une carte par guilde : qui est en ligne avec La Taverne (avec sa version, et une marque pour une ancienne), les joueurs vus ces deux dernières semaines, et combien de groupes ouverts et de joueurs disponibles chaque guilde a en ce moment. Triez les joueurs par nom, dernier signe ou version (pour voir qui doit mettre à jour), et affichez ou non ceux qui sont hors ligne. Les noms sont dans la couleur de leur classe, avec le niveau de chaque joueur dans son infobulle. Chaque carte indique aussi le relais de la guilde, et liste (repliés) ses membres sans La Taverne transmis par lui.

Les guildes communiquent par un canal caché. Si le jeu le coupe (un hoquet du serveur de chat, un écran de chargement), La Taverne le rejoint d'elle-même, et rien de ce qui arrive dans les premières secondes après une connexion ou un `/reload` n'est perdu.

### Métiers

- Tapez le nom d'une recette, ou faites Maj-clic sur un objet dans la case, et choisissez la recette.
- **Demander à l'alliance :** chaque La Taverne de votre guilde et des guildes alliées dont le personnage, ou un de ses alts, connaît la recette répond en quelques secondes, avec le temps de recharge s'il y en a un. Rien n'est écrit dans le chat.
- **Chuchoter** ouvre la boîte de discussion sur lui avec l'objet prêt, sans l'envoyer.
- Vos propres recettes sont partagées de la même façon. Cochez **Disponible pour aider** pour dire que vous fabriquez volontiers pour les autres : vous passez en premier dans leur liste. Décochez **Partager mes recettes** pour ne plus répondre.

### Carte du monde

- Les membres de votre guilde et les joueurs alliés qui utilisent La Taverne s'affichent en points de la couleur de leur classe sur la carte du monde : un anneau vert pour votre guilde, bleu pour les alliés. Survolez un point pour le nom, la guilde, le niveau et l'endroit.
- Les positions partent toutes les 10 secondes quand vous bougez (toutes les minutes à l'arrêt), et les points glissent entre les deux. Votre groupe et votre raid gardent les points du jeu.
- **Le partage est actif**, à partir du premier avis dans le chat. Il ne partage jamais depuis un donjon, un raid ou un champ de bataille. Pour le désactiver : **Options > Carte**.
- Pour afficher ou cacher les points de votre guilde et des alliés : l'onglet lynx sur la carte du monde, le menu du clic droit sur le bouton de la minicarte, ou **Options > Carte**.

### Invitation automatique

- Activez-la, et les membres de la guilde qui tapent un mot-clé seul dans le chat de guilde (`+1`, `inv`...) reçoivent une invitation de groupe, tout de suite ou quand vous cliquez. Les guildes alliées et les chuchotements peuvent aussi être écoutés. Le groupe devient un raid quand il est plein.
- **Jeux de mots-clés :** plusieurs chefs peuvent inviter en même temps, chacun avec ses mots (`+1` pour un groupe, `+2` pour un autre). La page de la file montre qui d'autre invite et prévient quand quelqu'un utilise vos mots.
- Les officiers choisissent qui peut l'utiliser : tout le monde, certains rangs seulement, ou personne.
- Elle est toujours désactivée à la connexion, et s'arrête d'elle-même après la durée choisie.

### Configuration (officiers)

L'onglet **Configuration** n'apparaît que pour les joueurs qui peuvent modifier les infos de guilde. Il regroupe les réglages de La Taverne pour la guilde, gardés dans les infos de guilde pour que l'addon de chaque membre les lise :

- **Invitation automatique :** qui peut l'utiliser.
- **Alliance de guildes :** les guildes membres avec un tag court pour chacune, et la clé partagée.
- **Relais de guilde :** si le chat de guilde et les positions OpenMap de vos membres sans La Taverne sont transmis aux guildes alliées.

Le lien entre les guildes se fait une fois, par un officier de chaque guilde :

1. Onglet **Configuration** : ajoutez les guildes alliées avec un tag pour chacune, créez la clé, puis **Enregistrer**. Le jeu ne permet pas aux addons de modifier les infos de guilde : La Taverne affiche donc le nouveau texte à copier-coller, c'est-à-dire votre texte actuel avec quelques lignes courtes commençant par `LT:` en plus, le reste tel quel.
2. **Exporter**, et envoyez le texte à un officier de chaque guilde alliée. Il le colle avec **Importer**, puis **Enregistrer**.
3. L'addon de chaque membre lit les infos de guilde et se connecte tout seul. Les membres qui quittent la guilde perdent l'accès d'eux-mêmes.

### Options

Taille de la fenêtre, fenêtre de chat pour les lignes de La Taverne, bouton de la minicarte et son halo, les nouveaux groupes à signaler, les annonces de groupe des chefs, les sons, **Silencieux en donjon, en raid et en combat** (ni alerte ni son), le nom des donjons dans l'autre langue (anglais / français) dans les infobulles, la carte, le lynx en haut de la fenêtre, le lynx et le tag sur les lignes des alliés, et l'aide au relais de votre guilde. Le **Rapport d'erreurs** est en bas.

### Compatible avec

- **OpenMap :** les points s'affichent aussi sur la carte d'OpenMap, à tous les niveaux de zoom, et leurs infobulles ressemblent à celles d'OpenMap. Son menu reçoit les deux options de carte de La Taverne, et sa propre option « Membres de guilde sur la carte » cache aussi les points de guilde et d'alliés de La Taverne. Un joueur qui partage déjà sa position par OpenMap n'a pas de deuxième point.
- **Chattynator :** le chat des guildes alliées s'affiche dans les fenêtres de Chattynator comme celui de votre guilde. Pour choisir l'onglet des messages de La Taverne, passez par les paramètres de l'onglet dans Chattynator (Add-ons).
- **GuildUnion :** **Importer > Depuis GuildUnion** reprend ses guildes et ses tags, et les lignes des deux addons tiennent ensemble dans les infos de guilde. Tant que les deux sont installés, ne laissez qu'un seul des deux partager le chat de guilde (dans La Taverne : **Options**), sinon les lignes alliées s'affichent deux fois.
- **Interface manette :** La Taverne s'utilise à la manette : la croix passe d'un élément à l'autre de la fenêtre, A choisit, Y revient en arrière ou ferme, LB / RB changent de section. B et X restent au jeu, et en combat la manette revient au jeu. Les menus et les fenêtres de confirmation fonctionnent sans erreurs « action bloquée ». Pour ouvrir La Taverne avec un bouton : Options du jeu, Raccourcis, AddOns.
- **BugSack / BugGrabber :** les erreurs de La Taverne vont aussi dans son propre rapport d'erreurs.

### Commandes

- `/taverne` : ouvrir ou fermer la fenêtre
- `/taverne autoinvite` : activer ou désactiver l'invitation automatique
- `/taverne roster` : la liste de guilde (rang, niveau, classe, en ligne, jours hors ligne, notes, et notes d'officier pour les rangs qui peuvent les voir) et l'historique de la liste du jeu, en texte à copier dans un tableur
- `/taverne errors` : le rapport d'erreurs, à joindre à un signalement de bug

### Bugs et suggestions

Ouvrez une issue sur GitHub, ou laissez un commentaire sur CurseForge. Si La Taverne a signalé une erreur, **Options > Rapport d'erreurs** contient un texte à copier dans votre message.

### Remerciements

- Points sur la carte du monde, compatibilité OpenMap, relais de guilde, carte d'invitation et `/taverne roster` : FlisherOfatale. Compatibilité avec l'interface manette : NuCl34R.
- Le chat allié dans la fenêtre de guilde reprend l'approche de GuildUnion (MIT, par Sadance).
- Utilise Ace3 (AceComm, AceSerializer, CallbackHandler), ChatThrottleLib, LibStub, LibDataBroker et LibDBIcon.

### Licence

Le code est sous licence MIT. Les noms « La Taverne » et « Nation du Québec » et les logos (dossiers `LaTaverne/media/` et `branding/`) ne le sont pas : ils appartiennent à la guilde Nation du Québec, tous droits réservés. Un fork doit utiliser son propre nom et ses propres images. Détails dans le fichier LICENSE.
