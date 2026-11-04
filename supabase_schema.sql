-- ============================================================================
-- QALAM STUDIO — SUPABASE COMPLETE DATABASE SCHEMA
-- Project ID: xwriwkeeiqagevbzhwcs
--
-- INSTRUCTIONS:
-- 1. Go to https://supabase.com/dashboard/project/xwriwkeeiqagevbzhwcs/sql
-- 2. Click "New query"
-- 3. Paste this entire SQL file and click "Run" (green button)
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS "public";

-- 1. User Accounts Table
CREATE TABLE IF NOT EXISTS "User" (
    "id" TEXT NOT NULL,
    "username" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "User_username_key" ON "User"("username");

-- 2. User Sessions Table
CREATE TABLE IF NOT EXISTS "Session" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "Session_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "Session_userId_idx" ON "Session"("userId");
CREATE INDEX IF NOT EXISTS "Session_expiresAt_idx" ON "Session"("expiresAt");

DO $$ BEGIN
  ALTER TABLE "Session" ADD CONSTRAINT "Session_userId_fkey" 
  FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 3. Core Design / Project Table
CREATE TABLE IF NOT EXISTS "Design" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL DEFAULT 'Untitled design',
    "width" INTEGER NOT NULL DEFAULT 1080,
    "height" INTEGER NOT NULL DEFAULT 1080,
    "pages" JSONB NOT NULL DEFAULT '[]',
    "thumbnail" TEXT,
    "source" TEXT NOT NULL DEFAULT 'blank',
    "ownerId" TEXT,
    "anonKey" TEXT,
    "deletedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Design_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "Design_ownerId_idx" ON "Design"("ownerId");
CREATE INDEX IF NOT EXISTS "Design_anonKey_idx" ON "Design"("anonKey");

DO $$ BEGIN
  ALTER TABLE "Design" ADD CONSTRAINT "Design_ownerId_fkey" 
  FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 4. Design Versions Table (Version History)
CREATE TABLE IF NOT EXISTS "DesignVersion" (
    "id" TEXT NOT NULL,
    "designId" TEXT NOT NULL,
    "label" TEXT NOT NULL DEFAULT 'Version',
    "name" TEXT NOT NULL,
    "width" INTEGER NOT NULL,
    "height" INTEGER NOT NULL,
    "pages" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "DesignVersion_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "DesignVersion_designId_createdAt_idx" ON "DesignVersion"("designId", "createdAt" DESC);

DO $$ BEGIN
  ALTER TABLE "DesignVersion" ADD CONSTRAINT "DesignVersion_designId_fkey" 
  FOREIGN KEY ("designId") REFERENCES "Design"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 5. Templates Table
CREATE TABLE IF NOT EXISTS "Template" (
    "id" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "width" INTEGER NOT NULL,
    "height" INTEGER NOT NULL,
    "pages" JSONB NOT NULL,
    "accent" TEXT NOT NULL DEFAULT '#00C4CC',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Template_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "Template_slug_key" ON "Template"("slug");

-- 6. Design Collaboration Events (Real-time op log)
CREATE TABLE IF NOT EXISTS "DesignEvent" (
    "id" BIGSERIAL NOT NULL,
    "designId" TEXT NOT NULL,
    "actorId" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "eventId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "DesignEvent_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "DesignEvent_designId_eventId_key" ON "DesignEvent"("designId", "eventId");
CREATE INDEX IF NOT EXISTS "DesignEvent_designId_id_idx" ON "DesignEvent"("designId", "id" DESC);

-- 7. Live Presence Table (Multi-user cursors & avatars)
CREATE TABLE IF NOT EXISTS "Presence" (
    "id" TEXT NOT NULL,
    "designId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "color" TEXT NOT NULL,
    "cursor" JSONB,
    "lastSeen" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Presence_pkey" PRIMARY KEY ("designId", "id")
);

CREATE INDEX IF NOT EXISTS "Presence_designId_lastSeen_idx" ON "Presence"("designId", "lastSeen");

-- 8. Canvas Comments Table
CREATE TABLE IF NOT EXISTS "Comment" (
    "id" TEXT NOT NULL,
    "designId" TEXT NOT NULL,
    "pageId" TEXT NOT NULL,
    "x" DOUBLE PRECISION NOT NULL,
    "y" DOUBLE PRECISION NOT NULL,
    "elementId" TEXT,
    "authorId" TEXT NOT NULL,
    "authorName" TEXT NOT NULL,
    "authorColor" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "parentId" TEXT,
    "resolved" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Comment_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "Comment_designId_createdAt_idx" ON "Comment"("designId", "createdAt");
CREATE INDEX IF NOT EXISTS "Comment_designId_resolved_idx" ON "Comment"("designId", "resolved");

-- 9. Media Store Table (Audio / Video / Large file uploads)
CREATE TABLE IF NOT EXISTS "Media" (
    "id" TEXT NOT NULL,
    "mime" TEXT NOT NULL,
    "size" INTEGER NOT NULL,
    "bytes" BYTEA NOT NULL,
    "ownerId" TEXT,
    "anonKey" TEXT,
    "finalizedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Media_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "Media_ownerId_idx" ON "Media"("ownerId");
CREATE INDEX IF NOT EXISTS "Media_anonKey_idx" ON "Media"("anonKey");
CREATE INDEX IF NOT EXISTS "Media_finalizedAt_createdAt_idx" ON "Media"("finalizedAt", "createdAt");

-- 10. AI Telemetry & Usage Accounting
CREATE TABLE IF NOT EXISTS "AIUsage" (
    "id" TEXT NOT NULL,
    "feature" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "ok" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "AIUsage_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "AIUsage_createdAt_idx" ON "AIUsage"("createdAt");

-- 11. Plugin Installs Table
CREATE TABLE IF NOT EXISTS "PluginInstall" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "pluginId" TEXT NOT NULL,
    "version" TEXT NOT NULL,
    "manifest" JSONB NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "PluginInstall_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "PluginInstall_userId_pluginId_key" ON "PluginInstall"("userId", "pluginId");
CREATE INDEX IF NOT EXISTS "PluginInstall_userId_idx" ON "PluginInstall"("userId");

-- 12. Plugin Assets Table
CREATE TABLE IF NOT EXISTS "PluginAsset" (
    "id" TEXT NOT NULL,
    "installId" TEXT NOT NULL,
    "path" TEXT NOT NULL,
    "mime" TEXT NOT NULL,
    "bytes" BYTEA NOT NULL,
    "sha256" TEXT NOT NULL,
    CONSTRAINT "PluginAsset_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "PluginAsset_installId_path_key" ON "PluginAsset"("installId", "path");

DO $$ BEGIN
  ALTER TABLE "PluginAsset" ADD CONSTRAINT "PluginAsset_installId_fkey" 
  FOREIGN KEY ("installId") REFERENCES "PluginInstall"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
