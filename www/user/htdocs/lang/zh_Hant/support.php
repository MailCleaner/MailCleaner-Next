<?php

$txt['SFALSENEGTITLE'] = "遺漏";
$txt['SFALSENEGSUBTITLE'] = "您是否收到了您認為是垃圾的電子郵件？";
$txt['SVERIFYPASS'] = "通過查看電子郵件標頭，檢查郵件是否已由 Mailcleaner 篩選處理。";
$txt['SMCLOGTITLE'] = "在標題中，您將看到以下提及 Mailcleaner 的行為:";
$txt['SMCLOGLINE1'] = "接收:從 mailcleaner.net (過濾守護程序)";
$txt['SMCLOGLINE2'] = "由 mailcleaner.net 與 esmtp (過濾守護程序)";
$txt['SMCFILTERINGLOG'] = "過濾結果: X-Mailcleaner-spamscore: oooo";
$txt['SFALSENEGTUTOR'] = "如果您確實發現該郵件是垃圾郵件，請將其傳輸到 spam@mailcleaner.net，或者更好的是，如果您的電子郵件程序允許，請選擇 “傳輸為附件” 以保留電子郵件標題 消息完好無損。 我們的分析中心將傳播訊息的內容並相應地調整 Mailcleaner 的過濾標準，以便所有 Mailcleaner 用戶從分析中受益。";
$txt['SFALSEPOSTITLE'] = "誤報";
$txt['SFALSEPOSSUB1TITLE'] = "您沒有收到應有的訊息？";
$txt['SFALSEPOSSUB1'] = "您可以通過“隔離”標題下的用戶網路界面檢查郵件是否被 Mailcleaner 阻止。 如果您未在隔離列表中找到它，請驗證以下幾點：";
$txt['SFALSEPOSSUB1POINT1'] = "寄件人使用的目標地址是正確的";
$txt['SFALSEPOSSUB1POINT2'] = "電子郵件有可能會被處理（這個過程可能需要幾分鐘）";
$txt['SFALSEPOSSUB2TITLE'] = "電子郵件被認為是垃圾郵件，你不明白為什麼？";
$txt['SFALSEPOSSUB2'] = "從隔離列表中，您可以透過 <img src=\"/templates/$template/images/support/reasons.gif\" align=\"middle\" alt=\"\"> 查看 Mailcleaner 用於將郵件視為垃圾郵件的條件。按鈕。 如果您認為這些標準不合理，可以通過我們的分析中心點擊 <img src=\"/templates/$template/images/support/analyse.gif\" align=\"middle\" alt=\"\"> 按鈕。 您還可以通過單擊 <img src=\"/templates/$template/images/support/force.gif\" align=\"middle\" alt=\"\"> 按鈕來檢視訊息。";
$txt['SFALSEPOSSUB3TITLE'] = "郵件列表";
$txt['SFALSEPOSSUB3'] = "有時，Mailcleaner 會阻止某些郵件列表。 這是由於它們的格式化，這通常與垃圾郵件非常相似。 您可以按照上面的說明請求對這些訊息進行分析，我們的分析中心將負責將此類郵件列表放在白名單上，以防止它們在將來被阻止。";
$txt['SOTHERTITLE'] = "其他問題";
$txt['SOTHER'] = "您是否在接收電子郵件時遇到任何其他問題？您是否遵循了上述程序而沒有取得積極成果？ 如果是這樣，請填寫此表單與 Mailcleaner 分析中心聯繫。";
$txt['FAQTITLE'] = "了解 Mailcleaner";
$txt['DOCTITLE'] = "用戶界面幫助";
$txt['WEBDOCTITLE'] = "線上文件";
$txt['FAQ'] = "
               <ul>
                 <li> <h2>Mailcleaner 是在做什麼？</h2>
                      Mailcleaner 是一個電子郵件過濾器，可以檢查傳入的郵件是否存在已知的垃圾郵件，病毒和其他危險內容，從而避免它到達您的桌面。 它是伺服器端解決方案，這意味著您的系統上沒有安裝任何軟體來過濾您的電子郵件。 這實際上是由您的電子郵件帳戶提供商完成的。 使用基於Web的界面，您可以直接連接到 Mailcleaner 過濾器，您可以從該過濾器調整過濾器的某些設置，並查看所有被阻止的垃圾郵件。
                 </li>
                 <li> <h2>什麼是垃圾郵件？</h2>
                      垃圾郵件是未經請求或不受歡迎的電子郵件。 通常用於廣告，這些訊息可以快速填滿您的收件箱。 這些訊息通常並不危險，但仍然非常煩人。
                 </li>
                 <li> <h2>什麼是病毒和危險內容？</h2>
                      病毒是一種小型軟體，能夠利用並讓惡意攻擊者控制您的電腦。 這些可以作為附件通過電子郵件發送給您，並在打開後感染您的系統（有些甚至可以在不打開的情況下啟用）。 危險內容是相同的，除了它可以通過更智慧的方式啟用，直接隱藏在郵件內容中，甚至通過反彈鏈接進入電子郵件的目標。 這些很難通過使用標準電子郵件過濾器來檢測，因為真正的病毒並未真正包含在郵件中。 Mailcleaner會執行更多檢查，以防止可能存在風險的電子郵件到達您的收件箱。
                 </li>
                 <li> <h2>Mailcleaner 反垃圾郵件標準</h2>
                     Mailcleaner 使用多種測試來盡可能準確地檢測垃圾郵件。 它使用簡單的關鍵字或關鍵詞相符，全球垃圾數據庫和統計偵測與計算等等。 所有這些標準的匯總將給出每條訊息的總體分數，Mailcleaner 將做出最終決定：垃圾郵件或正常郵件。 由於垃圾郵件是一個非常快速移動的目標，因此這些規則也會盡快適應。 這是 Mailcleaner 的工作，以保持這些設置盡可能好。
                 </li>
                 <li> <h2>錯誤</h2>
                     由於Mailcleaner是一個自動過濾系統，因此也容易出錯。 Mailcleaner 基本上可以生成兩種錯誤：
                      <ul>
                       <li> <h3>遺漏</h3> 遺漏原因是因為垃圾郵件，它們設法通過 Mailcleaner 過濾器並在未被檢測到的情況下到達您的收件箱。 這些都很煩人，但只要出現相對罕見，工作效率就不會有很大的損失。 還記得每週只收到幾封垃圾郵件嗎？ Mailcleaner 至少可以讓你回到這一點。
                       </li>
                       <li> <h3>誤報</h3> 這些是更令人討厭的錯誤，因為它們是有效電子郵件被系統阻止的結果。 如果您不夠警惕並且未仔細檢查隔離區或報告，則可能導致丟失重要訊息。 Mailcleaner 經過最佳處理，可以盡可能地減少這些錯誤。 然而，儘管非常罕見，但這可能發生。 這就是為什麼 Mailcleaner 包含實時隔離訪問和定期報告，以幫助您最大限度地降低郵件丟失的風險。
                       </li>
                      </ul>
                  </li>
                  <li> <h2>你可以做些什麼來糾正 Mailcleaner</h2>
                      在 Mailcleaner 出錯時，最好的辦法是通過向管理員發送反應來協助糾正過濾器。 不要認為最好的解決方案是發送白名單或黑名單，因為這只是一種快速但又髒的方式（請查看此信息以獲取更多信息）。 雖然它有時是唯一的可能性，但最好找出錯誤的真正原因並予以糾正。 這只能由技術人員完成，因此請不要猶豫，將錯誤後的反應發送給您的管理員。
                  </li>
                </ul>";
$txt['DOCUMENTATION'] = "
                         <ul>
                           <li> <h2>隔離 檢視/操作</h2>
                              <ul>
                                <li> <h3>地址:</h3>
                                   選擇要查看隔離的郵件的地址。
                                </li>
                                <li> <h3>Force (<img src=\"/templates/$template/images/force.gif\" align=\"top\" alt=\"\">): </h3>
                                   點擊此圖示可以釋放相對應的訊息。 它會直接轉發到您的收件箱。
                                </li>
                                <li> <h3>查看訊息 (<img src=\"/templates/$template/images/reasons.gif\" align=\"top\" alt=\"\">): </h3>
                                   如果您想查看郵件被檢測為垃圾郵件的原因，請單擊此圖示。 您將看到具有相應分數的 Mailcleaner 標準。 5分或以上的分數會將郵件視為垃圾郵件。
                                </li>
                                <li> <h3>發送到分析 (<img src=\"/templates/$template/images/analyse.gif\" align=\"top\" alt=\"\">): </h3>
                                  如果出現誤報，請單擊與無辜訊息對應的圖示，以向管理員發送反應。
                                </li>
                                <li> <h3>過濾選項: </h3>
                                   您可以使用某些過濾器選項來搜索隔離區。 隔離區中的天數，每頁的郵件數以及主題/目標搜尋字段。 填寫您要使用的那些，然後點擊“重新整理”來套用。
                                </li>
                                <li> <h3>Action: </h3>
                                   你可以清除 (<img src=\"/templates/$template/images/trash.gif\" align=\"top\" alt=\"\">) 隨時可以完全隔離。 請記住，系統會定期自動清除隔離區。 此選項允許您隨意執行此操作。
                                   您也可以申請摘要 (<img src=\"/templates/$template/images/summary.gif\" align=\"top\" alt=\"\">) 檢疫。 這與定期發送的摘要相同。 此選項只允許您隨意請求。
                                </li>
                              </ul>
                           </li>
                           <li> <h2>參數</h2>
                              <ul>
                                 <li> <h3>使用者語言設定: </h3>
                                    在這裡選擇主要語言。 您的界面，摘要和報告將受到影響。
                                 </li>
                                 <li> <h3>總計 地址/別名: </h3>
                                    如果您有許多地址或別名聚合到您的 Mailcleaner 界面，只需使用加號 (<img src=\"/templates/$template/images/plus.gif\" align=\"top\" alt=\"\">) 和減號 (<img src=\"/templates/$template/images/minus.gif\" align=\"top\" alt=\"\">) 用於添加或刪除郵件地址。
                                 </li>
                               </ul>
                            </li>
                            <li> <h2>每個地址設置: </h2>
                             某些設置可以基於每個地址進行配置。
                              <ul>
                                 <li><h3>適用於所有按鈕: </h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t  使用此選項可將更改應用於所有地址。
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<li><h3>垃圾郵件傳遞模式: </h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t  選擇您希望 Mailcleaner 如何處理被檢測為垃圾郵件的方式。
  \t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t <ul>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t <li><h4>Quarantine:</h4> 郵件存儲在隔離區中並定期刪除。</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t <li><h4>標籤:</h4>垃圾郵件不會被阻止，但標記將被附加到主題字段。</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t <li><h4>Drop:</h4> 垃圾郵件將被刪除。 請謹慎使用，因為它可能導致郵件丟失。</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t </ul>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<li><h3>隔離反彈: </h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t  此選項將導致 Mailcleaner 隔離退回郵件和電子郵件失敗通知。 如果您是由於例如廣泛的病毒導致的大量反彈電子郵件的受害者，這可能是有用的。 這應該只在很短的時間內激活，因為它非常危險。
 \t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<li><h3>垃圾郵件標籤: </h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t選擇並自定義標記為垃圾郵件的主題字段中顯示的郵件。 如果您選擇了隔離傳送模式，這是無關緊要的。
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<li><h3>報告頻率: </h3>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t  選擇接收隔離報告頻率。 在此時間間隔內，您將收到一封電子郵件，其中包含檢測到的垃圾郵件日誌並將其存儲在隔離區中。
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</ul>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</ul>";
$txt['WEBDOC'] = "<ul><li>更多資訊和文檔可在我們的網站上找到: <a href=\"https://wiki2.mailcleaner.net/doku.php/documentation:userfaq\" target=\"_blank\">郵件清理程式使用者文檔件</a></li></ul>";
