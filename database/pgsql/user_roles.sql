CREATE TABLE "user_roles" (
  "uid" integer DEFAULT 0 NOT NULL,
  "rid" integer DEFAULT 0 NOT NULL,
  CONSTRAINT user_roles_pkey PRIMARY KEY ("uid", "rid")
);

CREATE INDEX idx_user_roles_rid ON user_roles (rid);
