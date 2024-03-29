<?php

$txt['DOCUMENTATION'] = "
                         <ul>
                           <li> <h2>Karantina görünümü/eylemleri</h2>
                              <ul>
                                <li> <h3>Adres:</h3>
                                   karantinaya alınan mesajları görmek istediğiniz adresi seçin.
                                </li>
                                <li> <h3>Serbest bırak (<img src=\"/templates/$template/images/force.gif\" align=\"top\" alt=\"\">): </h3>
                                   İlgili mesajı serbest bırakmak için bu simgeye tıklayın. Doğrudan gelen kutunuza iletilecektir.
                                </li>
                                <li> <h3>Bilgileri görüntüle (<img src=\"/templates/$template/images/reasons.gif\" align=\"top\" alt=\"\">): </h3>
                                   Bir mesajın neden spam olarak algılandığını görmek istiyorsanız, bu simgeye tıklayın. Mailcleaner ölçütlerini karşılık gelen puanlarla göreceksiniz. 5 veya üzerindeki puanlar, bir mesajın spam olarak kabul edilmesini sağlayacaktır.
                                </li>
                                <li> <h3>Çözümlemeye gönder (<img src=\"/templates/$template/images/analyse.gif\" align=\"top\" alt=\"\">): </h3>
                                   Yanlış bir pozitif olması durumunda, yöneticinize geri bildirim göndermek için masum mesaja karşılık gelen simgeye tıklayın.
                                </li>
                                <li> <h3>Filtre seçenekleri: </h3>
                                   Karantinalarınızda arama yapmanıza izin veren bazı filtre seçenekleri vardır. Karantinadaki gün sayısı, sayfa başına mesaj sayısı ve konu/hedef arama alanları. Kullanmak istediklerinizi doldurun ve \"Yenile\" düğmesine tıklayın.
                                </li>
                                <li> <h3>Eylem: </h3>
                                   Karantinanın tamamını istediğiniz zaman (<img src=\"/templates/$template/images/trash.gif\" align=\"top\" alt=\"\">) temizleyebilirsiniz. Karantinaların sistem tarafından belirli aralıklarla otomatik olarak temizlendiğini unutmayın. Bu seçenek, bunu istediğiniz zaman yapmanızı sağlar.
                                   Ayrıca karantinanın bir özetini (<img src=\"/templates/$template/images/summary.gif\" align=\"top\" alt=\"\">) isteyebilirsiniz. Bu, belirli aralıklarla gönderilen ile aynı özettir. Bu seçenek bunu istediğiniz zaman istemenizi sağlar.
                                </li>
                              </ul>
                           </li>
                           <li> <h2>Parametreler</h2>
                              <ul>
                                 <li> <h3>Kullanıcı dili ayarları: </h3>
                                    Buradan ana dilinizi seçin. Arayüzünüz, özetler ve raporlar bundan etkilenecektir.
                                 </li>
                                 <li> <h3>Toplu adres/takma ad: </h3>
                                    Mailcleaner arayüzünüzde toplayacağınız çok sayıda adresiniz veya takma adınız varsa, adres eklemek veya kaldırmak için artı (<img src=\"/templates/$template/images/plus.gif\" align=\"top\" alt=\"\">) ve eksi (<img src=\"/templates/$template/images/minus.gif\" align=\"top\" alt=\"\">) işaretlerine tıklayın.
                                 </li>
                               </ul>
                            </li>
                            <li> <h2>Adrese özel ayarlar: </h2>
                              Bazı ayarlar adrese özel yapılandırılabilir.
                              <ul>
                                 <li><h3>Tümüne uygula düğmesi </h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t  Değişiklikleri tüm adreslere uygulamak için bunu kullanın.
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<li><h3>Spam teslim modu: </h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t  Mailcleaner'ın spam olarak algılanan mesajlarla ne yapmasını istediğinizi seçin.
  \t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t <ul>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t <li><h4>Karantina:</h4> Mesajlar karantinada saklanır ve belirli aralıklarla silinir.</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t <li><h4>Etiketle:</h4> Spam engellenmeyecek, ancak konu alanının sonuna bir işaret eklenecek.</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t <li><h4>Düşür:</h4> Spam düşürülecektir. Mesaj kaybına neden olabileceği için bunu dikkatli kullanın.</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t </ul>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<li><h3>Geri dönmeleri karantinaya al: </h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t  Bu seçenek Mailcleaner'ın geri dönen mesaj ve e-posta hatası bildirimlerini karantinaya almasına neden olur. Yaygın virüsler gibi nedenlerle çok büyük sayıda geri dönen e-postaların kurbanıysanız, bu yararlı olabilir. Bu, çok tehlikeli olduğu için yalnızca kısa bir süre için etkinleştirilmelidir.
 \t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<li><h3>Spam etiketi: </h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tEtiketlenen spamın konu alanında görünen mesajı seçin ve özelleştirin. Karantina dağıtım modunu seçtiyseniz, bunun önemi yoktur.
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<li><h3>Raporlama sıklığı: </h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t  Karantina özetleri alma sıklığınızı seçin. Bu aralıkta, tespit edilen ve karantinada saklanan spam günlüğünü içeren bir e-posta alacaksınız.
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</ul>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</ul>";
$txt['FAQ'] = "
               <ul>
                 <li> <h2>Mailcleaner ne yapmaktadır?</h2>
                      Mailcleaner, gelen mesajlarınızı bilinen spam, virüsler ve diğer tehlikeli içeriklere karşı denetleyerek, masaüstünüze bile ulaşmamasını sağlayan bir e-posta filtresidir. Bu,sunucu tarafı bir çözümdür, yani e-postalarınızı filtrelemek için sisteminizde herhangi bir yazılımın kurulu olmadığı anlamına gelir. Bu aslında e-posta hesabı sağlayıcınız tarafından yapılır. Web tabanlı arayüzle, doğrudan Mailcleaner filtresine bağlanırsınız, buradan filtrenin bazı ayarlarını değiştirebilir ve engellenen tüm spamları görebilirsiniz.
                 </li>
                 <li> <h2>Spam nedir?</h2>
                      Spam, istenmeyen e-posta mesajlarıdır. Genellikle reklamlar için kullanılan bu mesajlar, gelen kutunuzu hızla doldurabilir. Bu mesajlar genellikle tehlikeli değildir ancak yine de gerçekten can sıkıcıdır.
                 </li>
                 <li> <h2>Virüsler ve tehlikeli içerik nedir?</h2>
                      Virüsler, kötü niyetli kişilerin bilgisayarınızın denetimini ele geçirmesine izin veren küçük yazılımlardır. Bunlar size e-postayla ek olarak gönderilebilir ve açıldığında sisteminize bulaşabilir (bazıları açılmadan bile etkinleştirilebilir). Tehlikeli içerik, daha akıllı yollarla etkinleştirilebilmesi, doğrudan mesajın içeriğinde saklanabilmesi ve hatta e-postaya geri dönen bir bağlantıyla dışarıdan hedef alınabilmesi dışında aynıdır. Bunların standart e-posta filtreleri kullanılarak tespit edilmesi çok zordur, çünkü gerçek virüs mesaja gerçekten dahil edilmemiştir. Mailcleaner, olası riskli e-postaların gelen kutunuza ulaşmasını önlemek için bundan daha fazla denetim gerçekleştirir.
                 </li>
                 <li> <h2>Mailcleaner spamdan koruma ölçütleri</h2>
                      Mailcleaner, spamları mümkün olan en iyi doğrulukla tespit etmek için bir dizi test kullanır. Diğerlerinin yanı sıra, basit anahtar kelime veya anahtar cümle eşleştirme, dünya çapında spam veri tabanları ve istatistiksel belirteç hesaplama kullanır. Tüm bu ölçütlerin bir araya getirilmesi, her mesaj için genel bir puan verecek ve Mailcleaner son kararı verecektir: Spam veya ham. Spam gerçekten hızlı değişen bir hedef olduğundan, bu kurallar da olabildiğince hızlı uyarlanır. Bu ayarları olabildiğince iyi tutmak Mailcleaner'ın işidir.
                 </li>
                 <li> <h2>Hatalar</h2>
                      Mailcleaner otomatik bir filtreleme sistemi olduğu için hatalara da meyillidir. Mailcleaner tarafından yapılabilecek temelde iki tür hata vardır:
                      <ul>
                       <li> <h3>Yanlış negatifler</h3> Yanlış negatifler, Mailcleaner filtresinden geçip tespit edilmeden gelen kutunuza ulaşmayı başaran spam mesajlarıdır. Bunlar can sıkıcıdır, ancak olay nispeten nadir olduğu sürece, işteki üretkenliğiniz için önemli bir kayba neden olmayacaktır. Her hafta yalnızca birkaç spam mesaj aldığınızı hatırlıyor musunuz? Mailcleaner sizi en azından bu noktaya geri götürebilir.
                       </li>
                       <li> <h3>Yanlış pozitifler</h3> Bunlar, geçerli e-postaların sistem tarafından engellenmesinden kaynaklandığı için daha can sıkıcı hatalardır. Yeterince tetikte değilseniz ve karantinanızı veya raporlarınızı dikkatlice denetlemezseniz, bu önemli mesajların kaybolmasına neden olabilir. Mailcleaner, bu hataları olabildiğince azaltmak için iyileştirilmiştir. Ancak çok nadir de olsa bu olabilir. Bu nedenle Mailcleaner, mesaj kaybı riskini en aza indirmenize yardımcı olmak için gerçek zamanlı karantina erişimi ve belirli aralıklarla raporlar içerir.
                       </li>
                      </ul>
                  </li>
                  <li> <h2>Mailcleaner'ı düzeltmek için ne yapabilirsiniz?</h2>
                      Mailcleaner hataları durumunda yapılacak en iyi şey, yöneticinize geri bildirim göndererek filtreyi düzeltmeye yardımcı olmaktır. En iyi çözümün gönderenleri beyaz veya kara listeye almak olduğunu düşünmeyin, çünkü bu hızlı ama kirli bir yoldur (daha fazla bilgi için buna bakın). Bazen tek olasılık bu olsa da, hatanın gerçek nedenini bulmak ve düzeltmek her zaman daha iyidir. Bu yalnızca teknik kişiler tarafından yapılabilir, bu nedenle, yöneticinize hataların ardından geri bildirim göndermekten çekinmeyin.
                  </li>
                </ul>";
$txt['WEBDOC'] = "<ul><li>Daha fazla bilgi ve belgelendirme web sitemizde bulunabilir: <a href=\"https://wiki2.mailcleaner.net/doku.php/documentation:userfaq\" target=\"_blank\">Mailcleaner kullanıcı belgelendirmesi</a></li></ul>";
$txt['WEBDOCTITLE'] = "Çevrim içi belgelendirme";
$txt['DOCTITLE'] = "Kullanıcı arayüzü yardımı";
$txt['FAQTITLE'] = "Mailcleaner'ı anlamak";
$txt['SOTHER'] = "E-posta alımınızla ilgili başka sorunlar yaşıyor ve yukarıdaki işlemleri uyguladınız ama olumlu sonuçlar alamadınız mı? Öyleyse, lütfen bu formu doldurarak Mailcleaner Çözümleme Merkezi ile iletişime geçin.";
$txt['SOTHERTITLE'] = "DİĞER SORUNLAR";
$txt['SFALSEPOSSUB3'] = "Bazen, belirli e-posta listeleri Mailcleaner tarafından engellenir. Bunun nedeni, genellikle spama çok benzeyen biçimlendirmeleridir. Yukarıda açıklandığı gibi bu mesajların çözümlemesini talep edebilirsiniz ve çözümleme merkezimiz bu tür e-posta listelerinin ileride engellenmemesi için beyaz listelere koyulmasına özen gösterecektir.";
$txt['SFALSEPOSSUB3TITLE'] = "E-posta listeleri";
$txt['SFALSEPOSSUB2'] = "Karantina listesinden, Mailcleaner'ın iletiyi spam olarak kabul etmek için kullandığı ölçütleri <img src=\"/templates/$template/images/support/reasons.gif\" align=\"middle\" alt=\"\"> düğmesi aracılığıyla görüntüleyebilirsiniz. Bu ölçütlerin haklı olmadığını düşünüyorsanız, <img src=\"/templates/$template/images/support/analyse.gif\" align=\"middle\" alt=\"\"> düğmesine tıklayarak çözümleme merkezimizden bir çözümleme isteyebilirsiniz. <img src=\"/templates/$template/images/support/force.gif\" align=\"middle\" alt=\"\"> düğmesine tıklayarak da mesajı serbest bırakabilirsiniz.";
$txt['SFALSEPOSSUB2TITLE'] = "Bir e-posta spam olarak kabul edildi ve nedenini anlamadınız mı?";
$txt['SFALSEPOSSUB1POINT2'] = "e-postanın işlenme şansı vardı (birkaç dakika sürebilen bir işlem)";
$txt['SFALSEPOSSUB1POINT1'] = "gönderen tarafından kullanılan hedef adres doğru";
$txt['SFALSEPOSSUB1'] = "Mesajın Mailcleaner tarafından engellenip engellenmediğini görmek için kullanıcı web arayüzünün \"Karantina\" başlığı altına bakabilirsiniz. Karantina listesinde bulamazsanız, lütfen aşağıdaki noktaları doğrulayın:";
$txt['SFALSEPOSSUB1TITLE'] = "Almanız gereken bir mesajı almadınız mı?";
$txt['SFALSEPOSTITLE'] = "YANLIŞ POZİTİFLER";
$txt['SFALSENEGTUTOR'] = "Mesajın gerçekten spam olduğunu fark ederseniz, lütfen spam@mailcleaner.net adresine aktarın veya daha iyisi, e-posta programınız izin veriyorsa, e-posta başlıklarını olduğu gibi tutmak için \"Ek olarak aktar\" seçeneğini seçin. Çözümleme merkezimiz, mesajın içeriğini yayacak ve Mailcleaner'ın filtreleme ölçütlerini buna göre uyarlayacak, böylece tüm Mailcleaner kullanıcıları çözümlemeden faydalanacaktır.";
$txt['SMCFILTERINGLOG'] = "Filtreleme sonucu: X-Mailcleaner-spamscore: oooo";
$txt['SMCLOGLINE2'] = "mailcleaner.net tarafından esmtp ile (gelen arka plan programı)";
$txt['SMCLOGLINE1'] = "Alındı: mailcleaner.net (filtreleme arka plan programı)";
$txt['SMCLOGTITLE'] = "Başlıklarda Mailcleaner'dan bahseden aşağıdaki satırları göreceksiniz:";
$txt['SVERIFYPASS'] = "E-posta başlıklarına bakarak mesajın Mailcleaner filtresi tarafından işlenip işlenmediğini denetleyin.";
$txt['SFALSENEGSUBTITLE'] = "Spam olduğunu düşündüğünüz bir mesaj mı aldınız?";
$txt['SFALSENEGTITLE'] = "YANLIŞ NEGATİFLER";
