use mc_config;

DROP TABLE IF EXISTS mta_config;

CREATE TABLE mta_config (
  set_id			int(11) NOT NULL DEFAULT 1,
  stage				int(2) NOT NULL DEFAULT 1,
  header_txt			blob NOT NULL DEFAULT '',
  accept_8bitmime		enum('true','false') NOT NULL DEFAULT 'true',
  print_topbitchars		enum('true','false') NOT NULL DEFAULT 'true',
  return_path_remove		enum('true','false') NOT NULL DEFAULT 'true',
  ignore_bounce_after		char(10) NOT NULL DEFAULT '2d',
  timeout_frozen_after		char(10) NOT NULL DEFAULT '7d',
-- retry
  smtp_relay			enum('true','false') NOT NULL DEFAULT 'false',
  relay_from_hosts		blob,
  allow_relay_for_unknown_domains   bool NOT NULL DEFAULT '0',
  no_ratelimit_hosts            blob,
  smtp_enforce_sync             enum('true','false') NOT NULL DEFAULT 'true',
  allow_mx_to_ip        enum('true','false') NOT NULL DEFAULT 'false',
  smtp_receive_timeout		char(10) NOT NULL DEFAULT '30s',
  smtp_accept_max_per_host	int(10) NOT NULL DEFAULT 10,
  smtp_accept_max_per_trusted_host  int(10) NOT NULL DEFAULT 20,
  smtp_accept_max		int(10) NOT NULL DEFAULT 50,
  smtp_reserve          int(10) NOT NULL DEFAULT 5,
  smtp_load_reserve     int(10) NOT NULL DEFAULT 30,
  smtp_accept_queue_per_connection int(10) NOT NULL DEFAULT 10,
  smtp_accept_max_per_connection int(10) NOT NULL DEFAULT 100,
  smtp_conn_access		varchar(10000) DEFAULT '*',
  host_reject			blob,
  sender_reject			blob,
  recipient_reject		blob,
  user_reject			blob,
  verify_sender			bool NOT NULL DEFAULT '1',
  global_msg_max_size  char(50) DEFAULT '50M',
  max_rcpt			int(10) NOT NULL DEFAULT 1000,
  received_headers_max  int(10) NOT NULL DEFAULT 30,
  use_incoming_tls     bool NOT NULL DEFAULT '0',
  tls_certificate       char(50) NOT NULL DEFAULT 'default',
  tls_use_ssmtp_port    bool NOT NULL DEFAULT '0',
  tls_certificate_data  blob,
  tls_certificate_key   blob,
  hosts_require_tls     blob,
  domains_require_tls_from     blob,
  domains_require_tls_to     blob,
  hosts_require_incoming_tls  blob,
  use_syslog           bool NOT NULL DEFAULT '0',
  smtp_banner          varchar(255) NOT NULL DEFAULT '$smtp_active_hostname ESMTP Exim $version_number $tod_full',
  errors_reply_to      varchar(255) DEFAULT '',
  rbls                 varchar(255),
  rbls_timeout          int(10) DEFAULT 5,
  rbls_ignore_hosts     blob DEFAULT '',
  bs_rbls              varchar(255),
  rbls_after_rcpt       bool NOT NULL DEFAULT '1',
  callout_timeout       int(10) DEFAULT 10,
  retry_rule            varchar(255) NOT NULL DEFAULT 'F,4d,2m',
  ratelimit_enable      int(1) DEFAULT '0',
  ratelimit_rule        varchar(255) DEFAULT '30 / 1m / strict',
  ratelimit_delay       int(10) DEFAULT 10,
  trusted_ratelimit_enable  int(1) DEFAULT '0',
  trusted_ratelimit_rule    varchar(255) DEFAULT '60 / 1m / strict',
  trusted_ratelimit_delay   int(10) DEFAULT 10,
  outgoing_virus_scan   bool NOT NULL DEFAULT '0',
  mask_relayed_ip       bool NOT NULL DEFAULT '0',
  block_25_auth         bool NOT NULL DEFAULT '0',
  masquerade_outgoing_helo bool NOT NULL DEFAULT '0',
  forbid_clear_auth     bool NOT NULL DEFAULT '0',
  relay_refused_to_domains    blob,
  dkim_default_domain   varchar(255),
  dkim_default_selector varchar(255),
  dkim_default_pkey     blob,
  reject_bad_spf        bool NOT NULL DEFAULT '0',
  reject_bad_rdns       bool NOT NULL DEFAULT '0',
  dmarc_follow_reject_policy   bool NOT NULL DEFAULT '0',
  dmarc_enable_reports  bool NOT NULL DEFAULT '0',
  spf_dmarc_ignore_hosts blob DEFAULT '',
  log_subject bool NOT NULL DEFAULT '0',
  log_attachments bool NOT NULL DEFAULT '0',
  ciphers              varchar(255) NOT NULL DEFAULT 'SECURE256:+SECURE128:-VERS-TLS-ALL:+VERS-TLS1.2:-DHE-DSS:-CAMELLIA-128-CBC',
  allow_long		bool NOT NULL DEFAULT '1',
  folding		bool NOT NULL DEFAULT '0',
  PRIMARY KEY (set_id, stage)
);

INSERT INTO mta_config SET stage=1;

INSERT INTO mta_config SET stage=2;

INSERT INTO mta_config SET stage=4;

UPDATE mta_config SET tls_certificate_data='-----BEGIN CERTIFICATE-----
MIIDazCCAlOgAwIBAgIUQvGjAyONyjxDMdeoZijH7MKWxd0wDQYJKoZIhvcNAQEL
BQAwRTELMAkGA1UEBhMCQ0gxCjAIBgNVBAgMASAxFDASBgNVBAoMC01haWxDbGVh
bmVyMRQwEgYDVQQDDAttYWlsY2xlYW5lcjAeFw0yNDAxMjIxNzU3MTRaFw0zNDAx
MTkxNzU3MTRaMEUxCzAJBgNVBAYTAkNIMQowCAYDVQQIDAEgMRQwEgYDVQQKDAtN
YWlsQ2xlYW5lcjEUMBIGA1UEAwwLbWFpbGNsZWFuZXIwggEiMA0GCSqGSIb3DQEB
AQUAA4IBDwAwggEKAoIBAQCs0PFYVjF7COWgpHbIisisC52sR3wvon0HZf22vF40
Jx7vpGOnmi50mbzDrkN/MQGK57eeAq50UpqQq/GFH/h9nTaM3IDcEo94XiLZj239
zObW62IP7C8Iv5DCQwwYzrpS9EP15hcVH2UtCgUvZmkcNM3klP2nRi6bGp+xj+wd
ZjGr8eWUc47DXk4N8ffL34ulWWjtfYUDA9pB2yaM0pWlfJ729hQ/MsWCcyU5ULTO
olV5YZ8x8LYCTqxGnls8zqb9R8Q0WUOwS7mIW4C/+Haf21DLQkone547ulveWbhs
U0PwBXZAaxLWilNbgZTpDSL+GMNXpUFUyqBxaMwMe1t7AgMBAAGjUzBRMB0GA1Ud
DgQWBBQyQVzojeKp/ex2NXk8mo0sGR3a8zAfBgNVHSMEGDAWgBQyQVzojeKp/ex2
NXk8mo0sGR3a8zAPBgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQCf
GXcA3bJKJT63L3SETY5ZaPttNwwSIBwfDTWiCjEiZHfF/lV6aYHdS7GCK8pGB3WZ
F/qei/upQPgG8QykBQcKxmH759GGvi1GiFzJosvDqE+gmhZRssrjr7GBGSKIHzmV
zrtyplCFxOvO2r1V4OLfMWlnoiiFf52UVG+Lpmk+gdoQn38ytIw2LNblwKo7GXm+
Dzpoa5M4hE90P+eSaVSP6wVF06s6TiO9UrlVTS0cbDe2Snn4+9tDltQ0CEmbun6o
UPvaiGy1H4e3bcxIt4RXPI0JfIbLbX+lk31vQvvhqlE3pKlvabLvWVAg2qEA2ZjT
UhAhvL73nPKbsMwO+6+W
-----END CERTIFICATE-----' WHERE stage=1;

UPDATE mta_config SET tls_certificate_key='-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCs0PFYVjF7COWg
pHbIisisC52sR3wvon0HZf22vF40Jx7vpGOnmi50mbzDrkN/MQGK57eeAq50UpqQ
q/GFH/h9nTaM3IDcEo94XiLZj239zObW62IP7C8Iv5DCQwwYzrpS9EP15hcVH2Ut
CgUvZmkcNM3klP2nRi6bGp+xj+wdZjGr8eWUc47DXk4N8ffL34ulWWjtfYUDA9pB
2yaM0pWlfJ729hQ/MsWCcyU5ULTOolV5YZ8x8LYCTqxGnls8zqb9R8Q0WUOwS7mI
W4C/+Haf21DLQkone547ulveWbhsU0PwBXZAaxLWilNbgZTpDSL+GMNXpUFUyqBx
aMwMe1t7AgMBAAECggEAIiXvarstb9hkN4gICLyTxptM/rvpaCg9eHbI2ZEDNF7+
l+/t2TJ4N4YhbLFEmR9/5IjBGbIB8u5XqHqxcNLOcVPdcZwowlPQkcJYNJFI9LvG
aXV9nRPYf2wLGLfS7hv7aWTnAPIEYaIghfPS7njYEEDG5oIiVSljEDcEkzuTNoOl
eu2/NQWP93GC/98bQ4hTIWNFXkw36QBtsc4YnBEH6CMXcfZ6fQrIk+g703NBF8EE
CXgrFv8Rvb6ak8YFBLrqmIbiNVRKZjD9QBA2aggzy+i7GY5eaAj4gQiLkxxr1UJG
h6vl7RRTfwUL6BYG0RNb/Su+UHWuAkT5Xv2XXZJjUQKBgQDpsU8lqHKuZfG0EQrO
Qm6sG4wtXORkRFA5R4sk+6hfvXMEcYERSWtW5iGdx9KGQUNEipaJ0MbdmaG7BuTg
LQNJGlyamxmE8LD3PDJ6k9DgsISlHtfzDAjU57L/T63YaQVzlJEWrd/qSaVbEiyw
lJeF1a0kwKYdpXa1aJ4dVXzgfwKBgQC9UAK9+Cpe0qkpt0bbrTCxKt2+erP4HdwZ
wfoVsCEUABh6RzA1dThbOVeVXdJiXWlFTy3+RGCrC1KYPpDwoQOPyu4c+3LAtzwe
hAlER57U6iYZgC8xspHkIk925UG9bLTj47CEPj8UFVMj6Z1YROsETHGPZ1rlD02t
rJK7JViHBQKBgDbhpCPE5oHcgSH3qqD76v/STF5O5XhCrtB049GgpE8vr7ZIbbZA
lsvGqfhi+Cb9Zq3PGkFtXXanYNsKaG/ZQl9FqJ/KcvjMidLWOUieNDzAV7Zrgu2a
UuylKV1aOgqLx3L4XgaEeQSNnR7BKuuhSeBtaQcrkxd9R16dHhznebdDAoGBAI0U
u3ZnIuxXgcmc1CmR/9+IWohBWS1m00g+zuiqwXvuNk+qDbtJCB6ztRmTOd4kTvdf
8p6yxnexkHP07H7m/4iBasIegX4tD5iOPXmtBikV9h668HDQ6vhguWeZokxQXt4W
KM3ktY159uOkjaXidmJVtatxEsPxi6oKGa9uPXMhAoGALkkvCXKP5hX1uQ2DcKUk
Ogo0ZaGg60DF3//vEIQJxljmBMg7xDSlG8FR6pEPdrmFjkviVwU62r5dl8uW5n+4
Jz2ST172x71PjcwYNrKpZW6ZRdutDL01Srrx8u4oVLuT6w3jeUHyjLhYvvu63ZWJ
3rV5EMcPyP3F0N148qA8lB0=
-----END PRIVATE KEY-----' WHERE stage=1;
