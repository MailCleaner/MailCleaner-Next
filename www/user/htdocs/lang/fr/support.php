<?php

$txt['SFALSENEGTITLE'] = "FAUX-NÉGATIFS";
$txt['SFALSENEGSUBTITLE'] = "Vous avez reçu un message que vous considérez comme indésirable ?";
$txt['SVERIFYPASS'] = "Vérifiez que le message est bien passé par le filtre Mailcleaner en regardant l'entête du courriel.";
$txt['SMCLOGTITLE'] = "Mention du passage par mailcleaner.net :";
$txt['SMCLOGLINE1'] = "Reçu : de mailcleaner.net (daemon filtre)";
$txt['SMCLOGLINE2'] = "par mailcleaner.net via esmtp (daemon entrant)";
$txt['SMCFILTERINGLOG'] = "Résultat du filtrage : X-Mailcleaner-Spamscore : oooo";
$txt['SFALSENEGTUTOR'] = "Si vraiment il vous semble anormal d'avoir re&ccedil;u ce message, transf&eacute;rez le &agrave; l'adresse <a href=\"mailto:spam@mailcleaner.net\">spam@mailcleaner.net</a>, ou mieux si votre messagerie le permet, &quot;transf&eacute;rer en tant que pi&egrave;ce jointe&quot; pour conserver l'ent&ecirc;te compl&ecirc;te du message.<br>Nous analyserons le contenu de ce message et adapterons les crit&egrave;res de filtrage de mailcleaner en cons&eacute;quence pour que tous les autres utilisateurs b&eacute;n&eacute;ficient de cette analyse.";
$txt['SFALSEPOSTITLE'] = "FAUX-POSITIFS";
$txt['SFALSEPOSSUB1TITLE'] = "Vous ne recevez pas un courriel qui aurait dû vous parvenir ?";
$txt['SFALSEPOSSUB1'] = "Vous pouvez contr&ocirc;ler si le message n'a pas &eacute;t&eacute; bloqu&eacute; par l'interface web disponible sous l'onglet quarantaine. Si vous ne le trouvez pas dans la liste v&eacute;rifiez les points suivants :";
$txt['SFALSEPOSSUB1POINT1'] = "l'adresse de destination r&eacute;dig&eacute;e par votre interlocuteur comporte une erreur";
$txt['SFALSEPOSSUB1POINT2'] = "Courriel en cours d'acheminement ou de filtrage. Le traitement de votre message peut prendre plusieurs minutes.";
$txt['SFALSEPOSSUB2TITLE'] = "Un courriel a été considéré comme indésirable et vous ne comprenez pas pourquoi ?";
$txt['SFALSEPOSSUB2'] = "Sous l'onglet quarantaine, vous pouvez visualiser les crit&egrave;res qui ont pouss&eacute; Mailcleaner &agrave; consid&eacute;rer le message comme &eacute;tant un spam en cliquant sur l'ic&ocirc;ne <img src=\"/templates/$template/images/support/reasons.gif\" align=\"middle\" alt=\"\"> . Si vous estimez que ces crit&egrave;res ne sont pas justifi&eacute;s, vous pouvez en demander l'analyse &agrave; notre &eacute;quipe en cliquant sur le bouton <img src=\"/templates/$template/images/support/analyse.gif\" align=\"middle\" alt=\"\">. Vous pouvez aussi lib&eacute;rer le message en cliquant sur l'ic&ocirc;ne <img src=\"/templates/$template/images/support/force.gif\" align=\"middle\" alt=\"\"> .";
$txt['SFALSEPOSSUB3TITLE'] = "Les listes de publipostage";
$txt['SFALSEPOSSUB3'] = "Il peut arriver que certaines mailing-lists se trouvent bloqu&eacute;es par Mailcleaner. Cela est d&ucirc; &agrave; leur formattage, souvent tr&egrave;s proche des spams. Vous pouvez demander l'analyse de ces messages de la m&ecirc;me mani&egrave;re que pr&eacute;c&eacute;demment, et notre &eacute;quipe se chargera de placer cette mailing-list dans les listes-blanches.";
$txt['SOTHERTITLE'] = "AUTRES PROBLÈMES";
$txt['SOTHER'] = "Vous avez un autre probl&egrave;me avec la r&eacute;ception de vos e-mails, vous avez suivi la proc&eacute;dure ci-dessus sans r&eacute;sultats ou vous avez un autre probl&egrave;me ? Alors contactez le centre de support de Mailcleaner en compl&eacute;tant ce formulaire.";
$txt['FAQTITLE'] = "Fonctionnement de MailCleaner";
$txt['DOCTITLE'] = "Aide sur l'interface utilisateur";
$txt['WEBDOCTITLE'] = "Documentation en ligne";
$txt['FAQ'] = "
               <ul>
                 <li> <h2>Que fait r&eacute;ellement MailCleaner ?</h2>
                      Mailcleaner est un filtre de courriel charg&eacute; de bloquer les messages dangereux ou publicitaires. C'est une solution serveur, ce qui &eacute;limine le besoin d'installer un logiciel sur votre poste. Le filtrage est g&eacute;r&eacute; par le fournisseur de vos comptes de messagerie. Vous &ecirc;tes actuellement connect&eacute; sur l'interface utilisateur du filtre, d'o&ugrave; vous pourrez voir les &eacute;ventuels messages bloqu&eacute;s et proc&eacute;der &agrave; quelques r&eacute;glages.
                 </li>
                 <li> <h2>Qu'est ce qu'un spam ?</h2>
                      Un spam est un message non solicit&eacute; et non d&eacute;sir&eacute;. G&eacute;n&eacute;ralement &agrave; caract&eacute;re publicitaire, ces messages peuvent rapidement remplir votre compte de messagerie. Bien que rarement dangereux, ils sont particuli&egrave;rement ennuyeux et intrusifs.
                 </li>
                 <li> <h2>Que sont les virus et les contenus dangereux ?</h2>
                      Les virus sont des petits logiciels qui peuvent exploiter votre ordinateur et y donner acc&egrave;s &agrave; des personnes mal intentionn&eacute;es. Ils peuvent &ecirc;tre envoy&eacute;s sous la forme d'attachements et infecter votre syst&egrave;me d&egrave;s leur ouverture (certains ne n&eacute;cessitent m&ecirc;me aucune intervention humaine). Les contenus dangereux sont identiques, &agrave; l'exception qu'ils peuvent &ecirc;tre activ&eacute;s de mani&egrave;re plus intelligente et cach&eacute;e, directement dans le corps du message, ou par attaques &agrave; rebond. Ces derni&egrave;res sont particuli&egrave;rement difficiles &agrave; d&eacute;tecter car le code malicieux n'est pas r&eacute;ellement pr&eacute;sent dans le message. MailCleaner offre une protection avanc&eacute;e contre ce genre d'attaque afin de pr&eacute;venir tous messages dangereux d'atteindre votre bo&icirc;te.
                 </li>
                 <li> <h2>Crit&egrave;res anti-spam de MailCleaner</h2>
                      Mailcleaner utilise plusieurs types de contr&ocirc;les diff&eacute;rents afin de filtrer les messages le plus efficacement possible. Ceux-ci peuvent &ecirc;tre des correspondances de mots et de phrases cl&eacute;s, des bases mondiales de spam et des calculs statistiques de phon&egrave;mes. L'addition de tous ces crit&egrave;res fourni un score global au message sur lequel MailCleaner prendra sa d&eacute;cision: spam ou pas. Le spam &eacute;tant une cible mouvante, ces param&egrave;tres doivent &ecirc;tre adapt&eacute;s le plus rapidement possible. C'est le travail de MailCleaner que de tenir ces r&eacute;glages aussi bons que possible.
                 </li>
                 <li> <h2>Erreurs</h2>
                      Mailcleaner &eacute;tant un syst&egrave;me de filtrage automatique, il est ouvert aux erreurs. Il y a deux types d'erreurs provoqu&eacute;es par Mailcleaner: 
                      <ul>
                       <li> les <h3>faux n&eacute;gatifs</h3> sont des spams qui ont pass&eacute; outre les diff&eacute;rents filtres de Mailcleaner et qui ont r&eacute;ussi &agrave; atteindre votre bo&icirc;te sans &ecirc;tre d&eacute;tect&eacute;s. Ces cas sont ennuyeux, mais tant qu'ils restent assez rares, ils n'auront pas trop d'impact sur votre travail. Vous souvenez-vous du temps ou vous ne receviez qu'on ou deux spams par semaine ? Mailcleaner devrait au moins vous ramener &agrave; cette situation.
                       </li>
                       <li> les <h3>faux positifs</h3> sont des erreurs plus ennuyeuses, puisqu'il s'agit de messages valides qui sont bloqu&eacute;s par le syst&egrave;me. Si vous n'&ecirc;tes pas assez vigilant et que vous ne v&eacute;rifiez pas votre quarantaine ou ne lisez pas attentivement les rapports, vous risquez de perdre des messages importants. Mailcleaner est optimis&eacute; pour r&eacute;duire ce genre d'erreur au maximum. Malheureusement, bien qu'extr&ecirc;mement rares, elle peuvent se produire. Pour cette raison, Mailcleaner propose un acc&egrave;s temps-r&eacute;el &agrave; la quarantaine, et des rapports (r&eacute;sum&eacute;s) p&eacute;riodiques qui vous permettront de minimiser le risque de perte de messages.
                       </li>
                      </ul>
                  </li>
                  <li> <h2>Comment faire pour corriger MailCleaner ?</h2>
                      Lorsque MailCleaner commet une erreur, la meilleure r&eacute;action consiste &agrave; avertir votre administrateur de la situation. Bien qu'elle soit parfois in&eacute;vitable, l'utilisation des listes blanches et noires n'est malheureusement pas viable sur du moyen-long terme (voir ceci pour plus d'informations). La meilleure solution consiste toujours &agrave; trouver l'erreur commise et &agrave; la corriger. Ceci ne peut &ecirc;tre fait que par les administrateurs du filtre. N'h&eacute;sitez donc pas &agrave; leur communiquer les &eacute;ventuelles erreurs.
                  </li>
                </ul>";
$txt['DOCUMENTATION'] = "
                         <ul>
                           <li> <h2>Vue de la quarantaine/actions</h2>
                              <ul>
                                <li> <h3>addresse:</h3>
                                   s&eacute;lectionnez l'adresse dont vous voulez visualiser la quarantaine. 
                                </li>
                                <li> <h3>forcer le message (<img src=\"/templates/$template/images/force.gif\" align=\"top\" alt=\"\">): </h3>
                                   cliquez sur cette ic&ocirc;ne pour lib&eacute;rer le message. Il sera imm&eacute;diatement r&eacute;exp&eacute;di&eacute; dans votre bo&icirc;te.
                                </li>
                                <li> <h3>voir les raisons du filtrage (<img src=\"/templates/$template/images/reasons.gif\" align=\"top\" alt=\"\">): </h3>
                                   si vous d&eacute;sirez savoir pourquoi le message a &eacute;t&eacute; bloqu&eacute;, cliquez sur cette ic&ocirc;ne. Vous verrez alors les crit&egrave;res de filtrage de Mailcleaner et leur score respectif. Avec un score total de 5 ou plus, le message est consid&eacute;r&eacute; comme un spam.
                                </li>
                                <li> <h3>demande d'analyse du message (<img src=\"/templates/$template/images/analyse.gif\" align=\"top\" alt=\"\">): </h3>
                                   si le message est un faux-positif, cliquez sur l'ic&ocirc;ne correspondante afin d'avertir votre administrateur de l'erreur.
                                </li>
                                <li> <h3>options du filtre: </h3>
                                   quelques options de filtrage vous permettent de faire des recherches dans votre quarantaine. Le nombre de jours affich&eacute;s, le nombre de messages par page, le sujet et la provenance des messages. Remplissez ces champs et cliquez sur \"rafra&icirc;chir\" pour appliquer les nouvelles options de filtrage.
                                </li>
                                <li> <h3>actions: </h3>
                                   vous pouvez purger (<img src=\"/templates/$template/images/trash.gif\" align=\"top\" alt=\"\">) la quarantaine lorsque vous le d&eacute;sirez. Souvenez-vous que les quarantaines sont r&eacute;guli&egrave;rement purg&eacute;es par le syst&egrave;me. Cette option vous permet simplement de le faire &agrave; tout moment.
                                   Vous pouvez aussi demander un rapport (r&eacute;sum&eacute;) imm&eacute;diat (<img src=\"/templates/$template/images/summary.gif\" align=\"top\" alt=\"\">) de la quarantaine. Il s'agit d'un rapport identique &agrave; celui p&eacute;riodiquement envoy&eacute;. Cette option vous permet simplement d'en demander un &agrave; tout moment.
                                </li>
                              </ul>
                           </li>
                           <li> <h2>Param&egrave;tres</h2>
                              <ul>
                                 <li> <h3>langue: </h3>
                                    choisissez votre langue ici. L'interface, les rapports et les avertissements vous seront alors communiqu&eacute;s dans cette langue.
                                 </li>
                                 <li> <h3>adresse (aggregation): </h3>
                                    si vous disposez de plusieurs adresses ou aliases &agrave; aggr&eacute;ger &agrave; votre interface Mailcleaner, utilisez les boutons plus (<img src=\"/templates/$template/images/plus.gif\" align=\"top\" alt=\"\">) et moins (<img src=\"/templates/$template/images/minus.gif\" align=\"top\" alt=\"\">) pour ajouter ou supprimer des adresses.
                                 </li>
                               </ul>
                            </li>
                            <li> <h2>R&eacute;glages par adresse</h2>
                              quelques options sont d&eacute;finissables par adresse:
                              <ul>
                                 <li><h3>appliquer les changements &agrave; toutes les adresses et aliases: </h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t  selectionnez cela pour appliquer les changements directement &agrave; toutes les adresses.
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<li><h3>Action sur les spams: </h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t  selectionnez le comportement de Mailcleaner pour les messages d&eacute;tect&eacute;s comme spams.
  \t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t <ul>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t <li><h4>mise en quarantaine:</h4> les messages sont stock&eacute;s en quarantaine et effac&eacute;s r&eacute;guli&egrave;rement.</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t <li><h4>marquage du sujet:</h4> les spams ne seront pas bloqu&eacute;s, mais une marque sera ajout&eacute;e au sujet du message.</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t <li><h4>&eacute;limination:</h4> les spams seront simplement &eacute;limin&eacute;s. Utilisez cette option avec prudence car elle peut mener &agrave; la perte de messages (faux positifs).</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t </ul>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<li><h3>Mise en quarantaine des messages d'erreur: </h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t  cette option force Mailcleaner &agrave; mettre en quarantaine tous les messages de notification d'erreur des autres serveurs (adresse invalide, bo&icirc;te pleine, etc...). Ceci peut &ecirc;tre utile si vous &ecirc;tes victime d'une attaque massive de ce type de messages, due par exemple &agrave; un virus. Cette option ne devrait &ecirc;tre activ&eacute;e que pendant un court moment puisqu'elle est intrins&egrave;quement tr&egrave;s dangereuse.
 \t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<li><h3>Marque personnalis&eacute;e du sujet: </h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tchoisissez et personnalisez &agrave; votre guise la marque qui appara&icirc;tra dans le sujet des spams. Ceci ne sera utilis&eacute; que si l'action sur les spams choisie est le marquage du sujet.
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<li><h3>P&eacute;riodicit&eacute; des rapports: </h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t  choisissez avec quelle p&eacute;riodicit&eacute; vous d&eacute;sirez recevoir les rapports (r&eacute;sum&eacute;s) de quarantaine. A cette &eacute;ch&eacute;ance, vous recevrez un message dans votre bo&icirc;te contenant un r&eacute;sum&eacute; de tous les messages bloqu&eacute;s dans la quarantaine depuis le dernier rapport.
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</ul>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</ul>";
$txt['WEBDOC'] = "<ul><li>Vous trouverez plus d'informations et de documentation sur notre site: <a href=\"http://wiki2.mailcleaner.net/doku.php/documentation:userfaq\" target=\"_blank\">Mailcleaner user documentation</a></li></ul>";
