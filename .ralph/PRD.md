# QuickCarousals - Final Product Requirements Document

## Executive Summary

QuickCarousals is a LinkedIn-first carousel generator that enables solo creators to transform ideas into professional, ready-to-post PDF carousels in under 3 minutes. Built on the Saasfly monorepo template, the product focuses on speed, design confidence, and eliminating the blank-page anxiety that creators face when trying to produce engaging carousel content.

**Core Value Proposition:** "Turn an idea into a LinkedIn-ready PDF carousel in 3 minutes that doesn't look templated."

---

## Table of Contents

1. [Market Context](#market-context)
2. [Target Audience](#target-audience)
3. [Product Strategy](#product-strategy)
4. [Core Features](#core-features)
5. [Tech Stack](#tech-stack)
6. [Architecture](#architecture)
7. [Data Model](#data-model)
8. [UI/UX Requirements](#uiux-requirements)
9. [Security & Authentication](#security--authentication)
10. [Third-Party Integrations](#third-party-integrations)
11. [Constraints & Assumptions](#constraints--assumptions)
12. [Pricing Strategy](#pricing-strategy)
13. [Template Conversion Guide](#template-conversion-guide)
14. [Agent Validation Strategy](#agent-validation-strategy)
15. [Task List](#task-list)
16. [Agent Instructions](#agent-instructions)
17. [Success Criteria](#success-criteria)
18. [Environment Variables](#environment-variables)
19. [Error Handling Strategy](#error-handling-strategy)
20. [Analytics Events](#analytics-events)
21. [Font Handling Strategy](#font-handling-strategy)
22. [Keyboard Shortcuts](#keyboard-shortcuts)
23. [Performance Budget](#performance-budget)
24. [API Rate Limits](#api-rate-limits)
25. [Deployment Guide](#deployment-guide)
26. [Rollback Strategy](#rollback-strategy)
27. [Backup Strategy](#backup-strategy)
28. [Skim Score Feature (v1.5)](#skim-score-feature-v15)
29. [Localization (i18n)](#localization-i18n)

---

## Market Context

### Competitive Landscape

QuickCarousals enters a growing market of carousel-focused tools:

**Carousel-First Generators (Direct Competitors):**
- PostNitro, aiCarousels.com, CarouselMaker.co, Contentdrips, VDraw, Taplio

**Social Suites with Carousel Features:**
- Predis.ai, Ocoya, Simplified, Supergrow.ai

**Design Platforms with AI Carousel Helpers:**
- Venngage, Piktochart AI, Template.net, Phot.ai

### Differentiation Strategy

QuickCarousals wins through:
1. **Superior Layout Engine** - No ugly text overflows, guaranteed good design
2. **LinkedIn Skim Score** - Turns the product into a coach, not just a generator
3. **Speed** - 3-minute creation flow, not 45 minutes in Canva
4. **Constrained Quality** - 8-12 style kits that always look professional

---

## Target Audience

### Primary User: Solo LinkedIn Creators
- Content creators, coaches, consultants, and thought leaders
- Building personal brands on LinkedIn
- Value speed, confidence, and minimal fiddling
- Want professional-looking carousels without design expertise

### Pain Points Addressed
- Blank-page anxiety when starting a carousel
- Spending too much time on design instead of content
- Inconsistent visual identity across posts
- Text overflow and ugly formatting issues
- Uncertainty about whether their carousel will perform well

### User Psychology
- They don't buy "AI" - they buy less friction and more confidence
- They want to post consistently without design becoming a bottleneck
- They'll pay for tools that prevent the "why did this flop" emotional pain

---

## Product Strategy

### Why LinkedIn-First
- **One dominant format:** PDF carousels
- **One feed behavior:** Skim + save
- **One consistent canvas:** Portrait pages (1080x1350)
- **Achievable v1 scope:** Focused execution beats multi-platform sprawl

### Product Positioning
- **Not Canva:** Think "Google Slides for carousels"
- **Coach, not tool:** Guide users toward better content
- **Constraints over flexibility:** Fewer choices that guarantee good output

---

## Core Features

### 1. Topic → Carousel (Priority: Critical)
The fastest blank-page solver for creators.

**Input:**
- Topic (required)
- Optional: audience, tone ("bold / calm / contrarian")

**Output:** 8-12 slide draft with:
- Hook slide (attention-grabbing opener)
- Promise slide ("What you'll learn")
- 5-8 value slides (core content)
- Recap slide (key takeaways)
- CTA slide (follow/comment/save)

### 2. Paste Text → Carousel (Priority: Critical)
For power users with existing notes or draft content.

**Input:** Messy notes, LinkedIn post draft, or text up to 8,000 characters

**Output:** Structured slides with proper pacing, headings, and hierarchy

### 3. WYSIWYG Canvas Editor (Priority: Critical)
A constrained but powerful editing experience.

**Must-Have Features:**
- Click-to-edit text with live preview
- Drag to reorder slides, add/remove/duplicate
- Auto-fit text (killer feature):
  - Automatically shrinks font within min/max bounds
  - Adjusts line height for readability
  - "Fix with AI" button for overly long text
- Theme controls: font pair, color palette, spacing scale (tight/normal/roomy)
- Emphasis tools: bold highlight style ("marker" or "pill"), callout blocks, numbered steps
- Per-slide layout variants

### 4. Style System (Priority: Critical)
8 curated style kits instead of hundreds of templates.

**Launch Style Kits:**
| Kit Name | Description |
|----------|-------------|
| Minimal Clean | Black/white, lots of whitespace |
| High Contrast Punch | Big type, bold blocks |
| Marker Highlight | Emphasis strokes behind phrases |
| Sticky Note / Notebook | Casual, friendly |
| Corporate Pro | Clean grid, subtle accent, brand-safe |
| Gradient Modern | Tasteful gradients, modern feel |
| Dark Mode Punch | Dark backgrounds, vibrant accents |
| Soft Pastel | Gentle colors, approachable |

### 5. Brand Kit (Priority: High)
Personal branding made consistent.

**Features:**
- Upload logo
- Set name/handle
- Set color palette (primary, secondary, accent)
- Choose font pair
- Default footer style
- Auto-apply to all new carousels

### 6. Export System (Priority: Critical)
Reliable, high-quality output.

**Export Formats:**
- PDF export (primary - for LinkedIn upload)
- PNG export (individual slides as images)
- Cover thumbnail export (for LinkedIn preview optimization)

### 7. Quick Rewrite Actions (Priority: Medium)
AI-powered per-slide improvements:
- "Make this slide shorter"
- "Make this more punchy"
- "Add examples"
- "Reduce jargon"
- "More contrarian hook"
- "More specific"
- Regenerate hook options (3-5 variants)

### 8. LinkedIn Skim Score (Priority: Medium - Differentiator)
Turns the product into a coach.

**Scoring Features:**
- Hook Strength score for slide 1
- Skimmability score per slide
- Flag slides as: too dense, weak headline, no pattern interrupt

**One-Click Fixes:**
- "Split this slide"
- "Shorten headline"
- "Add bold emphasis"

---

## Tech Stack

### Frontend (apps/nextjs)
| Technology | Purpose |
|------------|---------|
| Next.js 15.x | React framework with App Router |
| TypeScript | Type safety |
| Konva.js | Canvas-based layered editor |
| Zustand | State management |
| Tailwind CSS | Utility-first styling |
| shadcn/ui | Component library |

### Backend
| Technology | Purpose |
|------------|---------|
| Next.js Route Handlers | API endpoints |
| tRPC | Type-safe API layer |
| Prisma + Kysely | Database schema management + type-safe queries |
| BullMQ + Redis | Job queue for exports |

### Database & Storage
| Technology | Purpose |
|------------|---------|
| PostgreSQL | Primary database (Vercel Postgres) |
| Cloudflare R2 / S3 | File storage (exports, logos, fonts) |
| Upstash Redis | Caching + queue |

### Rendering & Export
| Technology | Purpose |
|------------|---------|
| @napi-rs/canvas | Server-side Skia renderer |
| PDFKit | Multi-page PDF generation |
| Sharp | Image optimization |

### AI & External Services
| Technology | Purpose |
|------------|---------|
| OpenAI API (GPT-4.1) | Content generation |
| Stripe | Subscription billing |
| Clerk | Authentication & user management |
| PostHog | Analytics |
| Sentry | Error tracking |
| Resend | Transactional email |

### Hosting
| Service | Component |
|---------|-----------|
| Vercel | Next.js app + Route Handlers |
| Fly.io (optional) | Export worker for heavy rendering |

---

## Architecture

### Monorepo Structure (Saasfly)

```
saasfly/
├── apps/
│   └── nextjs/           # Main application
│       ├── src/
│       │   ├── app/      # App Router pages
│       │   │   ├── [lang]/
│       │   │   │   ├── (auth)/         # Sign in/up pages
│       │   │   │   ├── (dashboard)/    # Dashboard pages
│       │   │   │   └── (marketing)/    # Landing, pricing
│       │   │   └── api/                # Route handlers
│       │   ├── components/             # React components
│       │   ├── config/                 # App configuration
│       │   └── lib/                    # Utilities
│       └── public/                     # Static assets
├── packages/
│   ├── db/               # Database schema & utilities
│   ├── ui/               # Shared UI components
│   ├── auth/             # Authentication utilities
│   └── email/            # Email templates
└── tooling/              # Build configurations
```

### Layer-Based Template Architecture

Templates are stored as structured JSON layout primitives, not static images.

```json
{
  "template_id": "bold_modern_01",
  "styles": {
    "background_color": "#1A1A1A",
    "font_primary": "Inter",
    "accent_color": "#FF5733"
  },
  "layout_type": "text_left_image_right",
  "layers": [
    { "type": "background", "properties": {} },
    { 
      "type": "text_box", 
      "id": "headline", 
      "constraints": { 
        "max_lines": 2, 
        "min_font": 24, 
        "max_font": 48 
      } 
    },
    { 
      "type": "text_box", 
      "id": "body", 
      "constraints": { 
        "max_lines": 5, 
        "min_font": 16, 
        "max_font": 24 
      } 
    }
  ]
}
```

### AI Pipeline (4-Step Quality Guarantee)

```
┌─────────────────────────────────────────────────────────────┐
│  1. STRUCTURE: AI produces slide plan                        │
│     - Slide types (hook, steps, list, recap)                │
│     - One-sentence goal per slide                           │
├─────────────────────────────────────────────────────────────┤
│  2. COPY: Enforce hard constraints                          │
│     - Headline ≤ 8-12 words                                 │
│     - Body bullets max 3-5                                  │
│     - 1 idea per slide                                      │
├─────────────────────────────────────────────────────────────┤
│  3. LAYOUT SELECTION: Pick layout by slide type + text len  │
│     - Short hook → "big headline" layout                    │
│     - Long explanation → "bullets" layout                   │
├─────────────────────────────────────────────────────────────┤
│  4. FIT & POLISH: Auto-fit typography                       │
│     - Apply emphasis styling                                │
│     - Run density checks                                    │
│     - Suggest splits if needed                              │
└─────────────────────────────────────────────────────────────┘
```

### Core Subsystems

1. **Editor & Template Engine** (Frontend)
   - Konva.js canvas for layered editing
   - Real-time text measurement and auto-fit
   - Theme application and preview

2. **AI Generation Pipeline** (Backend)
   - Structured prompts with JSON output
   - Constraint enforcement
   - Layout matching algorithm

3. **Renderer/Export Service** (Backend Worker)
   - Server-side canvas rendering
   - PDF generation with font embedding
   - Queue-based job processing

---

## Data Model

### Prisma Schema

Add to `packages/db/prisma/schema.prisma`:

```prisma
// QuickCarousals Data Models

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

// Extends Clerk user with subscription info
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

model StyleKit {
  id           String   @id // e.g., 'minimal_clean'
  name         String
  typography   Json
  colors       Json
  spacingRules Json
  isPremium    Boolean  @default(false)
  
  projects     Project[]
}

model TemplateLayout {
  id              String @id // e.g., 'hook_big_headline'
  name            String
  category        String
  slideType       String
  layersBlueprint Json
  
  slides          Slide[]
}

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

### Entity Relationships

```
User (profiles)
├── has many BrandKits
├── has many Projects
│   ├── belongs to BrandKit (optional)
│   ├── belongs to StyleKit
│   ├── has many Slides
│   │   └── belongs to TemplateLayout
│   └── has many Exports
```

---

## UI/UX Requirements

### Design Principles
1. **Speed over features:** Every interaction optimized for < 3 minutes to export
2. **Confidence over flexibility:** Constrained choices that guarantee good output
3. **Coach over tool:** Guide users toward better content, not just execute commands

### Screen Flow

#### 1. Landing Page (Marketing)
- Hero with value proposition
- Feature highlights
- Style kit showcase
- Pricing preview
- CTA to sign up

#### 2. Dashboard (Authenticated)
- "New Carousel" prominent CTA
- Recent projects grid
- Empty state for new users
- Brand kit quick access

#### 3. Creation Flow (/create)
```
┌─────────────────────────────────────────┐
│  Choose Mode:                           │
│  [ Topic ] [ Paste Text ]               │
├─────────────────────────────────────────┤
│  Topic Input / Text Paste Area          │
├─────────────────────────────────────────┤
│  Style Kit Selection (8 options)        │
├─────────────────────────────────────────┤
│  Options:                               │
│  - Slide count (8/10/12)                │
│  - Tone (bold/calm/contrarian)          │
│  - Apply brand kit toggle               │
├─────────────────────────────────────────┤
│  [ Generate Carousel ]                  │
└─────────────────────────────────────────┘
```

#### 4. Editor (/editor/[projectId])
```
┌──────────────┬────────────────────────────┬──────────────┐
│              │                            │              │
│  Slide       │      Canvas Editor         │   Controls   │
│  Thumbnails  │      (1080x1350)          │   Panel      │
│              │                            │              │
│  [Slide 1]   │   ┌─────────────────┐     │  Style Kit   │
│  [Slide 2]   │   │                 │     │  Font Pair   │
│  [Slide 3]   │   │   Click to      │     │  Colors      │
│  [Slide 4]   │   │   Edit Text     │     │  Spacing     │
│  ...         │   │                 │     │  Layout      │
│              │   └─────────────────┘     │  Variants    │
│  [+ Add]     │                            │              │
│              │                            │  Quick       │
│              │                            │  Actions     │
│              │                            │              │
├──────────────┴────────────────────────────┴──────────────┤
│  [ Export PDF ]  [ Export PNG ]  Project Name            │
└──────────────────────────────────────────────────────────┘
```

#### 5. Export Modal
- Format selection (PDF / PNG)
- Filename customization
- Cover thumbnail option
- Progress indicator
- Download button

#### 6. Brand Kit Settings (/settings/brand-kit)
- Logo upload
- Color palette picker
- Font selection
- Name/handle input
- Preview on sample slides

### Responsive Requirements
- **Desktop-first:** Primary creation happens on laptops
- **Mobile:** View-only for reviewing exports
- **Default canvas:** 1080x1350 (LinkedIn portrait)

### Accessibility
- Keyboard navigation in editor
- Focus indicators
- Screen reader labels for controls
- Sufficient color contrast

---

## Security & Authentication

### Authentication Flow (Clerk)
- Email/password sign up
- OAuth (Google, LinkedIn, GitHub)
- Session management handled by Clerk
- Email verification for new accounts
- User profile sync to Profile table via webhooks

### Authorization
- Clerk userId validation on all protected endpoints
- Prisma queries filtered by `userId` for data isolation
- Projects, slides, brand kits owned by user (enforced in backend)
- Signed URLs for export downloads (24hr expiry)

### API Security
- Rate limiting on AI generation endpoints (10 req/min)
- Input validation with Zod schemas
- CSRF protection via Next.js
- Content Security Policy headers
- Clerk session validation on all API routes

### Data Protection
- All exports in private storage buckets
- User data encrypted at rest (Vercel Postgres)
- HTTPS everywhere
- API key rotation for OpenAI
- Clerk handles password hashing and secure storage

---

## Third-Party Integrations

### Required for MVP
| Service | Purpose | Integration Method |
|---------|---------|-------------------|
| Clerk | Authentication | SDK |
| PostgreSQL | Database | Prisma/Kysely |
| OpenAI | AI generation | REST API |
| Stripe | Billing | SDK + Webhooks |
| Cloudflare R2 | Storage | S3-compatible SDK |

### Post-MVP
| Service | Purpose | Version |
|---------|---------|---------|
| LinkedIn API | Direct publishing | v1.5 |
| Zapier | Workflow automation | v2.0 |

---

## Constraints & Assumptions

### Technical Constraints
- **Existing Codebase:** Built on Saasfly monorepo template - must work within its existing architecture and conventions
- **Canvas Rendering:** Konva.js for layered WYSIWYG editing; browser text metrics for measurement (per stack research)
- **PDF Generation:** Server-side rendering required - "Browsers are inconsistent, and creators want reliable PDF" (stack-and-architecture.txt)
- **Font Handling:** "Fonts are a real source of export bugs" - store font files in S3/R2, embed in server renderer, keep curated default set (Google Fonts) so free users look great

### Hosting & Infrastructure (from stack research)
- **Frontend:** Vercel for Next.js application
- **Backend/Workers:** Fly.io or Render for heavy rendering jobs
- **Database:** PostgreSQL via Neon or Supabase-managed
- **Storage/CDN:** Cloudflare R2 with CDN for exports, logos, custom fonts
- **Queue/Cache:** Upstash or managed Redis (BullMQ for rendering and heavy AI jobs)

### Development Constraints
- **Solo/Small Team:** Target user is solo creators; architecture should match (maintainability over complexity)
- **AI API Costs:** Consider "BYO API key" for Pro users - "creators love it, protects your margins" (stack research)
- **Export Performance:** Queue keeps app responsive - "rendering and AI calls are bursty and slow-ish"

### Business Assumptions (from pricing research)
- **Target Market:** Solo LinkedIn creators who "value speed, confidence, and minimal fiddling"
- **Pricing Alignment:** Market expects Free → $15-29/mo (Creator) → $49-99/mo (Pro/Agency)
- **User Psychology:** "They don't buy 'AI.' They buy less friction and more confidence."
- **Willingness to Pay:** "LinkedIn creators will pay for [coaching features] because it saves the emotional pain of 'why did this flop'"

### MVP Scope Limitations (from MVP research)
- **Single Platform:** LinkedIn-first - "one dominant format (PDF carousels), one feed behavior (skim + save), one consistent canvas"
- **No Direct Publishing:** Manual download + upload for v1.0; LinkedIn API integration is v1.5
- **Style Kits Only:** 8-12 curated kits instead of hundreds of templates - constrained quality over infinite options
- **No URL → Carousel:** "Skip for MVP unless comfortable with scraping edge cases" - planned for v1.5
- **No Video Export:** Carousel to video export planned for v1.5

---

## Pricing Strategy

### Tier Structure

| Tier | Price | Features |
|------|-------|----------|
| **Free** | $0 | 3 carousels/month, 8 slides max, watermark, 3 style kits |
| **Creator** | $15/mo | 30 carousels/month, 15 slides max, no watermark, all 8 style kits, 1 brand kit |
| **Pro** | $39/mo | Unlimited carousels, 20 slides max, 5 brand kits, custom fonts, priority exports |

### Monetization Gates
- Monthly carousel limits
- Slide count limits
- Watermark removal
- Style kit access
- Brand kit count
- Custom fonts (Pro)
- Priority export queue (Pro)

### Future Add-ons
- BYO OpenAI API key: Separate AI credits from export usage
- Repurposing Pack: URL/PDF/YouTube → carousel (+$10/mo)

---

## Template Conversion Guide

### Files to Update from Saasfly Template

#### Branding & Copy
| File | Changes |
|------|---------|
| `apps/nextjs/src/app/layout.tsx` | Update metadata title/description |
| `apps/nextjs/src/app/[lang]/(marketing)/page.tsx` | Replace hero, features, CTA |
| `apps/nextjs/src/app/[lang]/(auth)/login/page.tsx` | Update copy and helper text |
| `apps/nextjs/src/app/[lang]/(auth)/register/page.tsx` | Update copy and helper text |
| `apps/nextjs/src/app/[lang]/(dashboard)/dashboard/page.tsx` | Replace with QuickCarousals dashboard |
| `apps/nextjs/src/config/site.ts` | Update site name and metadata |
| `apps/nextjs/src/config/dictionaries/*.json` | Update i18n strings |

#### Visual Assets
| File | Changes |
|------|---------|
| `apps/nextjs/public/favicon.ico` | QuickCarousals favicon |
| `apps/nextjs/public/logo.svg` | QuickCarousals logo |
| `apps/nextjs/src/styles/globals.css` | Brand colors and fonts |

#### Database
| Action | Details |
|--------|---------|
| Create migrations | Add QuickCarousals tables |
| Seed data | Default style kits and layouts |
| Generate types | After schema changes |

#### Configuration
| File | Changes |
|------|---------|
| `package.json` (root) | Update name/description |
| `apps/nextjs/package.json` | Update name |
| `README.md` | Rewrite for QuickCarousals |
| `.env.example` | Document required env vars |

---

## Agent Validation Strategy

### Validation Principles
- Validate user-visible behavior and API contracts, not implementation details
- Use deterministic inputs and stable test data
- Prefer stable locators: add `data-testid` attributes
- Use snake_case for all `data-testid` values
- Always check for console errors and failed network requests
- Capture artifacts (screenshots + API responses)

### Validation Variables
```bash
export BASE_URL="http://localhost:3000"
export API_BASE_URL="$BASE_URL"
export LOG_DIR="./.agent/logs"
export SCREENSHOT_DIR="./screenshots"
```

### What Counts as "Validated"
A feature is validated when:
- One happy-path flow succeeds
- One negative-path flow returns clear error
- No frontend console errors or failed network requests
- Evidence captured: screenshots + API response logs
- For mutations, read-back verifies state change

### Validation Template

**Note:** These are reference templates showing validation approach. Adapt commands to match your actual implementation.

```bash
# Backend: happy + negative
curl -s "$API_BASE_URL/api/endpoint" -H "Content-Type: application/json" -d '{"valid":"data"}'
curl -s "$API_BASE_URL/api/endpoint" -H "Content-Type: application/json" -d '{"invalid":"data"}'

# Frontend: UI flow + evidence
agent-browser open "$BASE_URL/page"
agent-browser wait --load networkidle
agent-browser snapshot -i
agent-browser find testid "element" click
agent-browser errors
agent-browser screenshot "$SCREENSHOT_DIR/feature.png"
```

**Validation Object Structure in tasks.json:**
```json
{
  "validation": {
    "_note": "These commands are reference examples showing validation intent. Actual commands may need adjustment based on your implementation, file paths, and available tooling.",
    "commands": ["command1", "command2"],
    "expected": "Description of success criteria"
  }
}
```

---

## Task List

Tasks are ordered by dependencies. Each task includes a `depends_on` array listing prerequisite task IDs. Execute tasks only after all dependencies are complete.

### Validation Protocol

Before marking any task complete, execute ALL validation steps. Each validation includes:
- **Command**: Reference command showing validation approach
- **Expected**: What success looks like
- **Error Check**: How to verify no errors

**IMPORTANT: Validation Commands are Reference Examples**

The validation commands in tasks.json are **reference/pseudo-code examples**, not exact executable commands. They illustrate the validation approach and intent, but the actual commands may need to be adapted based on:
- Your actual implementation details
- File paths and structure
- Available tooling and scripts
- Environment-specific variables
- Framework-specific testing utilities

Use the validation commands as **guidance for what to verify**, not as copy-paste shell scripts. You may need to:
- Adjust file paths to match your implementation
- Use different testing tools than shown
- Modify commands to fit your actual setup
- Add or remove steps based on what you actually built

```bash
# Standard validation variables (set once per session)
export BASE_URL="http://localhost:3000"
export LOG_DIR="./.agent/logs"
export SCREENSHOT_DIR="./screenshots"
mkdir -p "$LOG_DIR" "$SCREENSHOT_DIR/setup" "$SCREENSHOT_DIR/features" "$SCREENSHOT_DIR/integrations" "$SCREENSHOT_DIR/styling" "$SCREENSHOT_DIR/testing"
```

All the tasks are defined in .ralph/tasks.json


### Task Dependency Graph

```
PHASE 1: Foundation (setup-01 to setup-14, infra-01 to infra-04)
├── setup-01 (package metadata)
│   ├── setup-02 (config + assets)
│   │   ├── setup-03 (landing page)
│   │   ├── setup-04 (auth pages)
│   │   └── setup-13 (API health)
│   │       └── setup-14 (auth guards)
│   ├── setup-06 (profiles table)
│   │   ├── setup-07 (style_kits table)
│   │   │   └── setup-08 (template_layouts table)
│   │   ├── setup-09 (brand_kits table)
│   │   │   └── setup-10 (projects table)
│   │   │       ├── setup-11 (slides table)
│   │   │       └── setup-12 (exports table)
│   └── infra-01 (storage)
│       └── infra-02 (signed URLs)
│   └── infra-03 (Redis)
│       └── infra-04 (BullMQ)

PHASE 2: AI Generation (feature-01 to feature-11)
├── feature-01 (OpenAI service)
│   └── feature-02 (slide plan)
│       └── feature-03 (slide copy)
│           └── feature-04 (layout selection)
│               ├── feature-05 (/api/generate/topic)
│               └── feature-06 (/api/generate/text)
├── feature-07 (style kits 1-4)
│   └── feature-08 (style kits 5-8)
│       └── feature-09 (/api/style-kits)
└── feature-10 (layouts 1-5)
    └── feature-11 (layouts 6-9)

PHASE 3: Editor Core (feature-12 to feature-23)
├── feature-12 (Konva canvas)
│   └── feature-13 (layer rendering)
│       ├── feature-14 (text editing)
│       │   ├── feature-15 (zoom/pan)
│       │   ├── feature-18 (text measurement)
│       │   │   └── feature-19 (auto-fit)
│       │   │       └── feature-20 (Fix with AI)
│       │   └── feature-35 (rewrite UI)
│       ├── feature-16 (thumbnails)
│       │   └── feature-17 (slide management)
│       └── feature-21 (style kit selector)
│           └── feature-22 (theme controls)
│               └── feature-23 (layout variants)

PHASE 4: Brand Kit & Export (feature-24 to feature-33)
├── feature-24 (brand kit API)
│   └── feature-25 (brand kit page)
│       └── feature-26 (brand kit apply)
├── feature-27 (server renderer)
│   └── feature-28 (PDF generation)
│       └── feature-29 (export worker)
│           └── feature-30 (/api/exports)
│               ├── feature-31 (PNG export)
│               └── feature-32 (export modal)
│                   └── feature-33 (download flow)

PHASE 5: Project Management (feature-36 to feature-40)
├── feature-36 (project CRUD)
│   ├── feature-37 (auto-save)
│   └── feature-38 (dashboard)
│       └── feature-39 (creation flow)
│           └── feature-40 (connect to editor)

PHASE 6: Billing (integration-01 to integration-05)
├── integration-01 (Stripe products)
│   └── integration-02 (checkout)
│       └── integration-03 (webhook)
│           ├── integration-04 (billing page)
│           └── integration-05 (feature gating)

PHASE 7: Polish & Testing (styling-01 to testing-04)
├── styling-01 (dashboard polish)
├── styling-02 (creation polish)
├── styling-03 (editor polish)
├── testing-01 (E2E topic)
├── testing-02 (E2E text)
├── testing-03 (QA style kits)
└── testing-04 (QA brand kits)
```

---

## Agent Instructions

### Pre-Development Setup
1. Read `activity.md` first to understand current state
2. Ensure dev server is running: `bun run dev:web`
3. Create `screenshots/` directory if needed
4. Set up environment variables from `.env.example`

### Development Loop (for each task)

```
┌──────────────────────────────────────────────────────────────────┐
│  1. FIND: Next task with "passes": false                         │
├──────────────────────────────────────────────────────────────────┤
│  2. IMPLEMENT: Complete all steps for the task                   │
├──────────────────────────────────────────────────────────────────┤
│  3. BACKEND VALIDATION: Test APIs with curl                      │
│     curl -s http://localhost:3000/api/{endpoint} | jq .         │
├──────────────────────────────────────────────────────────────────┤
│  4. FRONTEND VALIDATION: Test UI with agent-browser              │
│     agent-browser open http://localhost:3000                     │
│     agent-browser snapshot -i                                    │
│     agent-browser screenshot ./screenshots/{name}.png            │
├──────────────────────────────────────────────────────────────────┤
│  5. FIX: If validation fails, fix and re-validate                │
├──────────────────────────────────────────────────────────────────┤
│  6. MARK COMPLETE: Update task "passes": true                    │
├──────────────────────────────────────────────────────────────────┤
│  7. LOG: Update activity.md with completion details              │
└──────────────────────────────────────────────────────────────────┘
```

### Important Rules
- **Only modify** the `passes` field in task list
- **Always validate** before marking complete
- **Validation commands are reference examples** - adapt them to match your actual implementation, file paths, and available tooling
- **Take screenshots** for visual features
- **Log everything** in `activity.md`
- **Do not remove or rewrite tasks**

### Quick Reference Commands

```bash
# Start dev server
bun run dev:web

# Run database migration
bun db:push

# API test
curl -s http://localhost:3000/api/health | jq .

# Frontend test
agent-browser open http://localhost:3000
agent-browser snapshot -i
agent-browser screenshot ./screenshots/test.png
agent-browser close
```

---

## Success Criteria

### MVP Launch Success
| Metric | Target |
|--------|--------|
| Topic → Carousel creation time | < 3 minutes |
| PDF export consistency | No rendering bugs |
| Auto-fit text coverage | 95% of content without overflow |
| Style kits available | 8 polished kits |
| Brand kit application | Works on all slides |

### Business Success Metrics
| Metric | Target |
|--------|--------|
| Free-to-paid conversion | > 5% |
| User retention (weekly active) | > 40% |
| Time to first export | < 5 minutes |
| NPS score | > 40 |

### Technical Success Metrics
| Metric | Target |
|--------|--------|
| Page load time | < 2 seconds |
| Editor responsiveness | < 100ms for interactions |
| Export generation time | < 30 seconds for PDF |
| API response time | < 500ms for most endpoints |
| Uptime | > 99.5% |

---

## Error Handling Strategy

### User-Facing Errors

| Error Type | Display Method | User Action |
|------------|----------------|-------------|
| Network Error | Toast notification | "Check connection and retry" |
| AI Generation Failure | Inline error with retry | "Try again" or "Simplify input" |
| Export Failure | Modal with details | Retry or contact support |
| Auth Failure | Redirect to login | Re-authenticate |
| Validation Error | Inline field errors | Fix input |
| Rate Limit | Toast with countdown | Wait and retry |
| Payment Failure | Modal with Stripe error | Update payment method |

### Error Response Format

```typescript
// All API errors follow this shape
interface ApiError {
  error: {
    code: string;           // e.g., "VALIDATION_ERROR", "RATE_LIMITED"
    message: string;        // User-friendly message
    details?: unknown;      // Optional additional context
    requestId?: string;     // For support debugging
  };
}

// HTTP Status Codes
// 400 - Validation errors
// 401 - Not authenticated
// 403 - Not authorized (tier/limit)
// 404 - Not found
// 429 - Rate limited
// 500 - Server error
```

### Error Logging

```typescript
// All errors logged to Sentry with context
Sentry.captureException(error, {
  tags: {
    feature: 'generation',
    userId: user.id,
  },
  extra: {
    input: sanitizedInput,
    requestId,
  },
});
```

---

## Analytics Events

### PostHog Event Tracking

| Event | Trigger | Properties |
|-------|---------|------------|
| `page_view` | Every page load | `path`, `referrer` |
| `signup_started` | Click sign up | `source` |
| `signup_completed` | Account created | `method` (email/google/linkedin) |
| `carousel_generation_started` | Click generate | `mode` (topic/text), `style_kit`, `slide_count` |
| `carousel_generation_completed` | Generation success | `duration_ms`, `slide_count` |
| `carousel_generation_failed` | Generation error | `error_code` |
| `slide_edited` | Any slide edit | `edit_type` (text/layout/style) |
| `rewrite_used` | Click rewrite action | `action` (shorter/punchier/etc) |
| `export_started` | Click export | `format` (pdf/png) |
| `export_completed` | Download ready | `format`, `slide_count`, `duration_ms` |
| `export_downloaded` | User downloads file | `format` |
| `brand_kit_created` | Save brand kit | `has_logo` |
| `upgrade_clicked` | Click upgrade | `from_tier`, `to_tier`, `trigger_location` |
| `subscription_started` | Webhook: checkout complete | `tier`, `price` |
| `subscription_cancelled` | Webhook: subscription cancelled | `tier`, `reason` |
| `limit_reached` | Hit free tier limit | `limit_type` (carousels/slides/etc) |

### Feature Flags

```typescript
// PostHog feature flags for gradual rollout
const FEATURE_FLAGS = {
  'skim-score': false,        // LinkedIn Skim Score (v1.5)
  'custom-fonts': false,      // Pro tier custom fonts
  'direct-linkedin': false,   // LinkedIn direct publishing (v2.0)
  'youtube-import': false,    // YouTube → carousel (v2.0)
};
```

---

## Font Handling Strategy

### The Challenge
Fonts must render identically in:
1. Browser canvas (Konva.js)
2. Server-side renderer (@napi-rs/canvas)
3. Exported PDF (PDFKit)

### Solution Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Font Pipeline                                                   │
├─────────────────────────────────────────────────────────────────┤
│  1. FONT FILES stored in R2/S3 bucket                            │
│     - /fonts/inter-regular.woff2                                │
│     - /fonts/inter-bold.woff2                                   │
│     - /fonts/lora-regular.woff2                                 │
│     - etc.                                                       │
├─────────────────────────────────────────────────────────────────┤
│  2. BROWSER: Load via @font-face CSS                            │
│     - Preload critical fonts in layout.tsx                      │
│     - Font display: swap for fast rendering                     │
├─────────────────────────────────────────────────────────────────┤
│  3. SERVER RENDERER: Register fonts at startup                  │
│     - Download from R2 to /tmp on cold start                    │
│     - Register with @napi-rs/canvas: registerFont()             │
│     - Cache in memory for subsequent renders                    │
├─────────────────────────────────────────────────────────────────┤
│  4. PDF EXPORT: Embed fonts in PDF                              │
│     - PDFKit: registerFont() with TTF buffer                    │
│     - Subset fonts to reduce file size                          │
└─────────────────────────────────────────────────────────────────┘
```

### Bundled Fonts (MVP)

| Font Family | Weight | Use Case |
|-------------|--------|----------|
| Inter | 400, 700 | Primary body/headline |
| Lora | 400, 700 | Serif alternative |
| Poppins | 600, 800 | Bold modern headlines |
| Roboto Mono | 400 | Code/technical |
| Source Sans Pro | 400, 700 | Corporate clean |

### Font Pairing in Style Kits

```json
{
  "typography": {
    "headline_font": "Poppins",
    "headline_weight": 700,
    "body_font": "Inter",
    "body_weight": 400
  }
}
```

---

## Keyboard Shortcuts

### Editor Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd/Ctrl + S` | Save (manual, though auto-save is on) |
| `Cmd/Ctrl + Z` | Undo |
| `Cmd/Ctrl + Shift + Z` | Redo |
| `Cmd/Ctrl + D` | Duplicate slide |
| `Delete/Backspace` | Delete selected slide |
| `↑ / ↓` | Navigate slides |
| `Escape` | Deselect / Close modal |
| `Cmd/Ctrl + E` | Open export modal |
| `Cmd/Ctrl + +` | Zoom in |
| `Cmd/Ctrl + -` | Zoom out |
| `Cmd/Ctrl + 0` | Fit to screen |
| `Tab` | Next text box |
| `Shift + Tab` | Previous text box |

---

## Performance Budget

### Bundle Size Limits

| Asset | Max Size | Current |
|-------|----------|---------|
| Initial JS | 150KB gzipped | - |
| Konva.js chunk | 100KB gzipped | - |
| Total page weight | 500KB | - |
| Largest image | 200KB | - |
| Font files (per font) | 50KB woff2 | - |

### Runtime Performance

| Metric | Target |
|--------|--------|
| First Contentful Paint | < 1.5s |
| Time to Interactive | < 3s |
| Largest Contentful Paint | < 2.5s |
| Canvas render (single slide) | < 16ms (60fps) |
| Slide switch latency | < 100ms |
| Auto-fit calculation | < 50ms |
| API response (95th percentile) | < 500ms |

### Monitoring

```typescript
// Web Vitals tracking
import { onCLS, onFID, onLCP } from 'web-vitals';

onCLS((metric) => posthog.capture('web_vital_cls', { value: metric.value }));
onFID((metric) => posthog.capture('web_vital_fid', { value: metric.value }));
onLCP((metric) => posthog.capture('web_vital_lcp', { value: metric.value }));
```

---

## API Rate Limits

### Per-Endpoint Limits

| Endpoint | Free Tier | Creator | Pro |
|----------|-----------|---------|-----|
| `/api/generate/*` | 5/hour | 30/hour | 100/hour |
| `/api/rewrite` | 10/hour | 60/hour | Unlimited |
| `/api/exports` | 3/hour | 20/hour | Unlimited |
| `/api/style-kits` | 100/hour | 100/hour | 100/hour |
| `/api/projects` | 50/hour | 200/hour | Unlimited |
| `/api/*` (other) | 100/hour | 500/hour | Unlimited |

### Rate Limit Headers

```
X-RateLimit-Limit: 30
X-RateLimit-Remaining: 28
X-RateLimit-Reset: 1706399999
```

### Rate Limit Response

```json
{
  "error": {
    "code": "RATE_LIMITED",
    "message": "Too many requests. Please try again in 42 seconds.",
    "retryAfter": 42
  }
}
```

---

## Deployment Guide

### Prerequisites
- Vercel account with Pro plan (for Edge Functions)
- Configured environment variables
- Database provisioned (Vercel Postgres or Supabase)
- Storage bucket created (R2 or S3)
- Stripe products created

### Deployment Steps

```bash
# 1. Clone and install
git clone <repo>
cd quickcarousals
bun install

# 2. Set up environment
cp .env.example .env.local
# Fill in all required variables

# 3. Run database migrations
bun db:push
bun db:seed

# 4. Test locally
bun run dev

# 5. Deploy to Vercel
vercel --prod

# 6. Configure webhooks
# - Stripe webhook: https://quickcarousals.com/api/webhooks/stripe
# - Set webhook secret in env vars

# 7. Verify deployment
curl https://quickcarousals.com/api/health
```

### Post-Deployment Checklist

- [ ] Health endpoint returns 200
- [ ] Database connection works
- [ ] Auth flow works (sign up, sign in)
- [ ] AI generation works
- [ ] Export works (PDF download)
- [ ] Stripe checkout works (test mode)
- [ ] Stripe webhook receives events
- [ ] PostHog receiving events
- [ ] Sentry receiving errors

---

## Rollback Strategy

### Vercel Rollback

```bash
# List recent deployments
vercel ls

# Rollback to specific deployment
vercel rollback <deployment-id>
```

### Database Rollback

```bash
# Database migrations should be reversible
# For each migration, create a down migration

# Example: 001_create_style_kits.sql
# Corresponding: 001_create_style_kits_down.sql

# Emergency rollback procedure:
# 1. Deploy previous code version
# 2. Run down migrations if needed
# 3. Verify app functionality
```

### Feature Flag Rollback

```typescript
// Instant disable via PostHog feature flags
// No deployment needed
posthog.featureFlags.override({
  'problematic-feature': false
});
```

---

## Backup Strategy

### Database Backups

| Type | Frequency | Retention |
|------|-----------|-----------|
| Point-in-time recovery | Continuous | 7 days |
| Daily snapshots | Daily 3AM UTC | 30 days |
| Weekly archives | Sunday 3AM UTC | 90 days |

### User Data Export

Users can request full data export:
- Projects with all slides
- Brand kits
- Export history
- Profile data

Format: ZIP with JSON + media files

### Disaster Recovery

| Scenario | RTO | RPO |
|----------|-----|-----|
| Database failure | 1 hour | 5 minutes |
| Storage failure | 2 hours | 24 hours |
| Full region outage | 4 hours | 1 hour |

---

## Skim Score Feature (v1.5)

*Note: This feature is listed as Medium priority and planned for v1.5, not MVP.*

### Overview

LinkedIn Skim Score turns QuickCarousals into a coach, not just a generator.

### Scoring Algorithm

```typescript
interface SkimScore {
  overall: number;        // 0-100
  hook_strength: number;  // Slide 1 score
  slide_scores: {
    index: number;
    score: number;
    issues: SkimIssue[];
  }[];
}

type SkimIssue = 
  | 'too_dense'           // Too much text
  | 'weak_headline'       // Headline not punchy
  | 'no_pattern_interrupt'// No visual break
  | 'no_emphasis'         // Missing bold/highlight
  | 'wall_of_text'        // No bullets/structure
  | 'boring_opener';      // Hook doesn't grab
```

### One-Click Fixes

| Issue | Fix | Implementation |
|-------|-----|----------------|
| too_dense | "Split this slide" | Create 2 slides from content |
| weak_headline | "Punch up headline" | AI rewrite with constraints |
| no_emphasis | "Add bold emphasis" | Auto-bold key phrases |
| wall_of_text | "Add structure" | Convert to bullet points |

### Task (for v1.5)

```json
{
  "id": "feature-skim-01",
  "category": "feature",
  "description": "Implement Skim Score calculation",
  "depends_on": ["feature-19"],
  "steps": [
    "Create skim score algorithm",
    "Add density calculation (chars per area)",
    "Add headline strength heuristics",
    "Create per-slide scoring"
  ]
}
```

### Translation Structure

```
apps/nextjs/src/config/dictionaries/
├── en.json      # English (complete)
├── es.json      # Spanish (v1.5)
├── pt-BR.json   # Portuguese (v1.5)
├── fr.json      # French (v2.0)
└── de.json      # German (v2.0)
```

### AI Generation Language

- Default: Generate in user's browser language
- Option: Force English for consistency
- Translation: Optional post-generation translate

---

## Completion Criteria

All tasks in the Task List marked with `"passes": true`

---

*Document Version: 1.1*
*Last Updated: January 2026*
*Product: QuickCarousals*
*Template Base: Saasfly Monorepo*
