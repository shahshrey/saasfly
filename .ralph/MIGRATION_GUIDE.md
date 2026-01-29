# QuickCarousals Database Migration Guide

This guide shows how to add QuickCarousals tables to the existing Saasfly Prisma schema.

## Overview

The migration adds 7 new models to support the QuickCarousals application:
- **Profile** - User profiles linked to Clerk authentication
- **BrandKit** - User's brand assets (logo, colors, fonts)
- **StyleKit** - Pre-defined design themes
- **TemplateLayout** - Slide layout blueprints
- **Project** - Carousel projects
- **Slide** - Individual carousel slides
- **Export** - Export jobs (PDF/PNG generation)

## Migration Steps

### Step 1: Backup Existing Schema

```bash
cp packages/db/prisma/schema.prisma packages/db/prisma/schema.prisma.backup
```

### Step 2: Add QuickCarousals Models

Edit `packages/db/prisma/schema.prisma` and add the following **after** the existing models:

```prisma
// ============================================
// QuickCarousals Data Models
// ============================================

// Enums for QuickCarousals
enum SubscriptionTier {
  FREE
  CREATOR
  PRO
}

enum ProjectStatus {
  DRAFT
  PUBLISHED
  ARCHIVED
}

enum ExportType {
  PDF
  PNG
  THUMBNAIL
}

enum ExportStatus {
  PENDING
  PROCESSING
  COMPLETED
  FAILED
}

// Profile - Extends Clerk user with subscription info
model Profile {
  id               String           @id @default(dbgenerated("gen_random_uuid()"))
  clerkUserId      String           @unique // Links to Clerk user
  email            String           @unique
  name             String?
  avatarUrl        String?
  subscriptionTier SubscriptionTier @default(FREE)
  createdAt        DateTime         @default(now())
  updatedAt        DateTime         @updatedAt
  
  brandKits        BrandKit[]
  projects         Project[]
  
  @@index([clerkUserId])
  @@index([email])
}

// Brand Kit - User's branding assets
model BrandKit {
  id           String   @id @default(dbgenerated("gen_random_uuid()"))
  userId       String
  name         String
  colors       Json     @default("{}")
  fonts        Json     @default("{}")
  logoUrl      String?
  handle       String?
  footerStyle  String?
  isDefault    Boolean  @default(false)
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt
  
  user         Profile  @relation(fields: [userId], references: [id], onDelete: Cascade)
  projects     Project[]
  
  @@index([userId])
}

// Style Kit - Pre-defined design themes (seed data)
model StyleKit {
  id           String   @id // e.g., 'minimal_clean'
  name         String
  typography   Json
  colors       Json
  spacingRules Json
  isPremium    Boolean  @default(false)
  
  projects     Project[]
}

// Template Layout - Slide layout blueprints (seed data)
model TemplateLayout {
  id              String @id // e.g., 'hook_big_headline'
  name            String
  category        String
  slideType       String
  layersBlueprint Json
  
  slides          Slide[]
}

// Project - Carousel project
model Project {
  id          String        @id @default(dbgenerated("gen_random_uuid()"))
  userId      String
  title       String
  brandKitId  String?
  styleKitId  String
  status      ProjectStatus @default(DRAFT)
  createdAt   DateTime      @default(now())
  updatedAt   DateTime      @updatedAt
  
  user        Profile       @relation(fields: [userId], references: [id], onDelete: Cascade)
  brandKit    BrandKit?     @relation(fields: [brandKitId], references: [id])
  styleKit    StyleKit      @relation(fields: [styleKitId], references: [id])
  slides      Slide[]
  exports     Export[]
  
  @@index([userId])
  @@index([brandKitId])
  @@index([styleKitId])
}

// Slide - Individual carousel slide
model Slide {
  id         String   @id @default(dbgenerated("gen_random_uuid()"))
  projectId  String
  orderIndex Int
  layoutId   String
  slideType  String
  layers     Json     @default("[]")
  content    Json     @default("{}")
  createdAt  DateTime @default(now())
  updatedAt  DateTime @updatedAt
  
  project    Project         @relation(fields: [projectId], references: [id], onDelete: Cascade)
  layout     TemplateLayout  @relation(fields: [layoutId], references: [id])
  
  @@index([projectId])
  @@index([layoutId])
}

// Export - Export job tracking
model Export {
  id           String       @id @default(dbgenerated("gen_random_uuid()"))
  projectId    String
  exportType   ExportType
  status       ExportStatus @default(PENDING)
  fileUrl      String?
  errorMessage String?
  createdAt    DateTime     @default(now())
  completedAt  DateTime?
  
  project      Project      @relation(fields: [projectId], references: [id], onDelete: Cascade)
  
  @@index([projectId])
  @@index([status])
}
```

### Step 3: Remove Old NextAuth Models (Optional)

If you're fully committing to Clerk, you can remove the old NextAuth models:

```prisma
// REMOVE these models if using Clerk exclusively:
// - Account
// - Session
// - User
// - VerificationToken
```

**Keep only:**
- Customer (for Stripe integration)
- K8sClusterConfig (if still needed)

### Step 4: Apply Schema Changes

```bash
cd packages/db
bun db:push
```

This will:
1. Create all new tables in your database
2. Auto-generate Kysely types in `packages/db/prisma/types.ts`
3. Auto-generate enums in `packages/db/prisma/enums.ts`

### Step 5: Verify Types Generated

Check that types were generated:

```bash
ls -la packages/db/prisma/types.ts
ls -la packages/db/prisma/enums.ts
```

### Step 6: Create Seed Data

Create `packages/db/seed.ts` for style kits and template layouts:

```typescript
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

async function main() {
  // Seed StyleKits
  await prisma.styleKit.createMany({
    data: [
      {
        id: 'minimal_clean',
        name: 'Minimal Clean',
        typography: { headline: 'Inter', body: 'Inter' },
        colors: { primary: '#000000', background: '#FFFFFF' },
        spacingRules: { tight: true },
        isPremium: false,
      },
      {
        id: 'high_contrast',
        name: 'High Contrast Punch',
        typography: { headline: 'Poppins', body: 'Inter' },
        colors: { primary: '#FF0000', background: '#000000' },
        spacingRules: { normal: true },
        isPremium: false,
      },
      // Add other 6 style kits...
    ],
    skipDuplicates: true,
  })

  // Seed TemplateLayouts
  await prisma.templateLayout.createMany({
    data: [
      {
        id: 'hook_big_headline',
        name: 'Big Headline',
        category: 'hook',
        slideType: 'hook',
        layersBlueprint: {
          layers: [
            { type: 'background', color: '#ffffff' },
            { type: 'text_box', id: 'headline', fontSize: 48, maxLines: 2 },
          ],
        },
      },
      // Add other 8 layouts...
    ],
    skipDuplicates: true,
  })
}

main()
  .catch((e) => {
    console.error(e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
```

Run seed:

```bash
cd packages/db && bun run seed.ts
```

## Database Queries with Kysely

After migration, use Kysely for type-safe queries:

```typescript
import { db } from '@/lib/db'

// Get user's projects
const projects = await db
  .selectFrom('Project')
  .where('userId', '=', userId)
  .selectAll()
  .execute()

// Create a new project
const newProject = await db
  .insertInto('Project')
  .values({
    userId,
    title: 'My Carousel',
    styleKitId: 'minimal_clean',
    status: 'DRAFT',
    createdAt: new Date(),
    updatedAt: new Date(),
  })
  .returningAll()
  .executeTakeFirstOrThrow()
```

## Rollback

If you need to rollback:

```bash
# Restore backup
cp packages/db/prisma/schema.prisma.backup packages/db/prisma/schema.prisma

# Reapply old schema
cd packages/db && bun db:push
```

## Next Steps

After successful migration:

1. ✅ Verify all tables created in database
2. ✅ Check Kysely types generated
3. ✅ Run seed script for StyleKits and TemplateLayouts
4. ✅ Update Clerk webhook to create Profile on user signup
5. ✅ Test basic CRUD operations
6. ✅ Begin implementing QuickCarousals features per tasks.json

## Troubleshooting

### Error: "Relation mode 'prisma' requires foreign keys"

This is expected with the current Prisma config. The schema uses Prisma's relation mode which doesn't enforce foreign keys at the database level.

### Error: "Column already exists"

Drop the conflicting table manually:

```sql
DROP TABLE IF EXISTS "Profile" CASCADE;
```

Then re-run `bun db:push`.

### Types not generating

Ensure `prisma-kysely` generator is in schema:

```prisma
generator client {
  provider     = "prisma-kysely"
  output       = "."
  fileName     = "types.ts"
  enumFileName = "enums.ts"
}
```

## Environment Variables

Update `.env.local`:

```bash
# Database
POSTGRES_URL="postgresql://..."

# Clerk (replace NextAuth)
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_..."
CLERK_SECRET_KEY="sk_test_..."
CLERK_WEBHOOK_SECRET="whsec_..."
```

---

**Status:** Ready for implementation ✅

**Next Task:** Begin with `setup-01` in tasks.json
