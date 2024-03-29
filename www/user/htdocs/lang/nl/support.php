<?php

$txt['SFALSENEGTITLE'] = "VALSE NEGATIEVEN";
$txt['SFALSENEGSUBTITLE'] = "Heeft u een bericht ontvangen dat u als spam beschouwt?";
$txt['SVERIFYPASS'] = "Controleer of het bericht verwerkt is door het Mailcleaner-filter door te kijken naar de e-mailkoppen.";
$txt['SMCLOGTITLE'] = "In de koppen staan de volgende regels die duiden op verwerking voor Mailcleaner:";
$txt['SMCLOGLINE1'] = "Ontvangen: van mailcleaner.net (filterdienst)";
$txt['SMCLOGLINE2'] = "door mailcleaner.net met esmtp (inkomende dienst)";
$txt['SMCFILTERINGLOG'] = "Resultaat van filteren: X-Mailcleaner-spamscore: oooo";
$txt['SFALSENEGTUTOR'] = "Als u er zeker van bent dat het bericht spam is, stuur het dan door naar spam@mailcleaner.net of, indien uw e-mailapplicatie dit toestaat, kies \"Versturen als bijlage\" zodat de e-mailkoppen intact blijven. We zullen de berichtinhoud analyseren en onze filtercriteria aanpassen zodat alle Mailcleaner-gebruikers hiervan profiteren.";
$txt['SFALSEPOSTITLE'] = "VALSE POSITIEVEN";
$txt['SFALSEPOSSUB1TITLE'] = "Heeft u een bericht niet ontvangen dat u wel had moeten ontvangen?";
$txt['SFALSEPOSSUB1'] = "U kunt controleren of het bericht geblokkeerd is door Mailcleaner via de web-interface onder de kop Quarantaine. Als u het bericht niet in de quarantainelijst ziet staan, controleer dan de volgende punten:";
$txt['SFALSEPOSSUB1POINT1'] = "het bestemmingsadres, zoals gebruikt door de afzender, is juist";
$txt['SFALSEPOSSUB1POINT2'] = "de e-mail heeft de kans gekregen om verwerkt te worden (dit kan een paar minuten duren)";
$txt['SFALSEPOSSUB2TITLE'] = "Heeft u een e-mail ontvangen die gemarkeerd is als spam maar u begrijpt niet waarom?";
$txt['SFALSEPOSSUB2'] = "In de quarantainelijst kunt u de door Mailcleaner gebruikte criteria bekijken via de <img src=\"/templates/$template/images/support/reasons.gif\" align=\"middle\" alt=\"\">-knop. Als u vindt dat deze criteria niet voldoen, dan kunt u een analyseverzoek doen aan ons analysecentrum via de <img src=\"/templates/$template/images/support/analyse.gif\" align=\"middle\" alt=\"\">-knop. U kunt het bericht ook vrijgeven via de <img src=\"/templates/$template/images/support/force.gif\" align=\"middle\" alt=\"\">-knop.";
$txt['SFALSEPOSSUB3TITLE'] = "Mailinglijsten";
$txt['SFALSEPOSSUB3'] = "Soms worden mailinglijsten geblokkeerd door Mailcleaner. Dit komt doordat hun opmaak vaak op spam lijkt. U kunt, zoals hierboven is uitgelegd, een analyseverzoek voor deze berichten doen. Ons analysecentrum zal deze mailinglijsten dan op de witte lijsten plaatsen zodat ze in de toekomst niet meer worden geblokkeerd.";
$txt['SOTHERTITLE'] = "ANDERE PROBLEMEN";
$txt['SOTHER'] = "Heeft u een ander soort probleem met het ontvangen van e-mails en heeft u de hierboven genoemde procedures gevolgd zonder positieve resultaten te verkrijgen? Neem dan contact op met het Mailcleaner-analysecentrum door dit formulier in te vullen.";
$txt['FAQTITLE'] = "Mailcleaner leren begrijpen";
$txt['DOCTITLE'] = "Hulp bij het gebruiken";
$txt['WEBDOCTITLE'] = "Online-documentatie";
$txt['FAQ'] = "
               <ul>
                 <li> <h2>Wat doet Mailcleaner?</h2>
                      Mailcleaner is a e-mailfilter dat uw inkomende berichten controleert op spam, bekende virussen en andere gevaarlijke inhoud om te voorkomen dat de berichten binnenkomen in uw mailbox. Mailcleaner is een serverdienst. Dit houdt in dat u geen software hoeft te installeren op uw computer. Dit wordt eigenlijk gedaan door de provider van uw e-mailaccount. Met deze webinterface bent u direct verbonden met het Mailcleaner-filter. U kunt hier geblokkeerde spamberichten bekijken en enkele filterinstellingen wijzigen.
                 </li>
                 <li> <h2>Wat is een spambericht?</h2>
                      Een spambericht is een ongewenst e-mailbericht. Meestal wordt dit gebruikt voor advertenties. Deze e-mails kunnen zich al snel ophopen in uw mailbox. Gelukkig zijn deze berichten meestal niet gevaarlijk.
                 </li>
                 <li> <h2>Wat zijn virussen en wat is gevaarlijke inhoud?</h2>
                      Virussen zijn kleine stukjes software die zich op uw computer kunnen nestelen en kwaadwillenden de controle over uw computer laten overnemen. Virussen kunnen worden verstuurd als e-mailbijlagen en uw systeem infecteren zodra u ze opent (sommige kunnen zelfs infecteren zonder geopend te worden). Gevaarlijke inhoud is hetzelfde, alleen kan dit gevaarlijker zijn omdat de inhoud verborgen kan zijn in het bericht of op afstand kan worden ingevoegd door een bouce-link. Deze zijn moeilijk te detecteren door een standaard e-mailfilter omdat het daadwerkelijke virus zich niet in het bericht bevindt. Mailcleaner inspecteert deze e-mails grondiger en voorkomt zo dat ze binnenkomen op uw computer.
                 </li>
                 <li> <h2>Mailcleaner anti-spam-criteria</h2>
                      Mailcleaner gebruikt een aantal tests om spam te detecteren, met een zo goed mogelijk resultaat. Mailcleaner gebruikt o.a. eenvoudige sleutelwoord of -zinsovereenkomsten, wereldwijde spam-databases en statistische token computing. Al deze criteria bij elkaar leven een berichtscore op. Afhankelijk van deze score zal Mailcleaner een definitief besluit nemen: spam of ham. Als spam snel voortbewegend doel is, dan worden deze regels ook zo snel mogelijk toegepast. Het is Mailcleaner's taak om deze instellingen zo goed mogelijk te behouden.
                 </li>
                 <li> <h2>Fouten</h2>
                      Mailcleaner is een geautomatiseerd filtersysteem en kan daarom ook fouten maken. Er zijn twee fouten die door Mailcleaner kunnen onstaan:
                      <ul>
                       <li> <h3>valse negatieven</h3> valse negatieven zijn spam-berichten die door het Mailcleaner-filter zijn geslopen en in uw mailbox terecht zijn gekomen door gedetecteerd te zijn. Deze zijn vervelend, maar zolang het bij een enkele blijft, zullen ze uw productiviteit nauwelijks beïnvloeden. Herinnert u zich nog dat u slechts een paar spamberichten per week kreeg? Mailcleaner reduceert het aantal tot minimaal een paar.
                       </li>
                       <li> <h3>valse positieven</h3> zijn vervelendere fouten omdat dit correcte e-mails zijn die worden geblokkeerd door het systeem. Als u de quarantaine nooit bekijkt of rapporten niet zorgvuldig leest, dan kunnen er op deze manier belangrijke berichten verloren gaan. Mailcleaner is geoptimaliseerd om dit soort fouten zoveel mogelijk te voorkomen. Tóch kan dit sporadisch voorkomen. Mailcleaner bevat daarom real-time-toegang tot de quarantaine en stelt periodieke rapporten samen om het verliezen van berichten te reduceren.
                       </li>
                      </ul>
                  </li>
                  <li> <h2>Wat kunt u doen om Mailcleaner te corrigeren?</h2>
                      Het beste dat u kunt doen is het filter corrigeren door feedback te sturen aan uw administrator. Het plaatsen van afzenders op de witte of zwarte lijst is NIET de beste oplossing omdat dit slechts een pleister op de wonde is (lees dit om meer informatie hierover te krijgen). Het beste is om het daadwerkelijke probleem aan te pakken. Dit kan alleen worden gedaan voor technische mensen, dus geef alstublieft feedback aan uw administrator.
                  </li>
                </ul>";
$txt['DOCUMENTATION'] = "
                         <ul>
                           <li> <h2>Quarantine view/actions</h2>
                              <ul>
                                <li> <h3>Address:</h3>
                                   select which address you want to see the messages quarantined for.
                                </li>
                                <li> <h3>force (<img src=\"/templates/$template/images/force.gif\" align=\"top\" alt=\"\">): </h3>
                                   click on this icon to release the corresponding message. It will then be forwarded directly in your mailbox.
                                </li>
                                <li> <h3>view informations (<img src=\"/templates/$template/images/reasons.gif\" align=\"top\" alt=\"\">): </h3>
                                   if you want to see why a message has been detected as spam, click on this icon. You will see the Mailcleaner criteria with corresponding scores. With a score equals or greater than 5, a message is cnosidered as a spam.
                                </li>
                                <li> <h3>send to analyse (<img src=\"/templates/$template/images/analyse.gif\" align=\"top\" alt=\"\">): </h3>
                                   in case a false positive, click on this icon corresponding to the innocent message in order to send a feedback to your administrator.
                                </li>
                                <li> <h3>filter options: </h3>
                                   you have some filter option to let you search through your quarantines. The number of days of the quarantine, the number of message per pages, and subject/destination search fields. Fill in those you want to use and click refresh in order to apply filters.
                                </li>
                                <li> <h3>action: </h3>
                                   you can there purge (<img src=\"/templates/$template/images/trash.gif\" align=\"top\" alt=\"\">) the full quarantine whenever you want. Rememeber the quarantines are automatically purged periodically by the system. This option let you do it now.
                                   You can also request a summary (<img src=\"/templates/$template/images/summary.gif\" align=\"top\" alt=\"\">) of the quarantine. This is the same summary that the one periodically sent. This option just let you request one now.
                                </li>
                              </ul>
                           </li>
                           <li> <h2>Parameters</h2>
                              <ul>
                                 <li> <h3>user language settings: </h3>
                                    choose you main language here. You interface, summaries and reports will be affected.
                                 </li>
                                 <li> <h3>aggregate address/alias: </h3>
                                    if you have many addresses or aliases to aggregate to your mailcleaner interface, just use the plus (<img src=\"/templates/$template/images/plus.gif\" align=\"top\" alt=\"\">) and minus (<img src=\"/templates/$template/images/minus.gif\" align=\"top\" alt=\"\">) sign to add or remove addresses.
                                 </li>
                               </ul>
                            </li>
                            <li> <h2>Per address settings</h2>
                              some settings may be configured on a per-address basis
                              <ul>
                                 <li><h3>apply to all button: </h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t  use this to apply changes to all the addresses.
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<li><h3>spam delivery mode: </h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t  choose what you want Mailcleaner to do with messages detected as spam.
  \t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t <ul>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t <li><h4>quarantine:</h4> messages are stored in the quarantine and deleted periodically.</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t <li><h4>tag:</h4> spams will not be blocked, but a mark will be appended to the subject.</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t <li><h4>drop:</h4> spams will simply be dropped. Use this with caution as it can lead to message lost.</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t </ul>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<li><h3>quarantine bounces: </h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t  this option will cause Mailcleaner to quarantine bounces message and mail failurs notification. This may be usefull if you are victim of massive bounces mails due to wide spread viruses for exemple. This should only be activated for a small laps of time because it is very dangerous.
 \t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<li><h3>spam tag: </h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tchoose and customize the message that will appears in the subject of tagged spams. This is useless if you have chosen the quarantine delivery mode.
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<li><h3>reports frequencies: </h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t  choose the frequency of your quarantine summaries. On this regular basis, you will recieve a mail with a log of spams detected and stored in the quarantine.
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</ul>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</ul>";
$txt['WEBDOC'] = "<ul><li>Op onze website vindt u meer informatie en online documentatie: <a href=\"http://wiki2.mailcleaner.net/doku.php/documentation:userfaq\" target=\"_blank\">Mailcleaner-gebruikersdocumentatie</a></li></ul>";
