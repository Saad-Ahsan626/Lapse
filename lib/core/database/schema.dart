const databaseFileName = 'lapse.db';

const schemaVersion = 1;

abstract final class Tables {
  static const subscriptions = 'subscriptions';
  static const charges = 'charges';
}

const schemaV1 = [
  '''
  CREATE TABLE subscriptions (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    catalog_key TEXT,
    category TEXT,
    price_minor INTEGER NOT NULL,
    currency TEXT NOT NULL,
    period TEXT NOT NULL,
    custom_days INTEGER,
    anchor_day INTEGER NOT NULL,
    start_date TEXT NOT NULL,
    next_billing_date TEXT NOT NULL,
    is_trial INTEGER NOT NULL DEFAULT 0,
    reminder_offsets TEXT NOT NULL,
    cancel_url TEXT,
    payment_method TEXT,
    notes TEXT,
    status TEXT NOT NULL,
    cancelled_at TEXT,
    snoozed_until TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE charges (
    id TEXT PRIMARY KEY,
    subscription_id TEXT NOT NULL
      REFERENCES subscriptions(id) ON DELETE CASCADE,
    amount_minor INTEGER NOT NULL,
    currency TEXT NOT NULL,
    charged_on TEXT NOT NULL
  )
  ''',
  '''
  CREATE INDEX idx_subscriptions_next
    ON subscriptions(status, next_billing_date)
  ''',
  '''
  CREATE INDEX idx_charges_subscription
    ON charges(subscription_id, charged_on)
  ''',
];
