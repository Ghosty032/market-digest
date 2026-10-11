-- Runs once, on the first start with an empty pg_data volume.
CREATE DATABASE digest;
\c digest

CREATE TABLE articles (
  url         TEXT PRIMARY KEY,            -- dedupe key
  source      TEXT NOT NULL,               -- 'cafemutual' | 'moneycontrol'
  section     TEXT,                        -- page it was found on, e.g. 'industry', 'economy'
  title       TEXT NOT NULL,
  category    TEXT NOT NULL DEFAULT 'uncategorised',
  sent        BOOLEAN NOT NULL DEFAULT FALSE,
  fetched_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_articles_unsent ON articles (sent, category) WHERE sent = FALSE;

-- Keyword regex matched against the article title. Lowest priority number wins (first match).
-- Patterns are JavaScript regex, case-insensitive unless case_sensitive = TRUE.
CREATE TABLE category_rules (
  priority        INT  NOT NULL,
  category        TEXT NOT NULL,
  pattern         TEXT NOT NULL,
  case_sensitive  BOOLEAN NOT NULL DEFAULT FALSE,
  source          TEXT              -- NULL = all sources
);
INSERT INTO category_rules (priority, category, pattern, case_sensitive, source) VALUES
  (1, 'SEBI & AMFI',   '\b(SEBI|AMFI)\b', TRUE, NULL),
  (1, 'SEBI & AMFI',   '\b(circular|consultation paper|TER|MFDs?|SIFs?|NISM)\b', FALSE, NULL),
  (2, 'Insurance',     '\b(IRDAI|insurance|insurers?|LIC|policyholders?)\b', FALSE, NULL),
  (3, 'Global News',   '\b(tariffs?|trade (deal|pact|agreement|war)|FTA|sanctions?|ceasefire|war|geopolitic\w*|OPEC|BRICS|G20|G7|crude)\b', FALSE, NULL),
  (4, 'US Market',     '\b(Wall Street|Dow Jones|Nasdaq|S&P 500|FOMC|Federal Reserve|Powell|US Treasury)\b', FALSE, NULL),
  (4, 'US Market',     '\b(Fed|US Fed)\b', TRUE, NULL),
  (5, 'Indian Market', '\b(Sensex|Nifty|FIIs?|FPIs?|DIIs?|RBI|Dalal Street|equity outlook|equity flows)\b', FALSE, NULL),
  (9, 'MF Industry',   '.', FALSE, 'cafemutual');
