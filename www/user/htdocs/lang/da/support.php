<?php

$txt['SFALSENEGTITLE'] = "FALSK NEGATIV";
$txt['SFALSENEGSUBTITLE'] = "Har du modtaget en besked, som du anser for at være spam?";
$txt['SVERIFYPASS'] = "Kontroller, at meddelelsen er blevet behandlet af Mailcleaner-filteret ved at se på e-mail-headerne.";
$txt['SMCLOGTITLE'] = "I headerne, vil du se følgende linjer, der nævner Mailcleaner:";
$txt['SMCLOGLINE1'] = "Modtaget: Fra mailcleaner.net (filtrering daemon)";
$txt['SMCLOGLINE2'] = "af mailcleaner.net med ESMTP (indkommende dæmon)";
$txt['SMCFILTERINGLOG'] = "Resultat af filtrering: X-Mailcleaner-spamscore: oooo";
$txt['SFALSEPOSTITLE'] = "FALSK POSITIV";
$txt['SFALSEPOSSUB1TITLE'] = "Du har ikke modtaget en besked, som du burde have haft?";
$txt['SFALSEPOSSUB2TITLE'] = "En e-mail blev betragtet som spam, og du forstår ikke hvorfor?";
$txt['SFALSEPOSSUB3TITLE'] = "Mailing lister";
$txt['SFALSENEGTUTOR'] = "Hvis du virkelig finder, at beskeden skal betragtes som spam, så overfør den til spam@mailrenere.net, eller endnu bedre, hvis dit e -mail program tillader det, så vælg \"Overførsel som vedhæftning\" for at beholde e -mail - headers intakte. Vores analysecenter vil udbrede indholdet af meddelelsen og tilpasse Mailcleaner s filtreringskriterier i overensstemmelse hermed, s åledes at alle Mailcleaner -brugere drager fordel af analysen.";
$txt['SFALSEPOSSUB1'] = "Du kan kontrollere om mailen blev blokeret af Mailcleaner via brugergrænsefladen under overskriften \"Quarantine\".Hvis du ikke finder det på karantænelisten, bedes du bekræfte følgende punkter:";
$txt['SFALSEPOSSUB1POINT1'] = "destination adressen, der bruges af afsenderen er korrekt";
$txt['SFALSEPOSSUB1POINT2'] = "e -mailen havde mulighed for at blive behandlet (en proces, der kan tage et par minutter)";
$txt['SFALSEPOSSUB2'] = "Fra karantænelisten kan du se de kriterier, som Mailcleaner brugte til at betragte beskeden som spam via knappen \"Img src =\"/skabeloner /$skabelon /billeder /support /grunde.gif \"retter =\"mellemste \"alt =\"> knappen.Hvis du mener, at disse kriterier ikke er berettigede, kan du anmode om en analyse fra vores analysecenter ved at klikke på knappen “Img src =”skabeloner /$skabelon /billeder /support /analy.gif ” på \"mellemste\" alt =\"> knappen.Du kan også frigive beskeden ved at klikke på knappen […] Img src =]/skabeloner /$skabelon /billeder /support /force.gif =\"mellemste\" alt \">";
$txt['SFALSEPOSSUB3'] = "Nogle gange er visse mailinglister blokeret af Mailcleaner.Dette skyldes deres formatering, som ofte er meget lig spam.Du kan anmode om en analyse af disse meddelelser som forklaret ovenfor, og vores analysecenter vil sørge for at sætte disse mailinglister på hvide lister for at forhindre, at de blokeres i fremtiden.";
$txt['SOTHERTITLE'] = "ANDRE PROBLEMER";
$txt['SOTHER'] = "Oplever du andre problemer med din e-mail-modtagelse, og du har fulgt ovenstående procedurer uden positive resultater? Hvis ja, bedes du kontakte Mailcleaner Center for Analyse ved at udfylde denne formular.";
$txt['FAQTITLE'] = "Forstå Mailcleaner";
$txt['DOCTITLE'] = "Hjælp til brugergrænsefladen";
$txt['WEBDOCTITLE'] = "Online dokumentation";
$txt['DOCUMENTATION'] = "
                         <ul>
                           <li> <h2>Karantæne visning/handlinger</h2>
                              <ul>
                                <li> <h3>Adresse:</h3>
                                   vælg, hvilken adresse du vil se karantæne mails for.
                                </li>
                                <li> <h3>Tving (< img src = \"/skabeloner/$template/images/force.gif\" align = \"top\" alt = \"\" >):</h3>
                                   Klik på dette ikon for at frigive den tilsvarende besked. Beskeden vil blive videresendt direkte til din indbakke.
                                </li>
                                <li> <h3>få vist oplysninger (< img src = \"/skabeloner/$template/images/årsags.gif\" align = \"top\" alt = \"\" >):</h3>
                                   Hvis du vil se, hvorfor en meddelelse er blevet registreret som spam, skal du klikke på dette ikon. Du vil se Mailcleaner kriterier med tilsvarende scores. Scores ved 5 eller over, vil gøre en besked betragtes som en spam.
                                </li>
                                <li> <h3>Send til analyse (< img src = \"/skabeloner/$template/images/analyse.gif\" align = \"top\" alt = \"\" >):</h3>
                                   I tilfælde af en falsk positiv, skal du klikke på ikonet, der svarer til den uskyldige besked.  Feedback sendes til din administrator.
                                </li>
                                <li> <h3>filter indstillinger:</h3>
                                   Nogle filterindstillinger er tilgængelige, så du kan søge gennem din karantæne. Antallet af dage i karantænen, antallet af meddelelser pr. side og søgefelter for emne/destination. Udfyld dem, du vil bruge, og klik på \"Opdater\" for at anvende ændringerne.
                                </li>
                                <li> <h3>handling:</h3>
                                   Du kan slette (< img src = \"/skabeloner/$template/images/trash.gif\" align = \"top\" alt = \"\" >) den fulde karantæne, når du vil. Rememeber i karantæne bliver automatisk renset periodisk af systemet. Med denne indstilling kan du gøre det efter vilje.
                                   Du kan også anmode om en oversigt (< img src = \"/skabeloner/$template/images/summary.gif\" align = \"top\" alt = \"\" >) for karantænen. Dette er den samme opsummering som den, der sendes periodisk. Denne mulighed bare lader dig anmode om det på vilje.
                                </li>
                              </ul>
                           </li>
                           <li> <h2>parametre</h2>
                              <ul>
                                 <li> <h3>Indstillinger for bruger sprog:</h3>
                                    Vælg dit hovedsprog her. Du brugergrænseflade, resuméer og rapporter vil blive påvirket.
                                 </li>
                                 <li> <h3>aggregeret adresse/alias:</h3>
                                    Hvis du har mange adresser eller aliasser at aggregere til din Mailcleaner interface, bare bruge plus (< img src = \"/skabeloner/$template/images/plus.gif\" align = \"top\" alt = \"\" >) og minus (< img src = \"/skabeloner/$template/images/minus.gif\" align = \"til p \"alt =\" \">) for at tilføje eller fjerne adresser.
                                 </li>
                               </ul>
                            </li>
                            <li> <h2>per adresseindstillinger:</h2>
                              Nogle indstillinger kan konfigureres pr. adresse.
                              <ul>
                                 <li><h3>Anvend på alle knapper:</h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t  Brug denne til at anvende ændringer på alle adresserne.
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<li><h3>spam leveringsmåde:</h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t  Vælg, hvad Mailcleaner skal gøre med meddelelser, der registreres som spam.
  \t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t <ul>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t <li><h4>karantæne:</h4> meddelelser gemmes i karantæne og slettes periodisk. </li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t <li><h4>tag:</h4> spam vil ikke blive blokeret, men et mærke vil blive føjet til emnefeltet. </li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t <li><h4>drop:</h4> spam vil simpelthen blive droppet. Brug dette med forsigtighed, da det kan føre til besked tab. </li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t </ul>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<li><h3>karantæne bounces:</h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t  Denne indstilling vil medføre, at Mailcleaner kan sende meddelelser i karantæne og e-mail-fejl. Dette kan være nyttigt, hvis du er offer for massive hoppe e-mails på grund af for eksempel udbredte vira. Dette bør kun aktiveres for små omgange af tid, da det er meget farligt.
 \t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<li><h3>spam tag:</h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tVælg og tilpas den meddelelse, der vises i emnefeltet for tagget spam. Dette er irrelevent, hvis du har valgt karantæne leveringstilstand.
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<li><h3>rapporteringshyppighed:</h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t  Vælg den hyppighed, som du modtager karantæne oversigter med. Ved dette interval";
$txt['WEBDOC'] = "<ul><li>Mere information og dokumentation, der findes på vores websted: <a href=\"https://wiki2.mailcleaner.net/doku.php/documentation:userfaq\" target=\"_blank\">Mailcleaner bruger dokumentation</a></li></ul>";
