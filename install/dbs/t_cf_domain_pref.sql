USE mc_config;
DROP TABLE IF EXISTS domain_pref;

CREATE TABLE domain_pref (
  id				 int(11) NOT NULL auto_increment,
  viruswall                      tinyint(1) NOT NULL DEFAULT '1',
  spamwall                       tinyint(1) NOT NULL DEFAULT '1',
  contentwall			 tinyint(1) NOT NULL DEFAULT '1',
  scanners                       varchar(50) NOT NULL DEFAULT 'clamav etrust',
  silent                         varchar(100) NOT NULL DEFAULT 'HTML-IFrame All-Viruses Zip-Password',
  block_bad_tnef                 tinyint(1) NOT NULL DEFAULT '0',
  block_encrypted                tinyint(1) NOT NULL DEFAULT '0', 
  block_unencrypted              tinyint(1) NOT NULL DEFAULT '0', 
  allow_passprotected_archives   tinyint(1) NOT NULL DEFAULT '0', 
  allow_partial                  tinyint(1) NOT NULL DEFAULT '0', 
  allow_external_bodies          tinyint(1) NOT NULL DEFAULT '0', 
  allow_iframe                   tinyint(1) NOT NULL DEFAULT '0', 
  allow_forms                    tinyint(1) NOT NULL DEFAULT '1',
  allow_scripts                  tinyint(1) NOT NULL DEFAULT '0', 
  allow_codebase                 tinyint(1) NOT NULL DEFAULT '0', 
  convert_danger_to_text         tinyint(1) NOT NULL DEFAULT '0', 
  convert_html_to_text           tinyint(1) NOT NULL DEFAULT '0', 
  notify_sender                  tinyint(1) NOT NULL DEFAULT '1', 
  notify_virus_sender            tinyint(1) NOT NULL DEFAULT '0', 
  notify_blocked_sender          tinyint(1) NOT NULL DEFAULT '1', 
  notify_blocked_content         tinyint(1) NOT NULL DEFAULT '1',
  virus_modify_subject           tinyint(1) NOT NULL DEFAULT '1', 
  virus_subject                  varchar(20) NOT NULL DEFAULT '{Virus?}',
  file_modify_subject            tinyint(1) NOT NULL DEFAULT '1', 
  file_subject                   varchar(20) NOT NULL DEFAULT '{Virus?}',
  content_modify_subject         tinyint(1) NOT NULL DEFAULT '1', 
  content_subject                varchar(20) NOT NULL DEFAULT '{Content?}',
  warning_attach                 tinyint(1) NOT NULL DEFAULT '1', 
  warning_filename               varchar(50) NOT NULL DEFAULT 'AttentionVirus.txt',
  warning_encoding_charset       varchar(20) NOT NULL DEFAULT 'ISO-8859-1',
  use_bayes                      tinyint(1) NOT NULL DEFAULT '1',
  bayes_autolearn                tinyint(1) NOT NULL DEFAULT '1',
  ok_languages                   varchar(50) NOT NULL DEFAULT 'fr en de it es',
  ok_locales                     varchar(50) NOT NULL DEFAULT 'fr en de it es',
  use_rbls                       tinyint(1) NOT NULL DEFAULT '1',
  rbls_timeout                   int(11) NOT NULL DEFAULT  '20',
  use_dcc                        tinyint(1) NOT NULL DEFAULT '1',
  dcc_timeout                    int(11) NOT NULL DEFAULT  '10',
  use_razor                      tinyint(1) NOT NULL DEFAULT '1',
  razor_timeout                  int(11) NOT NULL DEFAULT  '10',
  use_pyzor                      tinyint(1) NOT NULL DEFAULT '1',
  pyzor_timeout                  int(11) NOT NULL DEFAULT  '10',
  auth_type                      varchar(10) NOT NULL DEFAULT 'local',
  auth_param			 varchar(200),
  auth_server                    varchar(100) NOT NULL DEFAULT 'localhost',
  auth_modif                     varchar(100) NOT NULL DEFAULT 'at_add',
  address_fetcher		 varchar(10) NOT NULL DEFAULT 'at_login',
  allow_smtp_auth                tinyint(1) NOT NULL DEFAULT '0',
  smtp_auth_cachetime            int(11) NOT NULL DEFAULT '86400',
  delivery_type                  int(11) NOT NULL DEFAULT  '1',
  daily_summary                  tinyint(1) NOT NULL DEFAULT '0',
  weekly_summary                 tinyint(1) NOT NULL DEFAULT '1', 
  monthly_summary		 tinyint(1) NOT NULL DEFAULT '0',
  summary                        tinyint(1) NOT NULL DEFAULT '1',
  summary_freq                   int(11) NOT NULL DEFAULT  '1',
  summary_to                     varchar(200),
  spam_tag                       varchar(20) NOT NULL DEFAULT '{Spam?}',
  quarantine_bounces             tinyint(1) NOT NULL DEFAULT '0',
  language                       varchar(4) NOT NULL DEFAULT 'en',
  gui_displayed_spams            int(11) NOT NULL DEFAULT '20',
  gui_displayed_days             int(11) NOT NULL DEFAULT '7',
  gui_mask_forced                tinyint(1) NOT NULL DEFAULT '0',
  gui_default_address            varchar(200) DEFAULT '',
  gui_graph_type                 varchar(20) NOT NULL DEFAULT 'bar',
  gui_group_quarantines          tinyint(1) NOT NULL DEFAULT '0',
  web_template			 varchar(50) NOT NULL DEFAULT 'default',
  summary_template               varchar(50) NOT NULL DEFAULT 'default',
  summary_type                   varchar(20) NOT NULL DEFAULT 'html',
  report_template                varchar(50) NOT NULL DEFAULT 'default',
  support_email                  varchar(50),
  systemsender			 varchar(250),
  falseneg_to			 varchar(250),
  falsepos_to			 varchar(250),
  supportemail                   varchar(250),
  supportname                    varchar(250),
  presharedkey 			 varchar(100) DEFAULT '',
  enable_whitelists              tinyint(1) NOT NULL DEFAULT '0',
  enable_warnlists               tinyint(1) NOT NULL DEFAULT '0',
  enable_blacklists              tinyint(1) NOT NULL DEFAULT '0',
  notice_wwlists_hit             tinyint(1) NOT NULL DEFAULT '0',
  warnhit_template			      varchar(50) NOT NULL DEFAULT 'default',
  ldapcallout                    int(11),
  ldapcalloutserver              varchar(200),
  ldapcalloutparam               varchar(200),
  extcallout_type                varchar(200),
  extcallout_param               blob,
  addlist_posters                blob,
  archive_mail                   tinyint(1) NOT NULL DEFAULT '0',
  archive_spam                   tinyint(1) NOT NULL DEFAULT '0',
  copyto_mail                    varchar(250) DEFAULT '',
  acc_max_daily_users            int(11) NOT NULL DEFAULT 0,
  batv_check                     tinyint(1) NOT NULL DEFAULT '0',
  batv_secret                    varchar(200),
  prevent_spoof                  tinyint(1) NOT NULL DEFAULT '0',
  dkim_domain                    varchar(255),
  dkim_selector                  varchar(255),
  dkim_pkey                      blob,
  require_incoming_tls           tinyint(1) NOT NULL DEFAULT '0',
  require_outgoing_tls           tinyint(1) NOT NULL DEFAULT '0',
  allow_newsletters              tinyint(1) NOT NULL DEFAULT '0',
  reject_capital_domain          tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (id)
);

-- create default preferences set
INSERT INTO domain_pref SET id=1; 

 
